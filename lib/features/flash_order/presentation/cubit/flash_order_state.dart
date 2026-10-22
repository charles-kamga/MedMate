import 'package:equatable/equatable.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/flash_order.dart';

enum UserRole {
  patient,
  pharmacist,
}

class FlashOrderState extends Equatable {
  const FlashOrderState({
    this.userRole = UserRole.patient,
    this.selectedMedication,
    this.selectedQuarter = 'Carrefour Warda, Poste Centrale',
    this.quantity = 1,
    this.activeOrder,
    this.activePharmacistIndex = 0,
    this.errorMessage,
  });

  final UserRole userRole;
  final Medication? selectedMedication;
  final String selectedQuarter;
  final int quantity;
  final FlashOrder? activeOrder;
  final int activePharmacistIndex;
  final String? errorMessage;

  bool get hasActiveOrder => activeOrder != null;
  bool get isDispatching => activeOrder?.status == FlashOrderStatus.dispatching;
  bool get hasWinner => activeOrder?.winnerPharmacy != null;
  bool get isConfirmed => activeOrder?.status == FlashOrderStatus.confirmed;

  FlashOrderState copyWith({
    UserRole? userRole,
    Medication? selectedMedication,
    String? selectedQuarter,
    int? quantity,
    FlashOrder? activeOrder,
    bool clearActiveOrder = false,
    int? activePharmacistIndex,
    String? errorMessage,
  }) {
    return FlashOrderState(
      userRole: userRole ?? this.userRole,
      selectedMedication: selectedMedication ?? this.selectedMedication,
      selectedQuarter: selectedQuarter ?? this.selectedQuarter,
      quantity: quantity ?? this.quantity,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      activePharmacistIndex: activePharmacistIndex ?? this.activePharmacistIndex,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        userRole,
        selectedMedication,
        selectedQuarter,
        quantity,
        activeOrder,
        activePharmacistIndex,
        errorMessage,
      ];
}
