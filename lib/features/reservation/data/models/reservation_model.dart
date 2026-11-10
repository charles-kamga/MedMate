import 'package:medmate/features/reservation/domain/entities/reservation.dart';

/// Modèle DTO pour une réservation de médicaments en officine avec code OTP.
class ReservationModel extends Reservation {
  const ReservationModel({
    required super.id,
    required super.clientReservationId,
    required super.demandeId,
    required super.offreId,
    required super.pharmacyId,
    required super.codeRetraitOtp6Chiffres,
    required super.statut,
    required super.createdAt,
    required super.expiresAt,
  });

  /// Désérialise une réservation depuis un dictionnaire JSON.
  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    final statutStr = json['statut'] as String? ?? 'pending';
    final statut = ReservationStatus.values.firstWhere(
      (e) => e.name == statutStr,
      orElse: () => ReservationStatus.pending,
    );

    return ReservationModel(
      id: json['id'] as String,
      clientReservationId: (json['client_reservation_id'] ??
          json['clientReservationId']) as String,
      demandeId: (json['demande_id'] ?? json['demandeId']) as String,
      offreId: (json['offre_id'] ?? json['offreId']) as String,
      pharmacyId: (json['pharmacy_id'] ?? json['pharmacyId']) as String,
      codeRetraitOtp6Chiffres: (json['code_retrait_otp_6_chiffres'] ??
          json['codeRetraitOtp6Chiffres']) as String,
      statut: statut,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory ReservationModel.fromDomain(Reservation domain) {
    return ReservationModel(
      id: domain.id,
      clientReservationId: domain.clientReservationId,
      demandeId: domain.demandeId,
      offreId: domain.offreId,
      pharmacyId: domain.pharmacyId,
      codeRetraitOtp6Chiffres: domain.codeRetraitOtp6Chiffres,
      statut: domain.statut,
      createdAt: domain.createdAt,
      expiresAt: domain.expiresAt,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_reservation_id': clientReservationId,
      'demande_id': demandeId,
      'offre_id': offreId,
      'pharmacy_id': pharmacyId,
      'code_retrait_otp_6_chiffres': codeRetraitOtp6Chiffres,
      'statut': statut.name,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// Convertit le modèle en entité de domaine.
  Reservation toDomain() => this;
}
