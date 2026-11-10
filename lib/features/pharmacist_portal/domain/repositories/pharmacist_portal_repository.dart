import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';

/// Contrat abstrait pour les opérations du portail comptoir officine
abstract class PharmacistPortalRepository {
  /// Récupère la liste des demandes de réservation en attente assignées à l'officine
  Future<Either<Failure, List<FlashOrder>>> getPendingOrdersForPharmacy(
    String pharmacyId,
  );

  /// Émet une proposition de devis selon l'un des 3 statuts ONPC
  Future<Either<Failure, PharmacyOffer>> submitQuote({
    required String orderId,
    required String pharmacyId,
    required PharmacyAvailabilityType availability,
    required int quotedPriceCfa,
    List<String> conditionRequirements = const [],
    String? conditionNote,
    bool proposesDelivery = false,
    int deliveryFeeCfa = 0,
    int? estimatedDeliveryMinutes,
  });

  /// Valide le code OTP à 6 chiffres présenté au comptoir par le patient
  Future<Either<Failure, FlashOrder>> validateOtpAtCounter({
    required String orderId,
    required String pharmacyId,
    required String otpCode,
  });
}
