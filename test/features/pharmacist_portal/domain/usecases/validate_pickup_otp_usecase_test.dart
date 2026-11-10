import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_pickup_otp_usecase.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistPortalRepository extends Mock
    implements PharmacistPortalRepository {}

void main() {
  late ValidatePickupOtpUseCase useCase;
  late MockPharmacistPortalRepository mockRepository;

  final sampleReservation = Reservation(
    id: 'res-1',
    clientReservationId: 'client-res-uuid-1',
    demandeId: 'demand-1',
    offreId: 'offer-1',
    pharmacyId: 'pharma-1',
    codeRetraitOtp6Chiffres: '482910',
    statut: ReservationStatus.completed,
    createdAt: DateTime(2026, 11, 9, 20, 0),
    expiresAt: DateTime(2026, 11, 9, 22, 0),
  );

  setUp(() {
    mockRepository = MockPharmacistPortalRepository();
    useCase = ValidatePickupOtpUseCase(mockRepository);
  });

  group('ValidatePickupOtpUseCase & Invariant OTP 6 Chiffres au Comptoir', () {
    test('returns Right(Reservation) when 6-digit OTP is valid', () async {
      when(
        () => mockRepository.validatePickupOtp(
          pharmacyId: 'pharma-1',
          reservationId: 'res-1',
          otpCode: '482910',
        ),
      ).thenAnswer((_) async => Right(sampleReservation));

      final result = await useCase(
        const ValidatePickupOtpParams(
          pharmacyId: 'pharma-1',
          reservationId: 'res-1',
          otpCode: '  482910  ',
        ),
      );

      expect(result, equals(Right<Failure, Reservation>(sampleReservation)));
      verify(
        () => mockRepository.validatePickupOtp(
          pharmacyId: 'pharma-1',
          reservationId: 'res-1',
          otpCode: '482910',
        ),
      ).called(1);
    });

    test('returns Left(ReservationFailure) when OTP is not exactly 6 digits',
        () async {
      final invalidOtps = ['12345', '1234567', '48291A', ''];

      for (final otp in invalidOtps) {
        final result = await useCase(
          ValidatePickupOtpParams(
            pharmacyId: 'pharma-1',
            reservationId: 'res-1',
            otpCode: otp,
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, Reservation>(
              ReservationFailure(
                'Le code OTP doit comporter exactement 6 chiffres.',
              ),
            ),
          ),
        );
      }
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ValidationFailure) when pharmacyId or reservationId is empty',
        () async {
      final resultEmptyPharmacy = await useCase(
        const ValidatePickupOtpParams(
          pharmacyId: '   ',
          reservationId: 'res-1',
          otpCode: '482910',
        ),
      );
      expect(
        resultEmptyPharmacy,
        equals(
          const Left<Failure, Reservation>(
            ValidationFailure('Paramètres de validation OTP invalides.'),
          ),
        ),
      );

      final resultEmptyReservation = await useCase(
        const ValidatePickupOtpParams(
          pharmacyId: 'pharma-1',
          reservationId: '   ',
          otpCode: '482910',
        ),
      );
      expect(
        resultEmptyReservation,
        equals(
          const Left<Failure, Reservation>(
            ValidationFailure('Paramètres de validation OTP invalides.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ReservationFailure) when repository validation fails',
        () async {
      const failure = ReservationFailure('Code OTP invalide ou réservation déjà retirée.');
      when(
        () => mockRepository.validatePickupOtp(
          pharmacyId: any(named: 'pharmacyId'),
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const ValidatePickupOtpParams(
          pharmacyId: 'pharma-1',
          reservationId: 'res-1',
          otpCode: '482910',
        ),
      );

      expect(result, equals(const Left<Failure, Reservation>(failure)));
    });
  });
}
