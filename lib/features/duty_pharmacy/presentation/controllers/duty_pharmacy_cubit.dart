import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/duty_pharmacy_repository_impl.dart';
import '../../domain/repositories/duty_pharmacy_repository.dart';
import '../../domain/usecases/get_duty_pharmacies.dart';
import 'duty_pharmacy_state.dart';

/// Contrôleur Cubit gérant l'affichage et le filtrage des pharmacies de garde
class DutyPharmacyCubit extends Cubit<DutyPharmacyState> {
  DutyPharmacyCubit({
    DutyPharmacyRepository? repository,
    GetDutyPharmaciesUseCase? getDutyPharmaciesUseCase,
  })  : _repository = repository ?? const DutyPharmacyRepositoryImpl(),
        _getDutyPharmacies = getDutyPharmaciesUseCase ??
            GetDutyPharmaciesUseCase(
              repository ?? const DutyPharmacyRepositoryImpl(),
            ),
        super(
          DutyPharmacyState(
            cities: (repository ?? const DutyPharmacyRepositoryImpl())
                .getSupportedCities(),
            allCityPharmacies: DutyPharmacyRepositoryImpl.defaultDutyPharmacies
                .where((p) => p.city == 'Yaoundé')
                .toList(),
          ),
        );

  final DutyPharmacyRepository _repository;
  final GetDutyPharmaciesUseCase _getDutyPharmacies;

  /// Change la ville active et recharge les pharmacies de garde associées
  Future<void> selectCity(String city) async {
    emit(state.copyWith(selectedCity: city, isLoading: true));
    final result = await _getDutyPharmacies(city);
    result.fold(
      (failure) => emit(
        state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        ),
      ),
      (pharmacies) => emit(
        state.copyWith(
          cities: _repository.getSupportedCities(),
          allCityPharmacies: pharmacies,
          isLoading: false,
        ),
      ),
    );
  }

  /// Bascule entre « Plus proches » (0) et « Toutes les gardes » (1)
  void selectSegment(int segment) {
    emit(state.copyWith(activeSegment: segment));
  }

  /// Met à jour le filtre de recherche par quartier ou nom d'officine
  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
