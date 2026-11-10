import 'package:equatable/equatable.dart';

/// Statistiques journalières d'activité de l'officine sur la plateforme Afya Santé.
///
/// INVARIANT DE CONFIDENTIALITÉ MÉDICALE (Loi n° 2024/017 ANTIC / APDP):
/// ZÉRO PII (Personally Identifiable Information). Cette entité ne contient
/// strictement aucune donnée à caractère personnel de patient (aucun nom,
/// aucun numéro de téléphone, aucun historique nominatif de traitement).
/// Seules des métriques opérationnelles anonymisées et agrégées sont calculées.
class PharmacyDailyAnalytics extends Equatable {
  const PharmacyDailyAnalytics({
    required this.pharmacyId,
    required this.date,
    required this.totalDemandsReceived,
    required this.totalQuotesSubmitted,
    required this.totalReservationsConfirmed,
    required this.conversionRate,
    this.id,
    this.tempsMoyenReponseSecondes,
  });

  /// Identifiant unique de l'enregistrement statistique (optionnel/UUID).
  final String? id;

  /// Identifiant de l'officine de pharmacie.
  final String pharmacyId;

  /// Date de la journée d'activité.
  final DateTime date;

  /// Nombre total de demandes flash reçues par l'officine.
  final int totalDemandsReceived;

  /// Nombre total de devis/offres formulés au comptoir.
  final int totalQuotesSubmitted;

  /// Nombre total de réservations confirmées au comptoir par validation OTP.
  final int totalReservationsConfirmed;

  /// Taux de conversion devis acceptés / demandes répondues (ex: 0.85 = 85%).
  final double conversionRate;

  /// Temps moyen de réponse au comptoir en secondes.
  final int? tempsMoyenReponseSecondes;

  /// Alias francophone: nombre de demandes reçues.
  int get totalDemandesRecues => totalDemandsReceived;

  /// Alias francophone: nombre de devis envoyés.
  int get totalDevisEnvoyes => totalQuotesSubmitted;

  /// Alias francophone: nombre de réservations confirmées.
  int get totalReservationsConfirmees => totalReservationsConfirmed;

  /// Alias francophone: taux de conversion.
  double get tauxConversion => conversionRate;

  /// Crée une copie immuable avec les champs modifiés.
  PharmacyDailyAnalytics copyWith({
    String? id,
    String? pharmacyId,
    DateTime? date,
    int? totalDemandsReceived,
    int? totalQuotesSubmitted,
    int? totalReservationsConfirmed,
    double? conversionRate,
    int? tempsMoyenReponseSecondes,
  }) {
    return PharmacyDailyAnalytics(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      date: date ?? this.date,
      totalDemandsReceived: totalDemandsReceived ?? this.totalDemandsReceived,
      totalQuotesSubmitted: totalQuotesSubmitted ?? this.totalQuotesSubmitted,
      totalReservationsConfirmed:
          totalReservationsConfirmed ?? this.totalReservationsConfirmed,
      conversionRate: conversionRate ?? this.conversionRate,
      tempsMoyenReponseSecondes:
          tempsMoyenReponseSecondes ?? this.tempsMoyenReponseSecondes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pharmacyId,
        date,
        totalDemandsReceived,
        totalQuotesSubmitted,
        totalReservationsConfirmed,
        conversionRate,
        tempsMoyenReponseSecondes,
      ];
}
