import 'package:equatable/equatable.dart';
import '../../domain/entities/duty_pharmacy_item.dart';

/// État immuable du contrôleur des pharmacies de garde
class DutyPharmacyState extends Equatable {
  const DutyPharmacyState({
    this.cities = const ['Yaoundé', 'Douala', 'Bertoua', 'Bafoussam'],
    this.selectedCity = 'Yaoundé',
    this.activeSegment = 0,
    this.searchQuery = '',
    this.allCityPharmacies = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<String> cities;
  final String selectedCity;
  final int activeSegment; // 0 = Plus proches, 1 = Toutes les gardes
  final String searchQuery;
  final List<DutyPharmacyItem> allCityPharmacies;
  final bool isLoading;
  final String? errorMessage;

  /// Liste filtrée selon l'onglet actif et la recherche par quartier/nom
  List<DutyPharmacyItem> get displayedPharmacies {
    if (activeSegment == 0) {
      return allCityPharmacies.take(4).toList();
    }
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return allCityPharmacies;
    }
    return allCityPharmacies
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.quarter.toLowerCase().contains(q) ||
              p.activity.toLowerCase().contains(q),
        )
        .toList();
  }

  DutyPharmacyState copyWith({
    List<String>? cities,
    String? selectedCity,
    int? activeSegment,
    String? searchQuery,
    List<DutyPharmacyItem>? allCityPharmacies,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DutyPharmacyState(
      cities: cities ?? this.cities,
      selectedCity: selectedCity ?? this.selectedCity,
      activeSegment: activeSegment ?? this.activeSegment,
      searchQuery: searchQuery ?? this.searchQuery,
      allCityPharmacies: allCityPharmacies ?? this.allCityPharmacies,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        cities,
        selectedCity,
        activeSegment,
        searchQuery,
        allCityPharmacies,
        isLoading,
        errorMessage,
      ];
}
