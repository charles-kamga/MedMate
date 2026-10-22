import 'package:equatable/equatable.dart';

sealed class PharmacySearchEvent extends Equatable {
  const PharmacySearchEvent();

  @override
  List<Object?> get props => [];
}

/// Déclenche la recherche des officines selon une position géographique ou un repère
final class SearchPharmaciesTriggered extends PharmacySearchEvent {
  const SearchPharmaciesTriggered({
    required this.latitude,
    required this.longitude,
    this.maxRadiusMeters = 3500,
  });

  final double latitude;
  final double longitude;
  final double maxRadiusMeters;

  @override
  List<Object?> get props => [latitude, longitude, maxRadiusMeters];
}

/// Déclenche la recherche textuelle dans le catalogue des médicaments
final class SearchMedicationsTriggered extends PharmacySearchEvent {
  const SearchMedicationsTriggered(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

/// Déclenche une demande de réservation temporaire
final class RequestReservationTriggered extends PharmacySearchEvent {
  const RequestReservationTriggered({
    required this.pharmacyId,
    required this.medicationId,
    required this.patientPhone,
    required this.quantite,
  });

  final String pharmacyId;
  final String medicationId;
  final String patientPhone;
  final int quantite;

  @override
  List<Object?> get props => [pharmacyId, medicationId, patientPhone, quantite];
}
