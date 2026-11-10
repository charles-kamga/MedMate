import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../repositories/pharmacist_portal_repository.dart';

/// Cas d'utilisation : Validation du code OTP à 6 chiffres au comptoir
class ValidateCounterOtpUseCase {
  const ValidateCounterOtpUseCase(this._repository);

  final PharmacistPortalRepository _repository;

  Future<Either<Failure, FlashOrder>> call({
    required String orderId,
    required String pharmacyId,
    required String otpCode,
  }) {
    final cleanOtp = otpCode.trim();
    if (orderId.trim().isEmpty) {
      return Future.value(
        const Left(NotFoundFailure('Identifiant de commande manquant.')),
      );
    }
    if (pharmacyId.trim().isEmpty) {
      return Future.value(
        const Left(NotFoundFailure("Identifiant d'officine manquant.")),
      );
    }
    // Validation du format : strictement 6 chiffres
    final otpRegex = RegExp(r'^\d{6}$');
    if (!otpRegex.hasMatch(cleanOtp)) {
      return Future.value(
        const Left(InvalidOtpFailure('Le code de retrait doit contenir exactement 6 chiffres.')),
      );
    }

    return _repository.validateOtpAtCounter(
      orderId: orderId,
      pharmacyId: pharmacyId,
      otpCode: cleanOtp,
    );
  }
}
