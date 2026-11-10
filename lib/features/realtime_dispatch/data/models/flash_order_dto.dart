import '../../../../features/flash_order/domain/entities/basket_item.dart';
import '../../../../features/flash_order/domain/entities/flash_order.dart';
import '../../../../features/pharmacy_search/domain/entities/medication.dart';
import 'pharmacy_offer_dto.dart';

/// DTO de sérialisation / désérialisation pour l'entité [FlashOrder]
/// Assure la compatibilité stricte entre Supabase PostgreSQL (CDC/REST) et le domaine.
class FlashOrderDto {
  const FlashOrderDto._();

  static FlashOrder fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    final items = rawItems
        .map((e) => BasketItemDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawTargets = json['targets'] as List<dynamic>? ?? <dynamic>[];
    final targets = rawTargets
        .map((e) => DispatchedPharmacyDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawOffers = json['offers'] as List<dynamic>? ?? <dynamic>[];
    final offers = rawOffers
        .map((e) => PharmacyOfferDto.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final rawSelectedOffer = json['selected_offer'] ?? json['selectedOffer'];
    final selectedOffer = rawSelectedOffer != null
        ? PharmacyOfferDto.fromJson(Map<String, dynamic>.from(rawSelectedOffer as Map))
        : null;

    final createdAtStr = json['created_at'] ?? json['createdAt'];
    final createdAt = createdAtStr != null
        ? DateTime.parse(createdAtStr.toString())
        : DateTime.now();

    final expiresAtStr = json['expires_at'] ?? json['expiresAt'];
    final expiresAt = expiresAtStr != null
        ? DateTime.parse(expiresAtStr.toString())
        : createdAt.add(const Duration(hours: 2));

    return FlashOrder(
      id: (json['id'] ?? '').toString(),
      items: items,
      quarter: (json['quarter'] ?? '').toString(),
      targets: targets,
      createdAt: createdAt,
      expiresAt: expiresAt,
      currentWave: (json['current_wave'] ?? json['currentWave'] ?? 1) as int,
      waveTimeRemainingSeconds:
          (json['wave_time_remaining_seconds'] ?? json['waveTimeRemainingSeconds'] ?? 120) as int,
      offers: offers,
      selectedOffer: selectedOffer,
      status: _parseStatus((json['status'] ?? '').toString()),
      paymentMethod: _parsePaymentMethod(json['payment_method'] ?? json['paymentMethod']),
      paymentStatus: _parsePaymentStatus(json['payment_status'] ?? json['paymentStatus']),
      phoneNumber: json['phone_number']?.toString() ?? json['phoneNumber']?.toString(),
      reservationOtpCode: json['reservation_otp_code']?.toString() ?? json['reservationOtpCode']?.toString(),
      isPickedUp: (json['is_picked_up'] ?? json['isPickedUp'] ?? false) as bool,
    );
  }

  static Map<String, dynamic> toJson(FlashOrder order) {
    return {
      'id': order.id,
      'quarter': order.quarter,
      'current_wave': order.currentWave,
      'wave_time_remaining_seconds': order.waveTimeRemainingSeconds,
      'status': order.status.name,
      'payment_method': order.paymentMethod?.name,
      'payment_status': order.paymentStatus.name,
      'phone_number': order.phoneNumber,
      'reservation_otp_code': order.reservationOtpCode,
      'is_picked_up': order.isPickedUp,
      'created_at': order.createdAt.toIso8601String(),
      'expires_at': order.expiresAt.toIso8601String(),
      'items': order.items.map(BasketItemDto.toJson).toList(),
      'targets': order.targets.map(DispatchedPharmacyDto.toJson).toList(),
      'offers': order.offers.map(PharmacyOfferDto.toJson).toList(),
      if (order.selectedOffer != null)
        'selected_offer': PharmacyOfferDto.toJson(order.selectedOffer!),
    };
  }

  static FlashOrderStatus _parseStatus(String val) {
    for (final s in FlashOrderStatus.values) {
      if (s.name.toLowerCase() == val.toLowerCase()) return s;
    }
    return FlashOrderStatus.dispatchingWave;
  }

  static FlashPaymentMethod? _parsePaymentMethod(dynamic val) {
    if (val == null) return null;
    final str = val.toString().toLowerCase();
    for (final m in FlashPaymentMethod.values) {
      if (m.name.toLowerCase() == str) return m;
    }
    return null;
  }

  static FlashPaymentStatus _parsePaymentStatus(dynamic val) {
    if (val == null) return FlashPaymentStatus.pending;
    final str = val.toString().toLowerCase();
    for (final s in FlashPaymentStatus.values) {
      if (s.name.toLowerCase() == str) return s;
    }
    return FlashPaymentStatus.pending;
  }
}

/// DTO pour [DispatchedPharmacy]
class DispatchedPharmacyDto {
  const DispatchedPharmacyDto._();

  static DispatchedPharmacy fromJson(Map<String, dynamic> json) {
    final respondedAtStr = json['responded_at'] ?? json['respondedAt'];
    final distRaw = json['distance_km'] ?? json['distanceKm'] ?? 0.0;
    final dist = distRaw is num ? distRaw.toDouble() : 0.0;

    return DispatchedPharmacy(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      quarter: (json['quarter'] ?? '').toString(),
      distanceKm: dist,
      phone: (json['phone'] ?? '').toString(),
      waveIndex: (json['wave_index'] ?? json['waveIndex'] ?? 1) as int,
      status: _parseReplyType((json['status'] ?? '').toString()),
      conditionNote: json['condition_note']?.toString() ?? json['conditionNote']?.toString(),
      respondedAt: respondedAtStr != null ? DateTime.tryParse(respondedAtStr.toString()) : null,
      quotedPriceCfa: json['quoted_price_cfa'] as int? ?? json['quotedPriceCfa'] as int?,
    );
  }

  static Map<String, dynamic> toJson(DispatchedPharmacy pharmacy) {
    return {
      'id': pharmacy.id,
      'name': pharmacy.name,
      'quarter': pharmacy.quarter,
      'distance_km': pharmacy.distanceKm,
      'phone': pharmacy.phone,
      'wave_index': pharmacy.waveIndex,
      'status': pharmacy.status.name,
      'condition_note': pharmacy.conditionNote,
      'responded_at': pharmacy.respondedAt?.toIso8601String(),
      'quoted_price_cfa': pharmacy.quotedPriceCfa,
    };
  }

  static PharmacistReplyType _parseReplyType(String val) {
    for (final r in PharmacistReplyType.values) {
      if (r.name.toLowerCase() == val.toLowerCase()) return r;
    }
    return PharmacistReplyType.waiting;
  }
}

/// DTO pour [BasketItem]
class BasketItemDto {
  const BasketItemDto._();

  static BasketItem fromJson(Map<String, dynamic> json) {
    final rawMed = json['medication'];
    final medication = rawMed is Map<String, dynamic>
        ? MedicationDto.fromJson(rawMed)
        : rawMed is Map
            ? MedicationDto.fromJson(Map<String, dynamic>.from(rawMed))
            : MedicationDto.fromJson(json);

    return BasketItem(
      id: (json['id'] ?? '').toString(),
      medication: medication,
      quantity: (json['quantity'] ?? 1) as int,
      hasPrescription: (json['has_prescription'] ?? json['hasPrescription'] ?? false) as bool,
      prescriptionNote:
          json['prescription_note']?.toString() ?? json['prescriptionNote']?.toString(),
    );
  }

  static Map<String, dynamic> toJson(BasketItem item) {
    return {
      'id': item.id,
      'quantity': item.quantity,
      'has_prescription': item.hasPrescription,
      'prescription_note': item.prescriptionNote,
      'medication': MedicationDto.toJson(item.medication),
    };
  }
}

/// DTO pour [Medication]
class MedicationDto {
  const MedicationDto._();

  static Medication fromJson(Map<String, dynamic> json) {
    return Medication(
      id: (json['id'] ?? '').toString(),
      dci: (json['dci'] ?? '').toString(),
      nomCommercial: (json['nom_commercial'] ?? json['nomCommercial'] ?? '').toString(),
      forme: (json['forme'] ?? '').toString(),
      dosage: (json['dosage'] ?? '').toString(),
      classeTherapeutique:
          (json['classe_therapeutique'] ?? json['classeTherapeutique'] ?? '').toString(),
      prixHomologueCfa:
          (json['prix_homologue_cfa'] ?? json['prixHomologueCfa'] ?? 0) as int,
      necessiteOrdonnance:
          (json['necessite_ordonnance'] ?? json['necessiteOrdonnance'] ?? false) as bool,
    );
  }

  static Map<String, dynamic> toJson(Medication med) {
    return {
      'id': med.id,
      'dci': med.dci,
      'nom_commercial': med.nomCommercial,
      'forme': med.forme,
      'dosage': med.dosage,
      'classe_therapeutique': med.classeTherapeutique,
      'prix_homologue_cfa': med.prixHomologueCfa,
      'necessite_ordonnance': med.necessiteOrdonnance,
    };
  }
}
