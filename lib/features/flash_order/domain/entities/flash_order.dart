import 'package:equatable/equatable.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';

/// Statuts possibles de réponse d'un pharmacien selon les exigences du client
enum PharmacistReplyType {
  waiting,
  available,
  unavailable,
  conditional,
}

/// Méthodes de paiement / retrait supportées
enum FlashPaymentMethod {
  orangeMoney,
  mtnMoMo,
  cashCounter,
}

/// Statut global du flux de commande flash
enum FlashOrderStatus {
  idle,
  dispatching,
  replied,
  confirmed,
}

/// Pharmacie ciblée lors d'un dispatch (2 à 3 pharmacies partenaires)
class DispatchedPharmacy extends Equatable {
  const DispatchedPharmacy({
    required this.id,
    required this.name,
    required this.quarter,
    required this.distanceKm,
    required this.phone,
    this.status = PharmacistReplyType.waiting,
    this.conditionNote,
    this.respondedAt,
  });

  final String id;
  final String name;
  final String quarter;
  final double distanceKm;
  final String phone;
  final PharmacistReplyType status;
  final String? conditionNote;
  final DateTime? respondedAt;

  DispatchedPharmacy copyWith({
    PharmacistReplyType? status,
    String? conditionNote,
    DateTime? respondedAt,
  }) {
    return DispatchedPharmacy(
      id: id,
      name: name,
      quarter: quarter,
      distanceKm: distanceKm,
      phone: phone,
      status: status ?? this.status,
      conditionNote: conditionNote ?? this.conditionNote,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        quarter,
        distanceKm,
        phone,
        status,
        conditionNote,
        respondedAt,
      ];
}

/// Entité maîtresse de la commande flash multi-pharmacies
class FlashOrder extends Equatable {
  const FlashOrder({
    required this.id,
    required this.medication,
    required this.quarter,
    required this.targets,
    required this.createdAt,
    required this.expiresAt,
    this.quantity = 1,
    this.status = FlashOrderStatus.dispatching,
    this.winnerPharmacy,
    this.winnerReplyType,
    this.conditionNote,
    this.paymentMethod,
    this.phoneNumber,
    this.reservationOtpCode,
  });

  final String id;
  final Medication medication;
  final String quarter;
  final int quantity;
  final List<DispatchedPharmacy> targets;
  final FlashOrderStatus status;
  final DispatchedPharmacy? winnerPharmacy;
  final PharmacistReplyType? winnerReplyType;
  final String? conditionNote;
  final FlashPaymentMethod? paymentMethod;
  final String? phoneNumber;
  final String? reservationOtpCode;
  final DateTime createdAt;
  final DateTime expiresAt;

  int get totalAmountCfa => medication.prixHomologueCfa * quantity;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  FlashOrder copyWith({
    Medication? medication,
    String? quarter,
    int? quantity,
    List<DispatchedPharmacy>? targets,
    FlashOrderStatus? status,
    DispatchedPharmacy? winnerPharmacy,
    PharmacistReplyType? winnerReplyType,
    String? conditionNote,
    FlashPaymentMethod? paymentMethod,
    String? phoneNumber,
    String? reservationOtpCode,
    DateTime? expiresAt,
  }) {
    return FlashOrder(
      id: id,
      medication: medication ?? this.medication,
      quarter: quarter ?? this.quarter,
      quantity: quantity ?? this.quantity,
      targets: targets ?? this.targets,
      status: status ?? this.status,
      winnerPharmacy: winnerPharmacy ?? this.winnerPharmacy,
      winnerReplyType: winnerReplyType ?? this.winnerReplyType,
      conditionNote: conditionNote ?? this.conditionNote,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      reservationOtpCode: reservationOtpCode ?? this.reservationOtpCode,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        medication,
        quarter,
        quantity,
        targets,
        status,
        winnerPharmacy,
        winnerReplyType,
        conditionNote,
        paymentMethod,
        phoneNumber,
        reservationOtpCode,
        createdAt,
        expiresAt,
      ];
}
