import 'package:equatable/equatable.dart';

/// Type de disponibilité déclaré par le pharmacien
enum PharmacyAvailabilityType {
  fullyAvailable,
  partiallyAvailable,
  conditional,
  unavailable,
}

/// Offre commerciale et médicale émise par une officine partenaire
/// Afya Santé ne fixe aucun prix : quotedPriceCfa provient exclusivement du pharmacien.
class PharmacyOffer extends Equatable {
  const PharmacyOffer({
    required this.id,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.quarter,
    required this.distanceKm,
    required this.phone,
    required this.availabilityType,
    required this.quotedPriceCfa,
    required this.submittedAt,
    this.availableItemIds = const [],
    this.missingItemIds = const [],
    this.conditionRequirements = const [],
    this.conditionNote,
    this.proposesDelivery = false,
    this.deliveryFeeCfa = 0,
    this.estimatedDeliveryMinutes,
    this.isAccepted = false,
  });

  final String id;
  final String pharmacyId;
  final String pharmacyName;
  final String quarter;
  final double distanceKm;
  final String phone;
  final PharmacyAvailabilityType availabilityType;
  final int quotedPriceCfa;
  final List<String> availableItemIds;
  final List<String> missingItemIds;
  final List<String> conditionRequirements;
  final String? conditionNote;
  final bool proposesDelivery;
  final int deliveryFeeCfa;
  final int? estimatedDeliveryMinutes;
  final DateTime submittedAt;
  final bool isAccepted;

  /// Montant total avec frais de livraison éventuels
  int get grandTotalCfa => quotedPriceCfa + (proposesDelivery ? deliveryFeeCfa : 0);

  bool get isFullMatch => missingItemIds.isEmpty && availabilityType == PharmacyAvailabilityType.fullyAvailable;

  PharmacyOffer copyWith({
    String? id,
    String? pharmacyId,
    String? pharmacyName,
    String? quarter,
    double? distanceKm,
    String? phone,
    PharmacyAvailabilityType? availabilityType,
    int? quotedPriceCfa,
    List<String>? availableItemIds,
    List<String>? missingItemIds,
    List<String>? conditionRequirements,
    String? conditionNote,
    bool? proposesDelivery,
    int? deliveryFeeCfa,
    int? estimatedDeliveryMinutes,
    DateTime? submittedAt,
    bool? isAccepted,
  }) {
    return PharmacyOffer(
      id: id ?? this.id,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      quarter: quarter ?? this.quarter,
      distanceKm: distanceKm ?? this.distanceKm,
      phone: phone ?? this.phone,
      availabilityType: availabilityType ?? this.availabilityType,
      quotedPriceCfa: quotedPriceCfa ?? this.quotedPriceCfa,
      availableItemIds: availableItemIds ?? this.availableItemIds,
      missingItemIds: missingItemIds ?? this.missingItemIds,
      conditionRequirements: conditionRequirements ?? this.conditionRequirements,
      conditionNote: conditionNote ?? this.conditionNote,
      proposesDelivery: proposesDelivery ?? this.proposesDelivery,
      deliveryFeeCfa: deliveryFeeCfa ?? this.deliveryFeeCfa,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes ?? this.estimatedDeliveryMinutes,
      submittedAt: submittedAt ?? this.submittedAt,
      isAccepted: isAccepted ?? this.isAccepted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pharmacyId,
        pharmacyName,
        quarter,
        distanceKm,
        phone,
        availabilityType,
        quotedPriceCfa,
        availableItemIds,
        missingItemIds,
        conditionRequirements,
        conditionNote,
        proposesDelivery,
        deliveryFeeCfa,
        estimatedDeliveryMinutes,
        submittedAt,
        isAccepted,
      ];
}
