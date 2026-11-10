import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacist_portal/data/models/incoming_demand_model.dart';
import 'package:medmate/features/pharmacist_portal/data/models/pharmacy_daily_analytics_model.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/pharmacy_offer_model.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';

/// Contrat abstrait de la source de données du portail comptoir pharmacien.
abstract class PharmacistPortalDataSource {
  /// Récupère la liste des demandes flash entrantes pour l'officine.
  Future<List<IncomingDemandModel>> getIncomingDemands(String pharmacyId);

  /// Soumet un devis au comptoir formulé avec prix et disponibilité.
  Future<PharmacyOfferModel> submitCounterQuote(
    CounterQuoteSubmissionModel submission,
  );

  /// Valide au comptoir le code OTP à 6 chiffres présenté par le patient.
  Future<ReservationModel> validatePickupOtp({
    required String pharmacyId,
    required String reservationId,
    required String otpCode,
  });

  /// Récupère les statistiques journalières anonymisées de l'officine (Zéro PII).
  Future<PharmacyDailyAnalyticsModel> getPharmacyAnalytics({
    required String pharmacyId,
    required DateTime date,
  });
}

/// Implémentation de la source de données du portail comptoir
/// connectée au coordinateur synchronisé en mémoire.
class PharmacistPortalDataSourceImpl implements PharmacistPortalDataSource {
  PharmacistPortalDataSourceImpl({InMemoryFlashOrderStore? store})
      : _store = store ?? InMemoryFlashOrderStore.instance;

  final InMemoryFlashOrderStore _store;

  @override
  Future<List<IncomingDemandModel>> getIncomingDemands(String pharmacyId) =>
      _store.getIncomingDemands(pharmacyId);

  @override
  Future<PharmacyOfferModel> submitCounterQuote(
    CounterQuoteSubmissionModel submission,
  ) =>
      _store.submitCounterQuote(submission);

  @override
  Future<ReservationModel> validatePickupOtp({
    required String pharmacyId,
    required String reservationId,
    required String otpCode,
  }) =>
      _store.validatePickupOtp(
        pharmacyId: pharmacyId,
        reservationId: reservationId,
        otpCode: otpCode,
      );

  @override
  Future<PharmacyDailyAnalyticsModel> getPharmacyAnalytics({
    required String pharmacyId,
    required DateTime date,
  }) =>
      _store.getPharmacyAnalytics(
        pharmacyId: pharmacyId,
        date: date,
      );
}
