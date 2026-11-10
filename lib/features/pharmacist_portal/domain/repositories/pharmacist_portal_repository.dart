import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/incoming_demand.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

/// Contrat abstrait du portail comptoir officinal.
abstract class PharmacistPortalRepository {
  /// Récupère la liste des demandes flash entrantes en attente de réponse au comptoir.
  Future<Either<Failure, List<IncomingDemand>>> getIncomingDemands({
    required String pharmacyId,
  });

  /// Soumet l'offre/devis formulé par le pharmacien au comptoir avec prix et disponibilité.
  Future<Either<Failure, PharmacyOffer>> submitCounterQuote(
    CounterQuoteSubmission submission,
  );

  /// Valide au comptoir le code OTP à 6 chiffres présenté par le patient pour délivrer les médicaments.
  Future<Either<Failure, Reservation>> validatePickupOtp({
    required String pharmacyId,
    required String reservationId,
    required String otpCode,
  });

  /// Récupère les métriques journalières anonymisées de l'officine (Zéro PII - Loi n° 2024/017).
  Future<Either<Failure, PharmacyDailyAnalytics>> getPharmacyAnalytics({
    required String pharmacyId,
    required DateTime date,
  });
}
