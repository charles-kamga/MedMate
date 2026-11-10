import 'package:equatable/equatable.dart';

/// Entité immuable représentant un médicament dans le référentiel national.
///
/// INVARIANT INVIOLABLE (Afya Santé / Déontologie ONPC):
/// Aucun champ de prix (`prix`, `price`, `cout`, `tarif`) n'est présent dans
/// cette entité catalogue. Le prix et la disponibilité finale sont
/// exclusivement déterminés et transmis au comptoir par le pharmacien d'officine.
class Medication extends Equatable {
  const Medication({
    required this.id,
    required this.codeNational,
    required this.nomCommercial,
    required this.dci,
    required this.forme,
    required this.dosage,
    required this.necessiteOrdonnance,
  });

  /// Identifiant unique (UUID ou identifiant CIP national).
  final String id;

  /// Code national d'identification du médicament (CIP / CIS).
  final String codeNational;

  /// Nom commercial ou marque (ex: "Paracétamol Biogaran", "Efferalgan").
  final String nomCommercial;

  /// Dénomination Commune Internationale (ex: "Paracétamol", "Amoxicilline").
  final String dci;

  /// Forme galénique (ex: "Comprimé effervescent", "Sirop", "Gélule").
  final String forme;

  /// Dosage unitaire (ex: "500 mg", "1 g", "125 mg/5 ml").
  final String dosage;

  /// Indique si la délivrance requiert une ordonnance médicale valide.
  final bool necessiteOrdonnance;

  /// Crée une copie immuable de l'entité avec des champs modifiés.
  Medication copyWith({
    String? id,
    String? codeNational,
    String? nomCommercial,
    String? dci,
    String? forme,
    String? dosage,
    bool? necessiteOrdonnance,
  }) {
    return Medication(
      id: id ?? this.id,
      codeNational: codeNational ?? this.codeNational,
      nomCommercial: nomCommercial ?? this.nomCommercial,
      dci: dci ?? this.dci,
      forme: forme ?? this.forme,
      dosage: dosage ?? this.dosage,
      necessiteOrdonnance: necessiteOrdonnance ?? this.necessiteOrdonnance,
    );
  }

  @override
  List<Object?> get props => [
        id,
        codeNational,
        nomCommercial,
        dci,
        forme,
        dosage,
        necessiteOrdonnance,
      ];
}
