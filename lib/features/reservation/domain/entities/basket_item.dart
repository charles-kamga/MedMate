import 'package:equatable/equatable.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';

/// Élément du panier de demande flash de disponibilité patient.
class BasketItem extends Equatable {
  const BasketItem({
    required this.medication,
    required this.quantite,
    this.precision,
  });

  /// Médicament recherché dans le panier.
  final Medication medication;

  /// Quantité unitaire demandée (doit être >= 1).
  final int quantite;

  /// Précision ou consigne facultative du patient (ex: "Générique accepté si disponible").
  final String? precision;

  /// Crée une copie immuable de l'élément de panier avec les modifications fournies.
  BasketItem copyWith({
    Medication? medication,
    int? quantite,
    String? precision,
  }) {
    return BasketItem(
      medication: medication ?? this.medication,
      quantite: quantite ?? this.quantite,
      precision: precision ?? this.precision,
    );
  }

  @override
  List<Object?> get props => [medication, quantite, precision];
}
