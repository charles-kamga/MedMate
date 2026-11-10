import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/submit_flash_request_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepository extends Mock
    implements ReservationRepository {}

void main() {
  late SubmitFlashRequestUseCase useCase;
  late MockReservationRepository mockRepository;

  const sampleMedication = Medication(
    id: 'med-para-500',
    codeNational: 'CIP-3400936184729',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  const sampleBasketItem = BasketItem(
    medication: sampleMedication,
    quantite: 2,
    precision: 'Générique accepté',
  );

  final sampleFlashRequest = FlashRequest(
    id: 'flash-1',
    clientRequestId: 'client-uuid-1',
    items: const [sampleBasketItem],
    quartierOuCarrefour: 'Carrefour Warda',
    statut: FlashRequestStatus.pending,
    vagueActuelle: 1,
    pharmaciesNotifieesIds: const [],
    offresRecues: const [],
    createdAt: DateTime(2026, 11, 9, 20, 0),
    expiresAt: DateTime(2026, 11, 9, 20, 15),
  );

  setUp(() {
    mockRepository = MockReservationRepository();
    useCase = SubmitFlashRequestUseCase(mockRepository);
  });

  group('SubmitFlashRequestUseCase', () {
    test('returns Right(FlashRequest) when parameters are valid', () async {
      when(
        () => mockRepository.submitFlashRequest(
          clientRequestId: 'client-uuid-1',
          items: const [sampleBasketItem],
          quartierOuCarrefour: 'Carrefour Warda',
          latitude: 3.8688,
          longitude: 11.5175,
        ),
      ).thenAnswer((_) async => Right(sampleFlashRequest));

      final result = await useCase(
        const SubmitFlashRequestParams(
          clientRequestId: 'client-uuid-1',
          items: [sampleBasketItem],
          quartierOuCarrefour: 'Carrefour Warda',
          latitude: 3.8688,
          longitude: 11.5175,
        ),
      );

      expect(result, equals(Right<Failure, FlashRequest>(sampleFlashRequest)));
      verify(
        () => mockRepository.submitFlashRequest(
          clientRequestId: 'client-uuid-1',
          items: const [sampleBasketItem],
          quartierOuCarrefour: 'Carrefour Warda',
          latitude: 3.8688,
          longitude: 11.5175,
        ),
      ).called(1);
    });

    test('returns Left(ValidationFailure) when items list is empty', () async {
      final result = await useCase(
        const SubmitFlashRequestParams(
          clientRequestId: 'client-uuid-1',
          items: [],
          quartierOuCarrefour: 'Carrefour Warda',
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, FlashRequest>(
            ValidationFailure('Le panier ne peut pas être vide.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ValidationFailure) when an item has quantity < 1',
        () async {
      const invalidItem = BasketItem(
        medication: sampleMedication,
        quantite: 0,
      );

      final result = await useCase(
        const SubmitFlashRequestParams(
          clientRequestId: 'client-uuid-1',
          items: [invalidItem],
          quartierOuCarrefour: 'Carrefour Warda',
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, FlashRequest>(
            ValidationFailure(
              'La quantité de chaque médicament doit être au moins 1.',
            ),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test(
        'returns Left(ValidationFailure) when clientRequestId or quartier is empty',
        () async {
      final resultEmptyClient = await useCase(
        const SubmitFlashRequestParams(
          clientRequestId: '   ',
          items: [sampleBasketItem],
          quartierOuCarrefour: 'Carrefour Warda',
        ),
      );

      expect(
        resultEmptyClient,
        equals(
          const Left<Failure, FlashRequest>(
            ValidationFailure('Paramètres de demande invalides.'),
          ),
        ),
      );

      final resultEmptyQuartier = await useCase(
        const SubmitFlashRequestParams(
          clientRequestId: 'client-uuid-1',
          items: [sampleBasketItem],
          quartierOuCarrefour: '   ',
        ),
      );

      expect(
        resultEmptyQuartier,
        equals(
          const Left<Failure, FlashRequest>(
            ValidationFailure('Paramètres de demande invalides.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository fails', () async {
      const failure = ServerFailure('Erreur base de données Supabase.');
      when(
        () => mockRepository.submitFlashRequest(
          clientRequestId: any(named: 'clientRequestId'),
          items: any(named: 'items'),
          quartierOuCarrefour: any(named: 'quartierOuCarrefour'),
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const SubmitFlashRequestParams(
          clientRequestId: 'client-uuid-1',
          items: [sampleBasketItem],
          quartierOuCarrefour: 'Carrefour Warda',
        ),
      );

      expect(result, equals(const Left<Failure, FlashRequest>(failure)));
    });
  });
}
