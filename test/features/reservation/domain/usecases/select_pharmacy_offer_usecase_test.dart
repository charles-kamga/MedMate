import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/select_pharmacy_offer_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepository extends Mock
    implements ReservationRepository {}

void main() {
  late SelectPharmacyOfferUseCase useCase;
  late MockReservationRepository mockRepository;

  final sampleReservation = Reservation(
    id: 'res-1',
    clientReservationId: 'client-res-uuid-1',
    demandeId: 'demand-1',
    offreId: 'offer-1',
    pharmacyId: 'pharma-1',
    codeRetraitOtp6Chiffres: '482910',
    statut: ReservationStatus.pending,
    createdAt: DateTime(2026, 11, 9, 20, 0),
    expiresAt: DateTime(2026, 11, 9, 22, 0),
  );

  setUp(() {
    mockRepository = MockReservationRepository();
    useCase = SelectPharmacyOfferUseCase(mockRepository);
  });

  group('SelectPharmacyOfferUseCase', () {
    test(
        'returns Right(Reservation) with valid parameters and Cameroonian phone',
        () async {
      when(
        () => mockRepository.selectPharmacyOffer(
          clientReservationId: 'client-res-uuid-1',
          demandeId: 'demand-1',
          offreId: 'offer-1',
          patientPhone: '+237699000000',
        ),
      ).thenAnswer((_) async => Right(sampleReservation));

      final result = await useCase(
        const SelectPharmacyOfferParams(
          clientReservationId: 'client-res-uuid-1',
          demandeId: 'demand-1',
          offreId: 'offer-1',
          patientPhone: '  +237699000000  ',
        ),
      );

      expect(result, equals(Right<Failure, Reservation>(sampleReservation)));
      verify(
        () => mockRepository.selectPharmacyOffer(
          clientReservationId: 'client-res-uuid-1',
          demandeId: 'demand-1',
          offreId: 'offer-1',
          patientPhone: '+237699000000',
        ),
      ).called(1);
    });

    test('accepts valid 9-digit local Cameroonian phone format (699000000)',
        () async {
      when(
        () => mockRepository.selectPharmacyOffer(
          clientReservationId: any(named: 'clientReservationId'),
          demandeId: any(named: 'demandeId'),
          offreId: any(named: 'offreId'),
          patientPhone: '699000000',
        ),
      ).thenAnswer((_) async => Right(sampleReservation));

      final result = await useCase(
        const SelectPharmacyOfferParams(
          clientReservationId: 'client-res-uuid-1',
          demandeId: 'demand-1',
          offreId: 'offer-1',
          patientPhone: '699000000',
        ),
      );

      expect(result.isRight(), isTrue);
    });

    test(
        'returns Left(ReservationFailure) when phone number does not match Cameroon format',
        () async {
      final invalidPhones = ['12345', 'abcdef', '+33612345678', '000000000'];

      for (final phone in invalidPhones) {
        final result = await useCase(
          SelectPharmacyOfferParams(
            clientReservationId: 'client-res-uuid-1',
            demandeId: 'demand-1',
            offreId: 'offer-1',
            patientPhone: phone,
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, Reservation>(
              ReservationFailure(
                'Numéro de téléphone camerounais invalide (+237...).',
              ),
            ),
          ),
        );
      }
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ValidationFailure) when required IDs are empty',
        () async {
      final resultEmptyId = await useCase(
        const SelectPharmacyOfferParams(
          clientReservationId: '   ',
          demandeId: 'demand-1',
          offreId: 'offer-1',
          patientPhone: '+237699000000',
        ),
      );

      expect(
        resultEmptyId,
        equals(
          const Left<Failure, Reservation>(
            ValidationFailure("Paramètres de sélection d'offre invalides."),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository fails', () async {
      const failure = ServerFailure('Conflit de réservation.');
      when(
        () => mockRepository.selectPharmacyOffer(
          clientReservationId: any(named: 'clientReservationId'),
          demandeId: any(named: 'demandeId'),
          offreId: any(named: 'offreId'),
          patientPhone: any(named: 'patientPhone'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const SelectPharmacyOfferParams(
          clientReservationId: 'client-res-uuid-1',
          demandeId: 'demand-1',
          offreId: 'offer-1',
          patientPhone: '+237699000000',
        ),
      );

      expect(result, equals(const Left<Failure, Reservation>(failure)));
    });
  });
}
