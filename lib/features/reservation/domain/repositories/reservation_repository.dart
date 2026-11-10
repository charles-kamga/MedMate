import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/errors/failures.dart';
import '../entities/basket_item.dart';
import '../entities/flash_order.dart';
import '../entities/pharmacy_offer.dart';
import '../entities/reservation.dart';

/// Contrat du repository de réservation inversée par vagues
abstract class ReservationRepository {
  /// Soumet une demande de recherche flash pour un panier et un repère donnés
  Future<Either<Failure, FlashOrder>> submitFlashRequest({
    required List<BasketItem> items,
    required YaoundeLandmark landmark,
  });

  /// Escalade la recherche vers la vague suivante de pharmacies partenaires
  Future<Either<Failure, FlashOrder>> escalateDispatchWave(String orderId);

  /// Récupère l'état actualisé d'une demande flash par son identifiant
  Future<Either<Failure, FlashOrder>> getFlashRequestById(String orderId);

  /// Valide le choix d'une offre officinale par le patient et génère le ticket OTP
  Future<Either<Failure, Reservation>> selectPharmacyOffer({
    required String orderId,
    required PharmacyOffer offer,
    required String patientPhone,
  });
}
