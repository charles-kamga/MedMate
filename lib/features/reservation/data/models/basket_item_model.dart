import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';

/// Modèle DTO pour un élément du panier de demande flash patient.
///
/// INVARIANT INVIOLABLE (Afya Santé / Déontologie ONPC):
/// Zéro prix affiché dans le panier côté patient.
class BasketItemModel extends BasketItem {
  const BasketItemModel({
    required super.medication,
    required super.quantite,
    super.precision,
  });

  /// Désérialise un élément de panier depuis un dictionnaire JSON.
  factory BasketItemModel.fromJson(Map<String, dynamic> json) {
    final medJson = json['medication'] as Map<String, dynamic>;
    final medication = Medication(
      id: (medJson['id'] ?? medJson['medication_id']) as String,
      codeNational:
          (medJson['code_national'] ?? medJson['codeNational'] ?? '')
              as String,
      nomCommercial:
          (medJson['nom_commercial'] ?? medJson['nomCommercial'] ?? '')
              as String,
      dci: (medJson['dci'] ?? '') as String,
      forme: (medJson['forme'] ?? '') as String,
      dosage: (medJson['dosage'] ?? '') as String,
      necessiteOrdonnance:
          (medJson['necessite_ordonnance'] ??
                  medJson['necessiteOrdonnance'] ??
                  false)
              as bool,
    );

    final rawQuantite = json['quantite'] ?? json['quantity'] ?? 1;
    final quantite = (rawQuantite is num) ? rawQuantite.toInt() : 1;

    return BasketItemModel(
      medication: medication,
      quantite: quantite,
      precision: json['precision'] as String?,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory BasketItemModel.fromDomain(BasketItem item) {
    return BasketItemModel(
      medication: item.medication,
      quantite: item.quantite,
      precision: item.precision,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'medication': {
        'id': medication.id,
        'code_national': medication.codeNational,
        'nom_commercial': medication.nomCommercial,
        'dci': medication.dci,
        'forme': medication.forme,
        'dosage': medication.dosage,
        'necessite_ordonnance': medication.necessiteOrdonnance,
      },
      'quantite': quantite,
      'precision': precision,
    };
  }

  /// Convertit le modèle en entité de domaine.
  BasketItem toDomain() => this;
}
