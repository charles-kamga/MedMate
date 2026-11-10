import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';

/// Modèle DTO pour un médicament dans le catalogue d'Afya Santé.
///
/// INVARIANT INVIOLABLE (Afya Santé / ONPC) :
/// STRICTEMENT AUCUN CHAMP DE PRIX OU DE TARIF.
/// Le prix n'est ni modélisé ni stocké ici.
class MedicationModel extends Medication {
  const MedicationModel({
    required super.id,
    required super.codeNational,
    required super.nomCommercial,
    required super.dci,
    required super.forme,
    required super.dosage,
    required super.necessiteOrdonnance,
  });

  /// Désérialise un médicament depuis un dictionnaire JSON.
  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String,
      codeNational: json['code_national'] as String,
      nomCommercial: json['nom_commercial'] as String,
      dci: json['dci'] as String,
      forme: json['forme'] as String,
      dosage: json['dosage'] as String,
      necessiteOrdonnance: json['necessite_ordonnance'] as bool? ?? false,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory MedicationModel.fromDomain(Medication medication) {
    return MedicationModel(
      id: medication.id,
      codeNational: medication.codeNational,
      nomCommercial: medication.nomCommercial,
      dci: medication.dci,
      forme: medication.forme,
      dosage: medication.dosage,
      necessiteOrdonnance: medication.necessiteOrdonnance,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON (sans aucun champ prix).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code_national': codeNational,
      'nom_commercial': nomCommercial,
      'dci': dci,
      'forme': forme,
      'dosage': dosage,
      'necessite_ordonnance': necessiteOrdonnance,
    };
  }

  @override
  MedicationModel copyWith({
    String? id,
    String? codeNational,
    String? nomCommercial,
    String? dci,
    String? forme,
    String? dosage,
    bool? necessiteOrdonnance,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      codeNational: codeNational ?? this.codeNational,
      nomCommercial: nomCommercial ?? this.nomCommercial,
      dci: dci ?? this.dci,
      forme: forme ?? this.forme,
      dosage: dosage ?? this.dosage,
      necessiteOrdonnance: necessiteOrdonnance ?? this.necessiteOrdonnance,
    );
  }

  /// Convertit le modèle en entité du domaine.
  Medication toDomain() => this;
}
