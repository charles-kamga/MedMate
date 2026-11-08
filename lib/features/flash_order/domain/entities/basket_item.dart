import 'package:equatable/equatable.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';

/// Article du panier intelligent multi-médicaments Afya Santé
class BasketItem extends Equatable {
  const BasketItem({
    required this.id,
    required this.medication,
    this.quantity = 1,
    this.hasPrescription = false,
    this.prescriptionNote,
  });

  final String id;
  final Medication medication;
  final int quantity;
  final bool hasPrescription;
  final String? prescriptionNote;

  BasketItem copyWith({
    String? id,
    Medication? medication,
    int? quantity,
    bool? hasPrescription,
    String? prescriptionNote,
  }) {
    return BasketItem(
      id: id ?? this.id,
      medication: medication ?? this.medication,
      quantity: quantity ?? this.quantity,
      hasPrescription: hasPrescription ?? this.hasPrescription,
      prescriptionNote: prescriptionNote ?? this.prescriptionNote,
    );
  }

  @override
  List<Object?> get props => [
        id,
        medication,
        quantity,
        hasPrescription,
        prescriptionNote,
      ];
}
