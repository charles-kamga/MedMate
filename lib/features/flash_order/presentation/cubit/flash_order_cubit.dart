import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/flash_order.dart';
import 'flash_order_state.dart';

class FlashOrderCubit extends Cubit<FlashOrderState> {
  FlashOrderCubit()
      : super(
          const FlashOrderState(
            selectedMedication: defaultSampleMedication,
            selectedQuarter: 'Carrefour Warda, Poste Centrale',
            quantity: 1,
          ),
        );

  static const Medication defaultSampleMedication = Medication(
    id: 'med-coartem',
    nomCommercial: 'Coartem 20/120',
    dci: 'Artéméther + Luméfantrine',
    forme: 'Comprimé',
    dosage: '20 mg / 120 mg',
    classeTherapeutique: 'Antipaludique (CTA)',
    prixHomologueCfa: 2800,
    necessiteOrdonnance: false,
  );

  static final List<DispatchedPharmacy> defaultTargetPharmacies = [
    const DispatchedPharmacy(
      id: 'pharma-soleil',
      name: 'Pharmacie du Soleil',
      quarter: 'Warda, Yaoundé',
      distanceKm: 0.4,
      phone: '+237 677 12 34 56',
    ),
    const DispatchedPharmacy(
      id: 'pharma-centre',
      name: 'Grande Pharmacie du Centre',
      quarter: 'Avenue Kennedy, Yaoundé',
      distanceKm: 0.9,
      phone: '+237 699 88 77 66',
    ),
    const DispatchedPharmacy(
      id: 'pharma-obili',
      name: "Pharmacie d'Obili",
      quarter: 'Carrefour Obili, Yaoundé',
      distanceKm: 1.8,
      phone: '+237 655 44 33 22',
    ),
  ];

  void setRole(UserRole role) {
    emit(state.copyWith(userRole: role));
  }

  void selectMedication(Medication medication) {
    emit(state.copyWith(selectedMedication: medication));
  }

  void selectQuarter(String quarter) {
    emit(state.copyWith(selectedQuarter: quarter));
  }

  void setQuantity(int quantity) {
    if (quantity < 1) return;
    emit(state.copyWith(quantity: quantity));
  }

  void setActivePharmacistIndex(int index) {
    emit(state.copyWith(activePharmacistIndex: index));
  }

  /// 1. Lancement de la commande flash par le patient
  void launchFlashOrder() {
    final medication = state.selectedMedication ?? defaultSampleMedication;
    final orderId = 'ORD-${DateTime.now().millisecondsSinceEpoch % 1000000}';
    final now = DateTime.now();

    final order = FlashOrder(
      id: orderId,
      medication: medication,
      quarter: state.selectedQuarter,
      quantity: state.quantity,
      targets: defaultTargetPharmacies.map((p) => p.copyWith(status: PharmacistReplyType.waiting)).toList(),
      status: FlashOrderStatus.dispatching,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 2)),
    );

    emit(state.copyWith(activeOrder: order));
  }

  /// 2. Réponse d'un pharmacien (Règle du premier répondant gagnant)
  void submitPharmacistResponse({
    required String pharmacyId,
    required PharmacistReplyType reply,
    String? conditionNote,
  }) {
    final currentOrder = state.activeOrder;
    if (currentOrder == null) return;

    // Si la commande a déjà été remportée, verrouillage strict
    if (currentOrder.winnerPharmacy != null) return;

    final now = DateTime.now();
    final updatedTargets = currentOrder.targets.map((target) {
      if (target.id == pharmacyId) {
        return target.copyWith(
          status: reply,
          conditionNote: conditionNote,
          respondedAt: now,
        );
      }
      return target;
    }).toList();

    if (reply == PharmacistReplyType.available || reply == PharmacistReplyType.conditional) {
      // Ce pharmacien gagne immédiatement la commande !
      final winner = updatedTargets.firstWhere((p) => p.id == pharmacyId);
      final updatedOrder = currentOrder.copyWith(
        targets: updatedTargets,
        status: FlashOrderStatus.replied,
        winnerPharmacy: winner,
        winnerReplyType: reply,
        conditionNote: conditionNote,
      );
      emit(state.copyWith(activeOrder: updatedOrder));
    } else {
      // Le pharmacien a répondu "Indisponible"
      final anyPending = updatedTargets.any((p) => p.status == PharmacistReplyType.waiting);
      final updatedOrder = currentOrder.copyWith(
        targets: updatedTargets,
        status: anyPending ? FlashOrderStatus.dispatching : FlashOrderStatus.replied,
      );
      emit(state.copyWith(activeOrder: updatedOrder));
    }
  }

  /// 3. Confirmation du mode de paiement / retrait
  void confirmPayment({
    required FlashPaymentMethod method,
    String? phoneNumber,
  }) {
    final currentOrder = state.activeOrder;
    if (currentOrder == null) return;

    // Génération d'un code OTP sécurisé à 6 chiffres
    final otpCode = 'RET-${100000 + Random().nextInt(900000)}';
    final now = DateTime.now();

    final updatedOrder = currentOrder.copyWith(
      status: FlashOrderStatus.confirmed,
      paymentMethod: method,
      phoneNumber: phoneNumber ?? '699001122',
      reservationOtpCode: otpCode,
      expiresAt: now.add(const Duration(hours: 2)),
    );

    emit(state.copyWith(activeOrder: updatedOrder));
  }

  /// 4. Réinitialisation pour une nouvelle démonstration
  void resetOrder() {
    emit(
      state.copyWith(
        clearActiveOrder: true,
        userRole: UserRole.patient,
        quantity: 1,
      ),
    );
  }
}
