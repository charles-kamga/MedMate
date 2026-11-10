import 'package:equatable/equatable.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../flash_order/domain/entities/basket_item.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../pharmacy_search/domain/entities/reservation.dart';

/// Statut de la machine d'état du parcours de réservation flash
enum FlashReservationStatus {
  initial,
  loading,
  waveActive,
  offersReceived,
  reservationConfirmed,
  failure,
}

/// État global du contrôleur de réservation flash
class FlashReservationState extends Equatable {
  const FlashReservationState({
    this.basketItems = const [],
    this.selectedLandmark,
    this.currentOrder,
    this.status = FlashReservationStatus.initial,
    this.errorMessage,
    this.confirmedReservation,
  });

  final List<BasketItem> basketItems;
  final YaoundeLandmark? selectedLandmark;
  final FlashOrder? currentOrder;
  final FlashReservationStatus status;
  final String? errorMessage;
  final Reservation? confirmedReservation;

  /// Getters utilitaires pour l'UI
  bool get isLoading => status == FlashReservationStatus.loading;
  bool get isWaveActive => status == FlashReservationStatus.waveActive;
  bool get hasOffers =>
      status == FlashReservationStatus.offersReceived ||
      (currentOrder != null && currentOrder!.offers.isNotEmpty);
  bool get isConfirmed => status == FlashReservationStatus.reservationConfirmed;
  bool get isFailure => status == FlashReservationStatus.failure;
  bool get hasItems => basketItems.isNotEmpty;
  int get totalItemCount =>
      basketItems.fold<int>(0, (sum, item) => sum + item.quantity);
  bool get canSubmit => basketItems.isNotEmpty && selectedLandmark != null;
  bool get hasActiveOrder => currentOrder != null;

  FlashReservationState copyWith({
    List<BasketItem>? basketItems,
    YaoundeLandmark? selectedLandmark,
    FlashOrder? currentOrder,
    FlashReservationStatus? status,
    String? errorMessage,
    bool clearError = false,
    Reservation? confirmedReservation,
    bool clearReservation = false,
  }) {
    return FlashReservationState(
      basketItems: basketItems ?? this.basketItems,
      selectedLandmark: selectedLandmark ?? this.selectedLandmark,
      currentOrder: currentOrder ?? this.currentOrder,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      confirmedReservation: clearReservation
          ? null
          : (confirmedReservation ?? this.confirmedReservation),
    );
  }

  @override
  List<Object?> get props => [
        basketItems,
        selectedLandmark,
        currentOrder,
        status,
        errorMessage,
        confirmedReservation,
      ];
}
