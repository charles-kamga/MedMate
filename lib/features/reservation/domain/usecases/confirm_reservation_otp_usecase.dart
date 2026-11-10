import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';

/// Paramètres requis pour la confirmation d'une réservation au comptoir par code OTP.
class ConfirmReservationOtpParams extends Equatable {
  const ConfirmReservationOtpParams({
    required this.reservationId,
    required this.otpCode,
    this.reservation,
  });

  /// Identifiant unique de la réservation.
  final String reservationId;

  /// Code de retrait OTP à 6 chiffres transmis au patient.
  final String otpCode;

  /// Instance optionnelle de la réservation permettant de vérifier son expiration TTL de 2h.
  final Reservation? reservation;

  @override
  List<Object?> get props => [reservationId, otpCode, reservation];
}

/// Cas d'utilisation: confirmation d'une réservation via code OTP à 6 chiffres.
///
/// Vérifie le format numérique à 6 chiffres de l'OTP, le respect du délai TTL de 2 heures
/// et délègue la confirmation sécurisée au comptoir au référentiel.
class ConfirmReservationOtpUseCase {
  const ConfirmReservationOtpUseCase(this._repository);

  final ReservationRepository _repository;

  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  Future<Either<Failure, Reservation>> call(
    ConfirmReservationOtpParams params,
  ) async {
    if (params.reservationId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Identifiant de réservation manquant.'),
      );
    }

    final trimmedOtp = params.otpCode.trim();
    if (!_otpRegex.hasMatch(trimmedOtp)) {
      return const Left(
        ReservationFailure(
          'Le code OTP doit comporter exactement 6 chiffres.',
        ),
      );
    }

    // Vérification de la validité TTL (2 heures) si l'entité est fournie
    if (params.reservation != null && params.reservation!.isExpired) {
      return const Left(
        ReservationFailure(
          'La réservation a expiré (délai de 2h dépassé).',
        ),
      );
    }

    return _repository.confirmReservationOtp(
      reservationId: params.reservationId.trim(),
      otpCode: trimmedOtp,
    );
  }
}
