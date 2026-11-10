import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/confirm_reservation_otp_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepository extends Mock
    implements ReservationRepository {}

void main() {
  late ConfirmReservationOtpUseCase useCase;
  late MockReservationRepository mockRepository;

  final sampleReservation = Reservation(
    id: 'res-1',
    clientReservationId: 'client-res-uuid-1',
    demandeId: 'demand-1',
    offreId: 'offer-1',
    pharmacyId: 'pharma-1',
    codeRetraitOtp6Chiffres: '482910',
    statut: ReservationStatus.confirmedAtCounter,
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    expiresAt: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
  );

  setUp(() {
    mockRepository = MockReservationRepository();
    useCase = ConfirmReservationOtpUseCase(mockRepository);
  });

  group('ConfirmReservationOtpUseCase & Invariants (OTP 6 Chiffres & TTL 2h)', () {
    test('returns Right(Reservation) with valid 6-digit OTP code', () async {
      when(
        () => mockRepository.confirmReservationOtp(
          reservationId: 'res-1',
          otpCode: '482910',
        ),
      ).thenAnswer((_) async => Right(sampleReservation));

      final result = await useCase(
        const ConfirmReservationOtpParams(
          reservationId: 'res-1',
          otpCode: '  482910  ',
        ),
      );

      expect(result, equals(Right<Failure, Reservation>(sampleReservation)));
      verify(
        () => mockRepository.confirmReservationOtp(
          reservationId: 'res-1',
          otpCode: '482910',
        ),
      ).called(1);
    });

    test('returns Left(ReservationFailure) when OTP has 5 digits', () async {
      final result = await useCase(
        const ConfirmReservationOtpParams(
          reservationId: 'res-1',
          otpCode: '12345',
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
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ReservationFailure) when OTP has 7 digits', () async {
      final result = await useCase(
        const ConfirmReservationOtpParams(
          reservationId: 'res-1',
          otpCode: '1234567',
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
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ReservationFailure) when OTP contains non-digit characters',
        () async {
      final result = await useCase(
        const ConfirmReservationOtpParams(
          reservationId: 'res-1',
          otpCode: '12345A',
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
      verifyZeroInteractions(mockRepository);
    });

    test(
        'returns Left(ReservationFailure) when reservation is expired (TTL 2h check)',
        () async {
      final expiredReservation = sampleReservation.copyWith(
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final result = await useCase(
        ConfirmReservationOtpParams(
          reservationId: 'res-1',
          otpCode: '482910',
          reservation: expiredReservation,
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, Reservation>(
            ReservationFailure(
              'La réservation a expiré (délai de 2h dépassé).',
            ),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ValidationFailure) when reservationId is empty',
        () async {
      final result = await useCase(
        const ConfirmReservationOtpParams(
          reservationId: '   ',
          otpCode: '482910',
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, Reservation>(
            ValidationFailure('Identifiant de réservation manquant.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ReservationFailure) when repository verification fails',
        () async {
      const failure = ReservationFailure('Code OTP incorrect ou session expirée.');
      when(
        () => mockRepository.confirmReservationOtp(
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const ConfirmReservationOtpParams(
          reservationId: 'res-1',
          otpCode: '482910',
        ),
      );

      expect(result, equals(const Left<Failure, Reservation>(failure)));
    });
  });
}
