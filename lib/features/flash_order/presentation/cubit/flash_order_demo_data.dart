import 'package:medmate/features/flash_order/presentation/cubit/flash_order_cubit.dart'
    show FlashOrderCubit;

import 'dart:math';
import '../../../../core/config/app_config.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/basket_item.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';

/// Données de démonstration et fabrique d'offres pour [FlashOrderCubit].
class FlashOrderDemoData {
  const FlashOrderDemoData._();

  static const Medication defaultSampleMedication = Medication(
    id: 'med-paracetamol',
    nomCommercial: 'Paracétamol 500 mg',
    dci: 'Paracétamol',
    forme: 'Comprimé',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique / Antipyrétique',
    prixHomologueCfa: 1500,
    necessiteOrdonnance: false,
  );

  static const Medication sampleMedicationVitC = Medication(
    id: 'med-vitaminc',
    nomCommercial: 'Vitamine C 1000 mg',
    dci: 'Acide ascorbique',
    forme: 'Comprimé effervescent',
    dosage: '1000 mg',
    classeTherapeutique: 'Vitamines',
    prixHomologueCfa: 2000,
    necessiteOrdonnance: false,
  );

  static const Medication sampleMedicationAmox = Medication(
    id: 'med-amox',
    nomCommercial: 'Amoxicilline 500 mg',
    dci: 'Amoxicilline',
    forme: 'Gélule',
    dosage: '500 mg',
    classeTherapeutique: 'Antibiotique',
    prixHomologueCfa: 3200,
    necessiteOrdonnance: true,
  );

  /// Vague 1 : Les 2 pharmacies partenaires les plus proches (Section 4 du CDC)
  static final List<DispatchedPharmacy> wave1Pharmacies = [
    const DispatchedPharmacy(
      id: 'pharma-soleil',
      name: 'Pharmacie du Soleil',
      quarter: 'Carrefour Warda',
      distanceKm: 0.4,
      phone: '+237 677 12 34 56',
      waveIndex: 1,
    ),
    const DispatchedPharmacy(
      id: 'pharma-centre',
      name: 'Grande Pharmacie du Centre',
      quarter: 'Poste Centrale',
      distanceKm: 0.9,
      phone: '+237 699 88 77 66',
      waveIndex: 1,
    ),
  ];

  /// Vague 2 : Les 2 pharmacies partenaires suivantes (Escalade après 2 minutes)
  static final List<DispatchedPharmacy> wave2Pharmacies = [
    const DispatchedPharmacy(
      id: 'pharma-obili',
      name: "Pharmacie d'Obili",
      quarter: 'Carrefour Obili',
      distanceKm: 1.8,
      phone: '+237 655 44 33 22',
      waveIndex: 2,
    ),
    const DispatchedPharmacy(
      id: 'pharma-acacia',
      name: 'Pharmacie Acacia Biyem-Assi',
      quarter: 'Carrefour Acacia',
      distanceKm: 2.4,
      phone: '+237 670 99 88 77',
      waveIndex: 2,
    ),
  ];

