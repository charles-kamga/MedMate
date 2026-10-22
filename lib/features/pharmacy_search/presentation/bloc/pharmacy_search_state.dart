import 'package:equatable/equatable.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/pharmacy.dart';
import '../../domain/entities/reservation.dart';

sealed class PharmacySearchState extends Equatable {
  const PharmacySearchState();

  @override
  List<Object?> get props => [];
}

/// État initial
final class PharmacySearchInitial extends PharmacySearchState {
  const PharmacySearchInitial();
}

/// Chargement en cours
final class PharmacySearchLoading extends PharmacySearchState {
  const PharmacySearchLoading();
}

/// Succès de la recherche des pharmacies de proximité
final class PharmaciesLoaded extends PharmacySearchState {
  const PharmaciesLoaded(this.pharmacies);

  final List<Pharmacy> pharmacies;

  @override
  List<Object?> get props => [pharmacies];
}

/// Succès de la recherche dans le catalogue des médicaments
final class MedicationsLoaded extends PharmacySearchState {
  const MedicationsLoaded(this.medications);

  final List<Medication> medications;

  @override
  List<Object?> get props => [medications];
}

/// Succès d'une réservation avec code de retrait
final class ReservationSuccess extends PharmacySearchState {
  const ReservationSuccess(this.reservation);

  final Reservation reservation;

  @override
  List<Object?> get props => [reservation];
}

/// État d'erreur avec message convivial et exploitable
final class PharmacySearchError extends PharmacySearchState {
  const PharmacySearchError(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
