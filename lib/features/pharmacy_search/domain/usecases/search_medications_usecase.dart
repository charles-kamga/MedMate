import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_search_repository.dart';

/// Paramètres de recherche de médicaments.
class SearchMedicationsParams extends Equatable {
  const SearchMedicationsParams({required this.query});

  /// Chaîne textuelle recherchée (nom commercial ou DCI).
  final String query;

  @override
  List<Object?> get props => [query];
}

/// Recherche de médicaments dans le référentiel avec tolérance aux fautes.
///
/// Si la requête saisie comporte moins de 2 caractères (après suppression des
/// espaces superflus), retourne immédiatement une liste vide sans solliciter
/// le réseau ni le serveur.
class SearchMedicationsUseCase {
  const SearchMedicationsUseCase(this._repository);

  final PharmacySearchRepository _repository;

  /// Exécute la recherche de médicaments avec validation préalable.
  Future<Either<Failure, List<Medication>>> call(
    SearchMedicationsParams params,
  ) async {
    final trimmedQuery = params.query.trim();
    if (trimmedQuery.length < 2) {
      return const Right(<Medication>[]);
    }

    return _repository.searchMedications(trimmedQuery);
  }
}
