import '../../domain/entities/medication.dart';

/// DTO pour la désérialisation typée des médicaments
class MedicationModel extends Medication {
  const MedicationModel({
    required super.id,
    required super.dci,
    required super.nomCommercial,
    required super.forme,
    required super.dosage,
    required super.classeTherapeutique,
    required super.prixHomologueCfa,
    required super.necessiteOrdonnance,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      id: json['id'] as String? ?? '',
      dci: json['dci'] as String? ?? '',
      nomCommercial: json['nom_commercial'] as String? ?? '',
      forme: json['forme'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      classeTherapeutique: json['classe_therapeutique'] as String? ?? '',
      prixHomologueCfa: json['prix_homologue_cfa'] as int? ?? 0,
      necessiteOrdonnance: json['necessite_ordonnance'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dci': dci,
      'nom_commercial': nomCommercial,
      'forme': forme,
      'dosage': dosage,
      'classe_therapeutique': classeTherapeutique,
      'prix_homologue_cfa': prixHomologueCfa,
      'necessite_ordonnance': necessiteOrdonnance,
    };
  }
}
