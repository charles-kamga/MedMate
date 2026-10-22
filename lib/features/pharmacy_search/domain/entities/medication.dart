import 'package:equatable/equatable.dart';

/// Entité métier représentant un médicament homologué au Cameroun
class Medication extends Equatable {
  const Medication({
    required this.id,
    required this.dci,
    required this.nomCommercial,
    required this.forme,
    required this.dosage,
    required this.classeTherapeutique,
    required this.prixHomologueCfa,
    required this.necessiteOrdonnance,
  });

  final String id;
  final String dci;
  final String nomCommercial;
  final String forme;
  final String dosage;
  final String classeTherapeutique;
  final int prixHomologueCfa;
  final bool necessiteOrdonnance;

  @override
  List<Object?> get props => [
        id,
        dci,
        nomCommercial,
        forme,
        dosage,
        classeTherapeutique,
        prixHomologueCfa,
        necessiteOrdonnance,
      ];
}
