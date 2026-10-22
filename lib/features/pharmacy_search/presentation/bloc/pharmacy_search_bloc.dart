import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/usecases/request_reservation.dart';
import '../../domain/usecases/search_medications.dart';
import '../../domain/usecases/search_pharmacies.dart';
import 'pharmacy_search_event.dart';
import 'pharmacy_search_state.dart';

class PharmacySearchBloc extends Bloc<PharmacySearchEvent, PharmacySearchState> {
  PharmacySearchBloc({
    required this.searchPharmaciesUseCase,
    required this.searchMedicationsUseCase,
    required this.requestReservationUseCase,
    this.uuid = const Uuid(),
  }) : super(const PharmacySearchInitial()) {
    on<SearchPharmaciesTriggered>(_onSearchPharmacies);
    on<SearchMedicationsTriggered>(_onSearchMedications);
    on<RequestReservationTriggered>(_onRequestReservation);
  }

  final SearchPharmaciesUseCase searchPharmaciesUseCase;
  final SearchMedicationsUseCase searchMedicationsUseCase;
  final RequestReservationUseCase requestReservationUseCase;
  final Uuid uuid;

  Future<void> _onSearchPharmacies(
    SearchPharmaciesTriggered event,
    Emitter<PharmacySearchState> emit,
  ) async {
    emit(const PharmacySearchLoading());
    final result = await searchPharmaciesUseCase(
      SearchPharmaciesParams(
        latitude: event.latitude,
        longitude: event.longitude,
        maxRadiusMeters: event.maxRadiusMeters,
      ),
    );

    result.fold(
      (failure) => emit(PharmacySearchError(failure.message, code: failure.code)),
      (pharmacies) => emit(PharmaciesLoaded(pharmacies)),
    );
  }

  Future<void> _onSearchMedications(
    SearchMedicationsTriggered event,
    Emitter<PharmacySearchState> emit,
  ) async {
    emit(const PharmacySearchLoading());
    final result = await searchMedicationsUseCase(event.query);

    result.fold(
      (failure) => emit(PharmacySearchError(failure.message, code: failure.code)),
      (medications) => emit(MedicationsLoaded(medications)),
    );
  }

  Future<void> _onRequestReservation(
    RequestReservationTriggered event,
    Emitter<PharmacySearchState> emit,
  ) async {
    emit(const PharmacySearchLoading());
    final clientReservationId = uuid.v4();

    final result = await requestReservationUseCase(
      RequestReservationParams(
        clientReservationId: clientReservationId,
        pharmacyId: event.pharmacyId,
        medicationId: event.medicationId,
        patientPhone: event.patientPhone,
        quantite: event.quantite,
      ),
    );

    result.fold(
      (failure) => emit(PharmacySearchError(failure.message, code: failure.code)),
      (reservation) => emit(ReservationSuccess(reservation)),
    );
  }
}
