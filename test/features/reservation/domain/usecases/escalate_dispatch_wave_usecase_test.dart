import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/escalate_dispatch_wave_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepository extends Mock
    implements ReservationRepository {}

void main() {
  late EscalateDispatchWaveUseCase useCase;
  late MockReservationRepository mockRepository;

  final sampleFlashRequest = FlashRequest(
    id: 'flash-1',
    clientRequestId: 'client-uuid-1',
    items: const [],
    quartierOuCarrefour: 'Bastos',
    statut: FlashRequestStatus.active,
    vagueActuelle: 2,
    pharmaciesNotifieesIds: const ['pharma-1', 'pharma-2', 'pharma-3', 'pharma-4'],
    offresRecues: const [],
    createdAt: DateTime(2026, 11, 9, 20, 0),
    expiresAt: DateTime(2026, 11, 9, 20, 15),
  );

  setUp(() {
    mockRepository = MockReservationRepository();
    useCase = EscalateDispatchWaveUseCase(mockRepository);
  });

  group('EscalateDispatchWaveUseCase & Déontologie ONPC Round-Robin', () {
    test(
        'escalates wave and dispatches to exactly next 2 partner pharmacies in Round-Robin order',
        () async {
      when(
        () => mockRepository.escalateDispatchWave(
          demandeId: 'flash-1',
          nextWaveNumber: 2,
          eligiblePharmacyIds: ['pharma-3', 'pharma-4'],
        ),
      ).thenAnswer((_) async => Right(sampleFlashRequest));

      final result = await useCase(
        const EscalateDispatchWaveParams(
          demandeId: 'flash-1',
          currentWave: 1,
          candidatePharmacyIds: [
            'pharma-1',
            'pharma-2',
            'pharma-3',
            'pharma-4',
            'pharma-5',
          ],
          alreadyNotifiedPharmacyIds: ['pharma-1', 'pharma-2'],
        ),
      );

      expect(result, equals(Right<Failure, FlashRequest>(sampleFlashRequest)));
      verify(
        () => mockRepository.escalateDispatchWave(
          demandeId: 'flash-1',
          nextWaveNumber: 2,
          eligiblePharmacyIds: ['pharma-3', 'pharma-4'],
        ),
      ).called(1);
    });

    test(
        'dispatches single remaining pharmacy when only 1 unnotified pharmacy is available',
        () async {
      when(
        () => mockRepository.escalateDispatchWave(
          demandeId: 'flash-1',
          nextWaveNumber: 3,
          eligiblePharmacyIds: ['pharma-3'],
        ),
      ).thenAnswer((_) async => Right(sampleFlashRequest));

      final result = await useCase(
        const EscalateDispatchWaveParams(
          demandeId: 'flash-1',
          currentWave: 2,
          candidatePharmacyIds: ['pharma-1', 'pharma-2', 'pharma-3'],
          alreadyNotifiedPharmacyIds: ['pharma-1', 'pharma-2'],
        ),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => mockRepository.escalateDispatchWave(
          demandeId: 'flash-1',
          nextWaveNumber: 3,
          eligiblePharmacyIds: ['pharma-3'],
        ),
      ).called(1);
    });

    test(
        'returns Left(ReservationFailure) when no additional partner pharmacies are available',
        () async {
      final result = await useCase(
        const EscalateDispatchWaveParams(
          demandeId: 'flash-1',
          currentWave: 2,
          candidatePharmacyIds: ['pharma-1', 'pharma-2'],
          alreadyNotifiedPharmacyIds: ['pharma-1', 'pharma-2'],
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, FlashRequest>(
            ReservationFailure(
              'Aucune officine partenaire supplémentaire disponible pour escalade.',
            ),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ValidationFailure) when demandeId is empty', () async {
      final result = await useCase(
        const EscalateDispatchWaveParams(
          demandeId: '   ',
          currentWave: 1,
          candidatePharmacyIds: ['pharma-1', 'pharma-2'],
          alreadyNotifiedPharmacyIds: [],
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, FlashRequest>(
            ValidationFailure('Identifiant de demande manquant.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository fails', () async {
      const failure = ServerFailure('Erreur serveur.');
      when(
        () => mockRepository.escalateDispatchWave(
          demandeId: any(named: 'demandeId'),
          nextWaveNumber: any(named: 'nextWaveNumber'),
          eligiblePharmacyIds: any(named: 'eligiblePharmacyIds'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const EscalateDispatchWaveParams(
          demandeId: 'flash-1',
          currentWave: 1,
          candidatePharmacyIds: ['pharma-1', 'pharma-2'],
          alreadyNotifiedPharmacyIds: [],
        ),
      );

      expect(result, equals(const Left<Failure, FlashRequest>(failure)));
    });
  });
}
