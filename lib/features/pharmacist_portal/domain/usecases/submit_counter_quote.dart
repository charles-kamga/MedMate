import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';
import '../repositories/pharmacist_portal_repository.dart';

/// Cas d'utilisation : Émission d'un devis par l'officine pour une demande flash
class SubmitCounterQuoteUseCase {
  const SubmitCounterQuoteUseCase(this._repository);

  final PharmacistPortalRepository _repository;

  Future<Either<Failure, PharmacyOffer>> call({
    required String orderId,
    required String pharmacyId,
    required PharmacyAvailabilityType availability,
    required int quotedPriceCfa,
    List<String> conditionRequirements = const [],
    String? conditionNote,
    bool proposesDelivery = false,
    int deliveryFeeCfa = 0,
    int? estimatedDeliveryMinutes,
  }) {
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
    if (availability != PharmacyAvailabilityType.unavailable && quotedPriceCfa < 0) {
      return Future.value(
        const Left(ReservationFailure('Le montant du devis ne peut être négatif.')),
      );
    }

    return _repository.submitQuote(
      orderId: orderId,
      pharmacyId: pharmacyId,
      availability: availability,
      quotedPriceCfa: quotedPriceCfa,
      conditionRequirements: conditionRequirements,
      conditionNote: conditionNote,
      proposesDelivery: proposesDelivery,
      deliveryFeeCfa: deliveryFeeCfa,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes,
    );
  }
}
