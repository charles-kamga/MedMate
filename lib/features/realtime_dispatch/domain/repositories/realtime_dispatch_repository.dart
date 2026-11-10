import '../../../../features/flash_order/domain/entities/flash_order.dart';
import '../../../../features/flash_order/domain/entities/pharmacy_offer.dart';
import '../../../../features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import '../../../../features/reservation/domain/repositories/reservation_repository.dart';
import '../../data/datasources/adaptive_polling_fallback_manager.dart';

/// Contrat unifié du repository temps réel pour le dispatching géospatial PostGIS
/// Implémente et harmonise à la fois [ReservationRepository] (parcours patient)
/// et [PharmacistPortalRepository] (portail comptoir officine) tout en fournissant
/// les flux réactifs WebSockets avec résilience offline (3G/EDGE).
abstract class RealtimeDispatchRepository
    implements ReservationRepository, PharmacistPortalRepository {
  /// Flux temps réel d'une commande flash pour le patient
  Stream<FlashOrder> watchFlashOrder(String orderId);

  /// Flux temps réel des offres reçues pour une commande flash
  Stream<List<PharmacyOffer>> watchOffersForOrder(String orderId);

  /// Flux temps réel des commandes assignées à une officine pour la vague courante
  Stream<List<FlashOrder>> watchPendingOrdersForPharmacy(String pharmacyId);

  /// Flux d'état de la connexion WebSocket / mode dégradé polling
  Stream<RealtimeConnectionStatus> get connectionStatusStream;

  /// Libère les ressources et souscriptions
  void dispose();
}
