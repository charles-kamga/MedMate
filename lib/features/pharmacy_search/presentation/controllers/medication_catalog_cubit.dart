import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/search_medications.dart';
import 'medication_catalog_state.dart';

/// Contrôleur BLoC/Cubit gérant la recherche réactive dans le catalogue homologué
class MedicationCatalogCubit extends Cubit<MedicationCatalogState> {
  MedicationCatalogCubit({
    required SearchMedicationsUseCase searchMedicationsUseCase,
  })  : _searchMedicationsUseCase = searchMedicationsUseCase,
        super(const MedicationCatalogInitial());

  final SearchMedicationsUseCase _searchMedicationsUseCase;

  /// Lance une recherche réactive sur la base de la requête utilisateur
  Future<void> search(String query) async {
    final sanitizedQuery = query.trim();
    if (sanitizedQuery.isEmpty) {
      emit(const MedicationCatalogInitial());
      return;
    }

    emit(const MedicationCatalogLoading());

    final result = await _searchMedicationsUseCase(sanitizedQuery);

    result.fold(
      (failure) => emit(MedicationCatalogError(failure.message)),
      (medications) => emit(MedicationCatalogLoaded(medications)),
    );
  }

  /// Réinitialise l'état du catalogue
  void clear() {
    emit(const MedicationCatalogInitial());
  }
}
