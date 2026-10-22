import 'package:equatable/equatable.dart';

/// Statuts de réservation de médicament
enum ReservationStatus {
  pending,
  confirmed,
  expired,
  cancelled,
  completed,
}

/// Entité représentant une réservation temporaire sécurisée (TTL 2h)
class Reservation extends Equatable {
  const Reservation({
    required this.id,
    required this.clientReservationId,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.medicationId,
    required this.medicationName,
    required this.quantite,
    required this.codeRetraitOtp,
    required this.statut,
    required this.createdAt,
    required this.expiresAt,
  });

  final String id;
  final String clientReservationId;
  final String pharmacyId;
  final String pharmacyName;
  final String medicationId;
  final String medicationName;
  final int quantite;
  final String codeRetraitOtp;
  final ReservationStatus statut;
  final DateTime createdAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        id,
        clientReservationId,
        pharmacyId,
        medicationId,
        quantite,
        codeRetraitOtp,
        statut,
        expiresAt,
      ];
}
