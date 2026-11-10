import 'package:equatable/equatable.dart';

/// Statut du cycle de vie d'une réservation de médicament en officine.
enum ReservationStatus {
  /// Réservation créée par le patient, en attente de validation du code OTP au comptoir.
  pending,

  /// Code OTP vérifié avec succès au comptoir par le pharmacien.
  confirmedAtCounter,

  /// Médicaments remis au patient et transaction finalisée.
  completed,

  /// Réservation annulée par le patient ou par l'officine.
  cancelled,

  /// Réservation expirée après expiration du délai TTL de 2 heures.
  expired,
}

/// Réservation de médicament dans une officine avec code OTP et TTL strict de 2 heures.
class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.clientReservationId,
    required this.demandeId,
    required this.offreId,
    required this.pharmacyId,
    required this.codeRetraitOtp6Chiffres,
    required this.statut,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Identifiant unique de la réservation (UUID).
  final String id;

  /// Identifiant d'idempotence généré côté client (UUID v4).
  final String clientReservationId;

  /// Identifiant de la demande flash d'origine.
  final String demandeId;

  /// Identifiant de l'offre officine sélectionnée.
  final String offreId;

  /// Identifiant de l'officine de retrait.
  final String pharmacyId;

  /// Code de retrait OTP strictement composé de 6 chiffres décimaux (`^\d{6}$`).
  final String codeRetraitOtp6Chiffres;

  /// Statut actuel de la réservation.
  final ReservationStatus statut;

  /// Date et heure de création de la réservation.
  final DateTime createdAt;

  /// Date et heure d'expiration (TTL strict de 2 heures à compter de la création).
  final DateTime expiresAt;

  /// Indique si le délai TTL de 2 heures de la réservation est dépassé.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Durée restante avant expiration de la réservation.
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Crée une copie immuable avec les champs modifiés.
  Reservation copyWith({
    String? id,
    String? clientReservationId,
    String? demandeId,
    String? offreId,
    String? pharmacyId,
    String? codeRetraitOtp6Chiffres,
    ReservationStatus? statut,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      clientReservationId: clientReservationId ?? this.clientReservationId,
      demandeId: demandeId ?? this.demandeId,
      offreId: offreId ?? this.offreId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      codeRetraitOtp6Chiffres:
          codeRetraitOtp6Chiffres ?? this.codeRetraitOtp6Chiffres,
      statut: statut ?? this.statut,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientReservationId,
        demandeId,
        offreId,
        pharmacyId,
        codeRetraitOtp6Chiffres,
        statut,
        createdAt,
        expiresAt,
      ];
}
