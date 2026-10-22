import '../../domain/entities/reservation.dart';

/// DTO pour la désérialisation typée des réservations
class ReservationModel extends Reservation {
  const ReservationModel({
    required super.id,
    required super.clientReservationId,
    required super.pharmacyId,
    required super.pharmacyName,
    required super.medicationId,
    required super.medicationName,
    required super.quantite,
    required super.codeRetraitOtp,
    required super.statut,
    required super.createdAt,
    required super.expiresAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String? ?? '',
      clientReservationId: json['client_reservation_id'] as String? ?? '',
      pharmacyId: json['pharmacy_id'] as String? ?? '',
      pharmacyName: json['pharmacy_name'] as String? ?? 'Pharmacie',
      medicationId: json['medication_id'] as String? ?? '',
      medicationName: json['medication_name'] as String? ?? 'Médicament',
      quantite: json['quantite'] as int? ?? 1,
      codeRetraitOtp: json['code_retrait_otp'] as String? ?? '',
      statut: _parseStatus(json['statut'] as String?),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] as String? ?? '') ??
          DateTime.now().add(const Duration(hours: 2)),
    );
  }

  static ReservationStatus _parseStatus(String? status) {
    switch (status) {
      case 'confirmed':
        return ReservationStatus.confirmed;
      case 'expired':
        return ReservationStatus.expired;
      case 'cancelled':
        return ReservationStatus.cancelled;
      case 'completed':
        return ReservationStatus.completed;
      case 'pending':
      default:
        return ReservationStatus.pending;
    }
  }
}
