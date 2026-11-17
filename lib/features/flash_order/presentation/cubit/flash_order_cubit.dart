import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/basket_item.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import 'flash_order_demo_data.dart';
import 'flash_order_state.dart';

class FlashOrderCubit extends Cubit<FlashOrderState> {
  FlashOrderCubit()
      : super(
          const FlashOrderState(
            basketItems: [
              BasketItem(
                id: 'item-paracetamol',
                medication: FlashOrderDemoData.defaultSampleMedication,
                quantity: 2,
              ),
              BasketItem(
                id: 'item-vitaminc',
                medication: FlashOrderDemoData.sampleMedicationVitC,
                quantity: 1,
              ),
            ],
            selectedQuarter: 'Carrefour Warda, Poste Centrale',
          ),
        );

  Timer? _waveTimer;

  static const Medication defaultSampleMedication =
      FlashOrderDemoData.defaultSampleMedication;
  static const Medication sampleMedicationVitC =
      FlashOrderDemoData.sampleMedicationVitC;
  static const Medication sampleMedicationAmox =
      FlashOrderDemoData.sampleMedicationAmox;
  static final List<DispatchedPharmacy> wave1Pharmacies =
      FlashOrderDemoData.wave1Pharmacies;
  static final List<DispatchedPharmacy> wave2Pharmacies =
      FlashOrderDemoData.wave2Pharmacies;

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

  void addBasketItem(
    Medication medication, {
    int quantity = 1,
    bool hasPrescription = false,
  }) {
    final existingIndex =
        state.basketItems.indexWhere((i) => i.medication.id == medication.id);
    if (existingIndex >= 0) {
      final updated = List<BasketItem>.from(state.basketItems);
      final current = updated[existingIndex];
      updated[existingIndex] =
          current.copyWith(quantity: current.quantity + quantity);
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
    final order = FlashOrderDemoData.buildInitialOrder(
      basketItems: state.basketItems,
      quarter: state.selectedQuarter,
    );
    emit(state.copyWith(activeOrder: order));
    _startWaveCountdown();
  }

  void _startWaveCountdown() {
    _waveTimer?.cancel();
    _waveTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentOrder = state.activeOrder;
      if (currentOrder == null ||
          currentOrder.status == FlashOrderStatus.accepted ||
          currentOrder.status == FlashOrderStatus.readyForPickup) {
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
      ...wave2Pharmacies
          .map((p) => p.copyWith(status: PharmacistReplyType.waiting)),
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

    final updatedOrder = FlashOrderDemoData.applyPharmacistQuote(
      currentOrder: currentOrder,
      pharmacyId: pharmacyId,
      availability: availability,
      quotedPriceCfa: quotedPriceCfa,
      availableItemIds: availableItemIds,
      missingItemIds: missingItemIds,
      conditionRequirements: conditionRequirements,
      conditionNote: conditionNote,
      proposesDelivery: proposesDelivery,
      deliveryFeeCfa: deliveryFeeCfa,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes,
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

    final chosenOffer =
        currentOrder.offers[offerIndex].copyWith(isAccepted: true);
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

  void confirmPayment({
    required FlashPaymentMethod method,
    String? phoneNumber,
  }) {
    _waveTimer?.cancel();
    _waveTimer = null;

    final currentOrder = state.activeOrder;
    if (currentOrder == null) return;

    final updatedOrder = FlashOrderDemoData.buildConfirmedOrder(
      currentOrder: currentOrder,
      method: method,
      phoneNumber: phoneNumber,
    );
    emit(state.copyWith(activeOrder: updatedOrder));
  }

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

    final delivered = FlashOrderDemoData.tryValidateOtp(
      currentOrder: currentOrder,
      enteredOtp: enteredOtp,
    );
    if (delivered != null) {
      emit(
        state.copyWith(
          activeOrder: delivered,
          otpValidationSuccess: true,
          otpValidationError: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          otpValidationSuccess: false,
          otpValidationError:
              'Code OTP erroné. Veuillez vérifier le code sur le téléphone du patient.',
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
