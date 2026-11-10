import 'package:equatable/equatable.dart';
import '../../domain/entities/medication.dart';

/// Hiérarchie scellée pour les états du catalogue et de la recherche de médicaments
sealed class MedicationCatalogState extends Equatable {
  const MedicationCatalogState();

  List<Medication> get medications => const [];
  bool get isLoading => false;
  bool get isError => false;
  String? get errorMessage => null;

  @override
  List<Object?> get props => [];
}

/// État initial avant toute saisie
class MedicationCatalogInitial extends MedicationCatalogState {
  const MedicationCatalogInitial();
}

/// Recherche en cours
class MedicationCatalogLoading extends MedicationCatalogState {
  const MedicationCatalogLoading();

  @override
  bool get isLoading => true;
}

/// Résultats trouvés dans le référentiel homologué
class MedicationCatalogLoaded extends MedicationCatalogState {
  const MedicationCatalogLoaded(this.medications);

  @override
  final List<Medication> medications;

  @override
  List<Object?> get props => [medications];
}

/// Erreur survenue lors de la consultation du catalogue
class MedicationCatalogError extends MedicationCatalogState {
  const MedicationCatalogError(this.message);

  final String message;

  @override
  bool get isError => true;

  @override
  String? get errorMessage => message;

  @override
  List<Object?> get props => [message];
}
