import '../../../../features/flash_order/domain/entities/pharmacy_offer.dart';

/// DTO de sérialisation / désérialisation pour [PharmacyOffer]
/// Supporte les schémas PostgreSQL / CDC Realtime (snake_case) et camelCase.
class PharmacyOfferDto {
  const PharmacyOfferDto._();

  static PharmacyOffer fromJson(Map<String, dynamic> json) {
    final rawAvailable = json['available_item_ids'] ?? json['availableItemIds'] ?? <dynamic>[];
    final availableItemIds = (rawAvailable as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    final rawMissing = json['missing_item_ids'] ?? json['missingItemIds'] ?? <dynamic>[];
    final missingItemIds = (rawMissing as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    final rawConditions =
        json['condition_requirements'] ?? json['conditionRequirements'] ?? <dynamic>[];
    final conditionRequirements = (rawConditions as List<dynamic>)
        .map((e) => e.toString())
        .toList();

    final submittedAtStr = json['submitted_at'] ?? json['submittedAt'];
    final submittedAt = submittedAtStr != null
        ? DateTime.tryParse(submittedAtStr.toString()) ?? DateTime.now()
        : DateTime.now();

    final distanceRaw = json['distance_km'] ?? json['distanceKm'] ?? 0.0;
    final distanceKm = distanceRaw is num ? distanceRaw.toDouble() : 0.0;

    final priceRaw = json['quoted_price_cfa'] ?? json['quotedPriceCfa'] ?? 0;
    final quotedPriceCfa = priceRaw is num ? priceRaw.toInt() : 0;

    final deliveryFeeRaw = json['delivery_fee_cfa'] ?? json['deliveryFeeCfa'] ?? 0;
    final deliveryFeeCfa = deliveryFeeRaw is num ? deliveryFeeRaw.toInt() : 0;

    final estDeliveryRaw =
        json['estimated_delivery_minutes'] ?? json['estimatedDeliveryMinutes'];
    final estimatedDeliveryMinutes =
        estDeliveryRaw != null && estDeliveryRaw is num ? estDeliveryRaw.toInt() : null;

    return PharmacyOffer(
      id: (json['id'] ?? '').toString(),
      pharmacyId: (json['pharmacy_id'] ?? json['pharmacyId'] ?? '').toString(),
      pharmacyName: (json['pharmacy_name'] ?? json['pharmacyName'] ?? '').toString(),
      quarter: (json['quarter'] ?? '').toString(),
      distanceKm: distanceKm,
      phone: (json['phone'] ?? '').toString(),
      availabilityType:
          _parseAvailabilityType((json['availability_type'] ?? json['availabilityType'] ?? '').toString()),
      quotedPriceCfa: quotedPriceCfa,
      availableItemIds: availableItemIds,
      missingItemIds: missingItemIds,
      conditionRequirements: conditionRequirements,
      conditionNote: json['condition_note']?.toString() ?? json['conditionNote']?.toString(),
      proposesDelivery:
          (json['proposes_delivery'] ?? json['proposesDelivery'] ?? false) as bool,
      deliveryFeeCfa: deliveryFeeCfa,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes,
      submittedAt: submittedAt,
      isAccepted: (json['is_accepted'] ?? json['isAccepted'] ?? false) as bool,
    );
  }

  static Map<String, dynamic> toJson(PharmacyOffer offer) {
    return {
      'id': offer.id,
      'pharmacy_id': offer.pharmacyId,
      'pharmacy_name': offer.pharmacyName,
      'quarter': offer.quarter,
      'distance_km': offer.distanceKm,
      'phone': offer.phone,
      'availability_type': offer.availabilityType.name,
      'quoted_price_cfa': offer.quotedPriceCfa,
      'available_item_ids': offer.availableItemIds,
      'missing_item_ids': offer.missingItemIds,
      'condition_requirements': offer.conditionRequirements,
      'condition_note': offer.conditionNote,
      'proposes_delivery': offer.proposesDelivery,
      'delivery_fee_cfa': offer.deliveryFeeCfa,
      'estimated_delivery_minutes': offer.estimatedDeliveryMinutes,
      'submitted_at': offer.submittedAt.toIso8601String(),
      'is_accepted': offer.isAccepted,
    };
  }

  static PharmacyAvailabilityType _parseAvailabilityType(String val) {
    for (final a in PharmacyAvailabilityType.values) {
      if (a.name.toLowerCase() == val.toLowerCase()) return a;
    }
    return PharmacyAvailabilityType.fullyAvailable;
  }
}
