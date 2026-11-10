import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

/// Paramètres requis pour la validation d'un code OTP au comptoir par le pharmacien.
class ValidatePickupOtpParams extends Equatable {
  const ValidatePickupOtpParams({
    required this.pharmacyId,
    required this.reservationId,
    required this.otpCode,
  });

  /// Identifiant de l'officine de pharmacie du comptoir.
  final String pharmacyId;

  /// Identifiant de la réservation à retirer.
  final String reservationId;

  /// Code OTP à 6 chiffres présenté par le patient.
  final String otpCode;

  @override
  List<Object?> get props => [pharmacyId, reservationId, otpCode];
}

/// Cas d'utilisation: validation du code OTP au comptoir pour délivrance des médicaments.
///
/// Valide le format à 6 chiffres de l'OTP et confirme le retrait sécurisé auprès du serveur.
class ValidatePickupOtpUseCase {
  const ValidatePickupOtpUseCase(this._repository);

  final PharmacistPortalRepository _repository;

  static final RegExp _otpRegex = RegExp(r'^\d{6}$');

  Future<Either<Failure, Reservation>> call(
    ValidatePickupOtpParams params,
  ) async {
    if (params.pharmacyId.trim().isEmpty ||
        params.reservationId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Paramètres de validation OTP invalides.'),
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

    return _repository.validatePickupOtp(
      pharmacyId: params.pharmacyId.trim(),
      reservationId: params.reservationId.trim(),
      otpCode: trimmedOtp,
    );
  }
}