  /// Applique la réponse d'une officine sur une commande active.
  static FlashOrder applyPharmacistQuote({
    required FlashOrder currentOrder,
    required String pharmacyId,
    required PharmacyAvailabilityType availability,
    required int quotedPriceCfa,
    List<String>? availableItemIds,
    List<String>? missingItemIds,
    List<String>? conditionRequirements,
    String? conditionNote,
    bool proposesDelivery = false,
    int deliveryFeeCfa = 0,
    int? estimatedDeliveryMinutes,
  }) {
    final targetIndex =
        currentOrder.targets.indexWhere((p) => p.id == pharmacyId);
    if (targetIndex < 0) return currentOrder;

    final targetPharma = currentOrder.targets[targetIndex];
    final now = DateTime.now();

    final replyType = switch (availability) {
      PharmacyAvailabilityType.fullyAvailable => PharmacistReplyType.available,
      PharmacyAvailabilityType.partiallyAvailable ||
      PharmacyAvailabilityType.conditional =>
        PharmacistReplyType.conditional,
      PharmacyAvailabilityType.unavailable => PharmacistReplyType.unavailable,
    };

    final updatedTargets = List<DispatchedPharmacy>.from(currentOrder.targets);
    updatedTargets[targetIndex] = targetPharma.copyWith(
      status: replyType,
      conditionNote: conditionNote,
      respondedAt: now,
      quotedPriceCfa: quotedPriceCfa,
    );

    if (availability == PharmacyAvailabilityType.unavailable) {
      return currentOrder.copyWith(targets: updatedTargets);
    }

    final offer = PharmacyOffer(
      id: 'offer-${now.millisecondsSinceEpoch}-$pharmacyId',
      pharmacyId: targetPharma.id,
      pharmacyName: targetPharma.name,
      quarter: targetPharma.quarter,
      distanceKm: targetPharma.distanceKm,
      phone: targetPharma.phone,
      availabilityType: availability,
      quotedPriceCfa: quotedPriceCfa,
      availableItemIds:
          availableItemIds ?? currentOrder.items.map((i) => i.id).toList(),
      missingItemIds: missingItemIds ?? const [],
      conditionRequirements: conditionRequirements ?? const [],
      conditionNote: conditionNote,
      proposesDelivery: proposesDelivery,
      deliveryFeeCfa: deliveryFeeCfa,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes,
      submittedAt: now,
    );

    final existingOffers =
        currentOrder.offers.where((o) => o.pharmacyId != pharmacyId).toList();
    return currentOrder.copyWith(
      targets: updatedTargets,
      offers: [...existingOffers, offer],
      status: currentOrder.status == FlashOrderStatus.dispatchingWave
          ? FlashOrderStatus.offersReceived
          : currentOrder.status,
    );
  }

  /// Construit la commande confirmée avec OTP 15 min lors du choix du paiement.
  static FlashOrder buildConfirmedOrder({
    required FlashOrder currentOrder,
    required FlashPaymentMethod method,
    String? phoneNumber,
  }) {
    var activeOffer = currentOrder.selectedOffer;
    if (activeOffer == null && currentOrder.offers.isNotEmpty) {
      activeOffer = currentOrder.offers.first;
    }
    final otpCode = 'RET-${100000 + Random().nextInt(900000)}';
    final now = DateTime.now();
    final isMobileMoney = method == FlashPaymentMethod.orangeMoney ||
        method == FlashPaymentMethod.mtnMoMo;
    return currentOrder.copyWith(
      selectedOffer: activeOffer,
      status: FlashOrderStatus.readyForPickup,
      paymentMethod: method,
      paymentStatus: isMobileMoney
          ? FlashPaymentStatus.confirmed
          : FlashPaymentStatus.pending,
      phoneNumber: phoneNumber ?? '699001122',
      reservationOtpCode: otpCode,
      expiresAt: now.add(AppConfig.otpValidityDuration),
    );
  }

  /// Vérifie le code OTP saisi au comptoir et retourne la commande livrée ou null.
  static FlashOrder? tryValidateOtp({
    required FlashOrder currentOrder,
    required String enteredOtp,
  }) {
    final expected = currentOrder.reservationOtpCode;
    if (expected == null) return null;
    final cleanEntered = enteredOtp.trim().toUpperCase();
    final cleanExpected = expected.trim().toUpperCase();
    if (cleanEntered == cleanExpected ||
        cleanEntered == cleanExpected.replaceAll('RET-', '')) {
      return currentOrder.copyWith(
        status: FlashOrderStatus.delivered,
        paymentStatus: FlashPaymentStatus.confirmed,
        isPickedUp: true,
      );
    }
    return null;
  }

  /// Construit une nouvelle demande flash en vague 1.
  static FlashOrder buildInitialOrder({
    required List<BasketItem> basketItems,
    required String quarter,
  }) {
    final now = DateTime.now();
    final orderId = 'ORD-${now.millisecondsSinceEpoch % 1000000}';
    return FlashOrder(
      id: orderId,
      items: basketItems.isNotEmpty
          ? basketItems
          : const [
              BasketItem(
                id: 'fallback-item',
                medication: defaultSampleMedication,
                quantity: 1,
              ),
            ],
      quarter: quarter,
      targets: wave1Pharmacies
          .map((p) => p.copyWith(status: PharmacistReplyType.waiting))
          .toList(),
      currentWave: 1,
      waveTimeRemainingSeconds: 120,
      status: FlashOrderStatus.dispatchingWave,
      createdAt: now,
      expiresAt: now.add(AppConfig.otpValidityDuration),
    );
  }
}
