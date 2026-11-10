import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';

/// Modèle DTO pour les statistiques journalières d'activité officinale.
///
/// INVARIANT DE CONFIDENTIALITÉ MÉDICALE (Loi n° 2024/017 ANTIC / APDP):
/// ZÉRO PII (Personally Identifiable Information). Cette entité ne contient
/// strictement aucune donnée à caractère personnel de patient.
class PharmacyDailyAnalyticsModel extends PharmacyDailyAnalytics {
  const PharmacyDailyAnalyticsModel({
    required super.pharmacyId,
    required super.date,
    required super.totalDemandsReceived,
    required super.totalQuotesSubmitted,
    required super.totalReservationsConfirmed,
    required super.conversionRate,
    super.id,
    super.tempsMoyenReponseSecondes,
  });

  /// Désérialise les statistiques journalières depuis un dictionnaire JSON.
  factory PharmacyDailyAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final rawConversion =
        json['conversion_rate'] ?? json['conversionRate'] ?? 0.0;
    final conversionRate =
        (rawConversion is num) ? rawConversion.toDouble() : 0.0;

    final rawTemps = json['temps_moyen_reponse_secondes'] ??
        json['tempsMoyenReponseSecondes'];
    final tempsMoyen = (rawTemps is num) ? rawTemps.toInt() : null;

    final rawTotalDemands =
        json['total_demands_received'] ?? json['totalDemandsReceived'] ?? 0;
    final totalDemandsReceived =
        (rawTotalDemands is num) ? rawTotalDemands.toInt() : 0;

    final rawTotalQuotes =
        json['total_quotes_submitted'] ?? json['totalQuotesSubmitted'] ?? 0;
    final totalQuotesSubmitted =
        (rawTotalQuotes is num) ? rawTotalQuotes.toInt() : 0;

    final rawTotalReservations = json['total_reservations_confirmed'] ??
        json['totalReservationsConfirmed'] ??
        0;
    final totalReservationsConfirmed =
        (rawTotalReservations is num) ? rawTotalReservations.toInt() : 0;

    return PharmacyDailyAnalyticsModel(
      id: json['id'] as String?,
      pharmacyId: (json['pharmacy_id'] ?? json['pharmacyId']) as String,
      date: DateTime.parse(json['date'] as String),
      totalDemandsReceived: totalDemandsReceived,
      totalQuotesSubmitted: totalQuotesSubmitted,
      totalReservationsConfirmed: totalReservationsConfirmed,
      conversionRate: conversionRate,
      tempsMoyenReponseSecondes: tempsMoyen,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory PharmacyDailyAnalyticsModel.fromDomain(
    PharmacyDailyAnalytics domain,
  ) {
    return PharmacyDailyAnalyticsModel(
      id: domain.id,
      pharmacyId: domain.pharmacyId,
      date: domain.date,
      totalDemandsReceived: domain.totalDemandsReceived,
      totalQuotesSubmitted: domain.totalQuotesSubmitted,
      totalReservationsConfirmed: domain.totalReservationsConfirmed,
      conversionRate: domain.conversionRate,
      tempsMoyenReponseSecondes: domain.tempsMoyenReponseSecondes,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy_id': pharmacyId,
      'date': date.toIso8601String(),
      'total_demands_received': totalDemandsReceived,
      'total_quotes_submitted': totalQuotesSubmitted,
      'total_reservations_confirmed': totalReservationsConfirmed,
      'conversion_rate': conversionRate,
      'temps_moyen_reponse_secondes': tempsMoyenReponseSecondes,
    };
  }

  /// Convertit le modèle en entité de domaine.
  PharmacyDailyAnalytics toDomain() => this;
}
