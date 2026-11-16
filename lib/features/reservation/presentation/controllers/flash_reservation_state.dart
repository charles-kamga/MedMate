import 'package:equatable/equatable.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../flash_order/domain/entities/basket_item.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
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
    this.realtimeNotification,
  });

  final List<BasketItem> basketItems;
  final YaoundeLandmark? selectedLandmark;
  final FlashOrder? currentOrder;
  final FlashReservationStatus status;
  final String? errorMessage;
  final Reservation? confirmedReservation;
  final String? realtimeNotification;

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
  bool get hasRealtimeNotification =>
      realtimeNotification != null && realtimeNotification!.isNotEmpty;

  /// Retourne un nouvel état avec le médicament ajouté ou incrémenté
  FlashReservationState withAddedItem(
    Medication medication, {
    int quantity = 1,
    String? note,
  }) {
    final existingIndex =
        basketItems.indexWhere((i) => i.medication.id == medication.id);
    if (existingIndex >= 0) {
      final existingItem = basketItems[existingIndex];
      final updatedList = List<BasketItem>.from(basketItems);
      updatedList[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
        prescriptionNote: note ?? existingItem.prescriptionNote,
      );
      return copyWith(basketItems: updatedList);
    }
    final newItem = BasketItem(
      id: 'item-${medication.id}-${DateTime.now().millisecondsSinceEpoch}',
      medication: medication,
      quantity: quantity,
      hasPrescription: medication.necessiteOrdonnance,
      prescriptionNote: note,
    );
    return copyWith(basketItems: [...basketItems, newItem]);
  }

  /// Retourne un nouvel état synchronisé avec une mise à jour temps réel de commande
  FlashReservationState withOrderRealtimeUpdate(FlashOrder orderUpdate) {
    String? notification;
    if (orderUpdate.status == FlashOrderStatus.readyForPickup) {
      notification = 'Votre réservation est validée et prête à être retirée !';
    } else if (orderUpdate.status == FlashOrderStatus.delivered ||
        orderUpdate.isPickedUp) {
      notification = "Commande délivrée et clôturée par l'officine.";
    }

    final resolvedStatus = orderUpdate.offers.isNotEmpty &&
            status != FlashReservationStatus.reservationConfirmed
        ? FlashReservationStatus.offersReceived
        : (status == FlashReservationStatus.initial
            ? FlashReservationStatus.waveActive
            : status);

    return copyWith(
      currentOrder: orderUpdate,
      status: resolvedStatus,
      realtimeNotification: notification,
    );
  }

  FlashReservationState copyWith({
    List<BasketItem>? basketItems,
    YaoundeLandmark? selectedLandmark,
    FlashOrder? currentOrder,
    bool clearOrder = false,
    FlashReservationStatus? status,
    String? errorMessage,
    bool clearError = false,
    Reservation? confirmedReservation,
    bool clearReservation = false,
    String? realtimeNotification,
    bool clearNotification = false,
  }) {
    return FlashReservationState(
      basketItems: basketItems ?? this.basketItems,
      selectedLandmark: selectedLandmark ?? this.selectedLandmark,
      currentOrder: clearOrder ? null : (currentOrder ?? this.currentOrder),
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      confirmedReservation: clearReservation
          ? null
          : (confirmedReservation ?? this.confirmedReservation),
      realtimeNotification: clearNotification
          ? null
          : (realtimeNotification ?? this.realtimeNotification),
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
        realtimeNotification,
      ];
}
