import 'dart:async';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/basket_item.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import 'flash_order_state.dart';

class FlashOrderCubit extends Cubit<FlashOrderState> {
  FlashOrderCubit()
      : super(
          const FlashOrderState(
            basketItems: [
              BasketItem(
                id: 'item-paracetamol',
                medication: defaultSampleMedication,
                quantity: 2,
              ),
              BasketItem(
                id: 'item-vitaminc',
                medication: sampleMedicationVitC,
                quantity: 1,
              ),
            ],
            selectedQuarter: 'Carrefour Warda, Poste Centrale',
          ),
        );

  Timer? _waveTimer;

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

  void setRole(UserRole role) {
    emit(state.copyWith(userRole: role));
  }

  void selectQuarter(String quarter) {
    emit(state.copyWith(selectedQuarter: quarter));
  }

  void setActivePharmacistIndex(int index) {
    emit(state.copyWith(activePharmacistIndex: index));
  }

  // ===========================================================================
  // GESTION DU PANIER MULTI-MÉDICAMENTS (Section 3.1)
  // ===========================================================================

  void addBasketItem(Medication medication, {int quantity = 1, bool hasPrescription = false}) {
    final existingIndex = state.basketItems.indexWhere((i) => i.medication.id == medication.id);
    if (existingIndex >= 0) {
      final updated = List<BasketItem>.from(state.basketItems);
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(quantity: current.quantity + quantity);
      emit(state.copyWith(basketItems: updated));
    } else {
      final newItem = BasketItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        medication: medication,
        quantity: quantity,
        hasPrescription: hasPrescription,
      );
      emit(state.copyWith(basketItems: [...state.basketItems, newItem]));
    }
  }

  void removeBasketItem(String itemId) {
    final updated = state.basketItems.where((i) => i.id != itemId).toList();
    emit(state.copyWith(basketItems: updated));
  }

  void updateBasketItemQuantity(String itemId, int quantity) {
    if (quantity < 1) {
      removeBasketItem(itemId);
      return;
    }
    final updated = state.basketItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: quantity);
      }
      return item;
    }).toList();
    emit(state.copyWith(basketItems: updated));
  }

  void togglePrescription(String itemId) {
    final updated = state.basketItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(hasPrescription: !item.hasPrescription);
      }
      return item;
    }).toList();
    emit(state.copyWith(basketItems: updated));
  }

  /// Méthodes de compatibilité descendante
  void selectMedication(Medication medication) {
    emit(
      state.copyWith(
        basketItems: [
          BasketItem(
            id: 'legacy-item',
            medication: medication,
            quantity: 1,
          ),
        ],
      ),
    );
  }

  void setQuantity(int quantity) {
    if (quantity < 1) return;
    if (state.basketItems.isNotEmpty) {
      updateBasketItemQuantity(state.basketItems.first.id, quantity);
    }
  }

  // ===========================================================================
  // MOTEUR D'ATTRIBUTION EN VAGUES (2 pharmacies / 2 minutes) (Section 4)
  // ===========================================================================

  /// Lancement de la recherche sans choisir de pharmacie
  void launchFlashOrder() {
    _waveTimer?.cancel();

    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final now = DateTime.now();

    final order = FlashOrder(
      id: orderId,
      items: state.basketItems.isNotEmpty
          ? state.basketItems
          : const [
              BasketItem(
                id: 'fallback-item',
                medication: defaultSampleMedication,
                quantity: 1,
              ),
            ],
      quarter: state.selectedQuarter,
      targets: wave1Pharmacies.map((p) => p.copyWith(status: PharmacistReplyType.waiting)).toList(),
      currentWave: 1,
      waveTimeRemainingSeconds: 120,
      status: FlashOrderStatus.dispatchingWave,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 2)),
    );

    emit(state.copyWith(activeOrder: order));
    _startWaveCountdown();
  }

  void _startWaveCountdown() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentOrder = state.activeOrder;
      if (currentOrder == null || currentOrder.status == FlashOrderStatus.accepted || currentOrder.status == FlashOrderStatus.readyForPickup) {
        timer.cancel();
        return;
      }

      final remaining = currentOrder.waveTimeRemainingSeconds - 1;
      if (remaining <= 0) {
        timer.cancel();
        escalateToNextWave();
      } else {
        emit(
          state.copyWith(
            activeOrder: currentOrder.copyWith(
              waveTimeRemainingSeconds: remaining,
            ),
          ),
        );
      }
    });
  }

  /// Bouton de démonstration pour accélérer l'escalade de 2 minutes
  void accelerateWave() {
    escalateToNextWave();
  }

  /// Escalade vers la vague suivante (les 2 pharmacies suivantes)
  void escalateToNextWave() {
    final currentOrder = state.activeOrder;
    if (currentOrder == null) return;
    if (currentOrder.currentWave >= 2) {
      // Déjà au maximum des vagues prévues pour ce prototype
      return;
    }

    final newTargets = [
      ...currentOrder.targets,
      ...wave2Pharmacies.map((p) => p.copyWith(status: PharmacistReplyType.waiting)),
    ];

    final updatedOrder = currentOrder.copyWith(
      currentWave: 2,
      targets: newTargets,
      waveTimeRemainingSeconds: 120,
    );

    emit(state.copyWith(activeOrder: updatedOrder));
    _startWaveCountdown();
  }

  // ===========================================================================
  // RÉPONSES & OFFRES DES PHARMACIENS (Sections 5 & 6)
  // ===========================================================================

  /// Soumission d'une offre détaillée par un pharmacien partenaire
  /// Afya Santé ne fixe aucun prix : quotedPriceCfa provient exclusivement de l'officine.
  void submitPharmacistQuote({
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
    final currentOrder = state.activeOrder;
    if (currentOrder == null) return;

    final targetIndex = currentOrder.targets.indexWhere((p) => p.id == pharmacyId);
    if (targetIndex < 0) return;

    final targetPharma = currentOrder.targets[targetIndex];
    final now = DateTime.now();

    PharmacistReplyType replyType;
    switch (availability) {
      case PharmacyAvailabilityType.fullyAvailable:
        replyType = PharmacistReplyType.available;
      case PharmacyAvailabilityType.partiallyAvailable:
      case PharmacyAvailabilityType.conditional:
        replyType = PharmacistReplyType.conditional;
      case PharmacyAvailabilityType.unavailable:
        replyType = PharmacistReplyType.unavailable;
    }

    final updatedTarget = targetPharma.copyWith(
      status: replyType,
      conditionNote: conditionNote,
      respondedAt: now,
      quotedPriceCfa: quotedPriceCfa,
    );

    final updatedTargets = List<DispatchedPharmacy>.from(currentOrder.targets);
    updatedTargets[targetIndex] = updatedTarget;

    // Si indisponible, pas d'offre commerciale créée
    if (availability == PharmacyAvailabilityType.unavailable) {
      emit(
        state.copyWith(
          activeOrder: currentOrder.copyWith(
            targets: updatedTargets,
          ),
        ),
      );
      return;
    }

    final offer = PharmacyOffer(
      id: 'offer-${DateTime.now().millisecondsSinceEpoch}-$pharmacyId',
      pharmacyId: targetPharma.id,
      pharmacyName: targetPharma.name,
      quarter: targetPharma.quarter,
      distanceKm: targetPharma.distanceKm,
      phone: targetPharma.phone,
      availabilityType: availability,
      quotedPriceCfa: quotedPriceCfa,
      availableItemIds: availableItemIds ?? currentOrder.items.map((i) => i.id).toList(),
      missingItemIds: missingItemIds ?? const [],
      conditionRequirements: conditionRequirements ?? const [],
      conditionNote: conditionNote,
      proposesDelivery: proposesDelivery,
      deliveryFeeCfa: deliveryFeeCfa,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes,
      submittedAt: now,
    );

    // Ajouter l'offre sans remplacer les offres concurrentes (comparaison libre)
    final existingOffers = currentOrder.offers.where((o) => o.pharmacyId != pharmacyId).toList();
    final updatedOffers = [...existingOffers, offer];

    final updatedOrder = currentOrder.copyWith(
      targets: updatedTargets,
      offers: updatedOffers,
      status: currentOrder.status == FlashOrderStatus.dispatchingWave
          ? FlashOrderStatus.offersReceived
          : currentOrder.status,
    );

    emit(state.copyWith(activeOrder: updatedOrder));
  }

  /// Rétro-compatibilité avec les tests V1
  void submitPharmacistResponse({
    required String pharmacyId,
    required PharmacistReplyType reply,
    String? conditionNote,
  }) {
    if (reply == PharmacistReplyType.unavailable) {
      submitPharmacistQuote(
        pharmacyId: pharmacyId,
        availability: PharmacyAvailabilityType.unavailable,
        quotedPriceCfa: 0,
      );
      return;
    }

    final availability = reply == PharmacistReplyType.available
        ? PharmacyAvailabilityType.fullyAvailable
        : PharmacyAvailabilityType.conditional;

    submitPharmacistQuote(
      pharmacyId: pharmacyId,
      availability: availability,
      quotedPriceCfa: 2800,
      conditionRequirements: conditionNote != null ? [conditionNote] : const [],
      conditionNote: conditionNote,
    );
  }

  // ===========================================================================
  // CHOIX DU PATIENT & CONFIRMATION RÉSERVATION (Section 3 point 6 & Section 7)
  // ===========================================================================

  /// Arrêt manuel du timer de vagues (ex: tests ou navigation)
  void stopWaveTimer() {
    _waveTimer?.cancel();
    _waveTimer = null;
  }

  /// Le patient sélectionne souverainement l'offre retenue parmi celles reçues
  void selectOffer(String offerId) {
    _waveTimer?.cancel();
    _waveTimer = null;

    final currentOrder = state.activeOrder;
    if (currentOrder == null) return;

    final offerIndex = currentOrder.offers.indexWhere((o) => o.id == offerId);
    if (offerIndex < 0) return;

    final chosenOffer = currentOrder.offers[offerIndex].copyWith(isAccepted: true);
    final updatedOffers = currentOrder.offers.map((o) {
      return o.id == offerId ? chosenOffer : o.copyWith(isAccepted: false);
    }).toList();

    final updatedOrder = currentOrder.copyWith(
      offers: updatedOffers,
      selectedOffer: chosenOffer,
      status: FlashOrderStatus.accepted,
    );

    emit(state.copyWith(activeOrder: updatedOrder));
  }

  /// Confirmation de réservation avec choix du mode de paiement et génération code OTP
  void confirmPayment({
    required FlashPaymentMethod method,
    String? phoneNumber,
  }) {
    _waveTimer?.cancel();
    _waveTimer = null;

    final currentOrder = state.activeOrder;
    if (currentOrder == null) return;

    // Si aucune offre n'est explicitement choisie mais qu'il y en a une dispo, la retenir
    var activeOffer = currentOrder.selectedOffer;
    if (activeOffer == null && currentOrder.offers.isNotEmpty) {
      activeOffer = currentOrder.offers.first;
    }

    final otpCode = 'RET-${100000 + Random().nextInt(900000)}';
    final now = DateTime.now();

    final isMobileMoney = method == FlashPaymentMethod.orangeMoney || method == FlashPaymentMethod.mtnMoMo;

    final updatedOrder = currentOrder.copyWith(
      selectedOffer: activeOffer,
      status: FlashOrderStatus.readyForPickup,
      paymentMethod: method,
      paymentStatus: isMobileMoney ? FlashPaymentStatus.confirmed : FlashPaymentStatus.pending,
      phoneNumber: phoneNumber ?? '699001122',
      reservationOtpCode: otpCode,
      expiresAt: now.add(const Duration(hours: 2)),
    );

    emit(state.copyWith(activeOrder: updatedOrder));
  }

  // ===========================================================================
  // CONTRÔLE PHARMACIEN AU RETRAIT (Section 7)
  // ===========================================================================

  /// Validation du code OTP par le pharmacien lors du retrait au comptoir
  void validateOtpAtCounter({
    required String enteredOtp,
    required String pharmacyId,
  }) {
    final currentOrder = state.activeOrder;
    if (currentOrder == null || currentOrder.reservationOtpCode == null) {
      emit(
        state.copyWith(
          otpValidationSuccess: false,
          otpValidationError: 'Aucune réservation active trouvée.',
        ),
      );
      return;
    }

    final cleanEntered = enteredOtp.trim().toUpperCase();
    final cleanExpected = currentOrder.reservationOtpCode!.trim().toUpperCase();

    if (cleanEntered == cleanExpected || cleanEntered == cleanExpected.replaceAll('RET-', '')) {
      final updatedOrder = currentOrder.copyWith(
        status: FlashOrderStatus.delivered,
        paymentStatus: FlashPaymentStatus.confirmed,
        isPickedUp: true,
      );
      emit(
        state.copyWith(
          activeOrder: updatedOrder,
          otpValidationSuccess: true,
          otpValidationError: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          otpValidationSuccess: false,
          otpValidationError: 'Code OTP erroné. Veuillez vérifier le code sur le téléphone du patient.',
        ),
      );
    }
  }

  void clearOtpStatus() {
    emit(state.copyWith(clearOtpStatus: true));
  }

  // ===========================================================================
  // CYCLE DE VIE & RÉINITIALISATION
  // ===========================================================================

  void resetOrder() {
    _waveTimer?.cancel();
    emit(
      state.copyWith(
        clearActiveOrder: true,
        userRole: UserRole.patient,
        clearOtpStatus: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _waveTimer?.cancel();
    return super.close();
  }
}
