import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../flash_order/domain/entities/basket_item.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../../realtime_dispatch/domain/repositories/realtime_dispatch_repository.dart';
import '../../domain/repositories/reservation_repository.dart';
import '../../domain/usecases/escalate_dispatch_wave.dart';
import '../../domain/usecases/select_pharmacy_offer.dart';
import '../../domain/usecases/submit_flash_request.dart';
import 'flash_reservation_state.dart';

/// Contrôleur BLoC/Cubit gérant le parcours de réservation flash inversée
class FlashReservationCubit extends Cubit<FlashReservationState> {
  FlashReservationCubit({
    required SubmitFlashRequestUseCase submitFlashRequestUseCase,
    required EscalateDispatchWaveUseCase escalateDispatchWaveUseCase,
    required SelectPharmacyOfferUseCase selectPharmacyOfferUseCase,
    required ReservationRepository reservationRepository,
    RealtimeDispatchRepository? realtimeRepository,
    bool enableAutoEscalation = false,
    Duration autoEscalationDuration = const Duration(seconds: 120),
  })  : _submitFlashRequestUseCase = submitFlashRequestUseCase,
        _escalateDispatchWaveUseCase = escalateDispatchWaveUseCase,
        _selectPharmacyOfferUseCase = selectPharmacyOfferUseCase,
        _reservationRepository = reservationRepository,
        _realtimeRepository = realtimeRepository ??
            (reservationRepository is RealtimeDispatchRepository
                ? reservationRepository
                : null),
        _enableAutoEscalation = enableAutoEscalation,
        _autoEscalationDuration = autoEscalationDuration,
        super(const FlashReservationState());

  final SubmitFlashRequestUseCase _submitFlashRequestUseCase;
  final EscalateDispatchWaveUseCase _escalateDispatchWaveUseCase;
  final SelectPharmacyOfferUseCase _selectPharmacyOfferUseCase;
  final ReservationRepository _reservationRepository;
  final RealtimeDispatchRepository? _realtimeRepository;
  final bool _enableAutoEscalation;
  final Duration _autoEscalationDuration;

  StreamSubscription<List<PharmacyOffer>>? _offersSubscription;
  StreamSubscription<FlashOrder>? _orderSubscription;
  Timer? _escalationTimer;

  /// Ajoute un médicament au panier ou incrémente sa quantité s'il est déjà présent
  void addItem(
    Medication medication, {
    int quantity = 1,
    String? note,
  }) {
    if (quantity <= 0) return;

    final existingIndex =
        state.basketItems.indexWhere((i) => i.medication.id == medication.id);

    if (existingIndex >= 0) {
      final existingItem = state.basketItems[existingIndex];
      final updatedList = List<BasketItem>.from(state.basketItems);
      updatedList[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
        prescriptionNote: note ?? existingItem.prescriptionNote,
      );
      emit(state.copyWith(basketItems: updatedList));
    } else {
      final newItem = BasketItem(
        id: 'item-${medication.id}-${DateTime.now().millisecondsSinceEpoch}',
        medication: medication,
        quantity: quantity,
        hasPrescription: medication.necessiteOrdonnance,
        prescriptionNote: note,
      );
      emit(state.copyWith(basketItems: [...state.basketItems, newItem]));
    }
  }

  /// Supprime un article du panier par son identifiant unique
  void removeItem(String itemId) {
    final updatedList = state.basketItems.where((i) => i.id != itemId).toList();
    emit(state.copyWith(basketItems: updatedList));
  }

  /// Met à jour la quantité d'un article (supprime l'article si quantité <= 0)
  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedList = state.basketItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    emit(state.copyWith(basketItems: updatedList));
  }

  /// Met à jour la note ou précision liée à un article du panier
  void updateNote(String itemId, String? note) {
    final updatedList = state.basketItems.map((item) {
      if (item.id == itemId) {
        return item.copyWith(prescriptionNote: note);
      }
      return item;
    }).toList();

    emit(state.copyWith(basketItems: updatedList));
  }

  /// Sélectionne le repère urbain (carrefour ou quartier) de Yaoundé
  void selectLandmark(YaoundeLandmark landmark) {
    emit(state.copyWith(selectedLandmark: landmark));
  }

  /// Soumet la demande de recherche flash sans choisir de pharmacie d'avance
  Future<void> submitFlashRequest() async {
    if (state.basketItems.isEmpty) {
      emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage: 'Le panier de médicaments est vide.',
      ),);
      return;
    }

    final landmark = state.selectedLandmark;
    if (landmark == null) {
      emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage:
            'Veuillez sélectionner un repère urbain (carrefour ou quartier).',
      ),);
      return;
    }

    emit(state.copyWith(
      status: FlashReservationStatus.loading,
      clearError: true,
    ),);

    final result = await _submitFlashRequestUseCase(
      items: state.basketItems,
      landmark: landmark,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage: failure.message,
      ),),
      (order) {
        final status = order.offers.isNotEmpty
            ? FlashReservationStatus.offersReceived
            : FlashReservationStatus.waveActive;
        emit(state.copyWith(
          status: status,
          currentOrder: order,
          clearError: true,
        ),);
        _subscribeToRealtimeOrder(order.id);
        _startAutoEscalationTimer();
      },
    );
  }

  /// Escalade vers la vague suivante de 2 pharmacies partenaires
  Future<void> escalateWave() async {
    final currentOrder = state.currentOrder;
    if (currentOrder == null) {
      emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage: 'Aucune recherche active à escalader.',
      ),);
      return;
    }

    emit(state.copyWith(
      status: FlashReservationStatus.loading,
      clearError: true,
    ),);

    final result = await _escalateDispatchWaveUseCase(currentOrder.id);

    result.fold(
      (failure) => emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage: failure.message,
      ),),
      (updatedOrder) {
        final status = updatedOrder.offers.isNotEmpty
            ? FlashReservationStatus.offersReceived
            : FlashReservationStatus.waveActive;
        emit(state.copyWith(
          status: status,
          currentOrder: updatedOrder,
          clearError: true,
        ),);
        _startAutoEscalationTimer();
      },
    );
  }

  /// Sélectionne une offre émise par une officine et confirme la réservation
  Future<void> selectOffer(
    PharmacyOffer offer, {
    required String patientPhone,
  }) async {
    final currentOrder = state.currentOrder;
    if (currentOrder == null) {
      emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage: 'Aucune demande active sélectionnée.',
      ),);
      return;
    }

    emit(state.copyWith(
      status: FlashReservationStatus.loading,
      clearError: true,
    ),);

    final result = await _selectPharmacyOfferUseCase(
      orderId: currentOrder.id,
      offer: offer,
      patientPhone: patientPhone,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage: failure.message,
      ),),
      (reservation) {
        _escalationTimer?.cancel();
        emit(state.copyWith(
          status: FlashReservationStatus.reservationConfirmed,
          confirmedReservation: reservation,
          currentOrder: currentOrder.copyWith(selectedOffer: offer),
          clearError: true,
        ),);
      },
    );
  }

  /// Rafraîchit l'état courant de la demande depuis le repository
  Future<void> refreshFlashRequest([String? orderId]) async {
    final targetId = orderId ?? state.currentOrder?.id;
    if (targetId == null) return;

    final result = await _reservationRepository.getFlashRequestById(targetId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: FlashReservationStatus.failure,
        errorMessage: failure.message,
      ),),
      (refreshedOrder) {
        final status = refreshedOrder.offers.isNotEmpty
            ? FlashReservationStatus.offersReceived
            : (state.status == FlashReservationStatus.initial
                ? FlashReservationStatus.waveActive
                : state.status);
        emit(state.copyWith(
          currentOrder: refreshedOrder,
          status: status,
          clearError: true,
        ),);
        _subscribeToRealtimeOrder(refreshedOrder.id);
      },
    );
  }

  void _subscribeToRealtimeOrder(String orderId) {
    if (_realtimeRepository == null) return;

    _offersSubscription?.cancel();
    _offersSubscription = _realtimeRepository.watchOffersForOrder(orderId).listen(
      (offers) {
        if (isClosed) return;
        final currentOrder = state.currentOrder;
        if (currentOrder != null && currentOrder.id == orderId) {
          final updatedOrder = currentOrder.copyWith(offers: offers);
          final status = offers.isNotEmpty &&
                  state.status != FlashReservationStatus.reservationConfirmed
              ? FlashReservationStatus.offersReceived
              : state.status;
          emit(state.copyWith(
            currentOrder: updatedOrder,
            status: status,
            clearError: true,
          ),);
        }
      },
    );

    _orderSubscription?.cancel();
    _orderSubscription = _realtimeRepository.watchFlashOrder(orderId).listen(
      (orderUpdate) {
        if (isClosed) return;
        String? notification;
        if (orderUpdate.status == FlashOrderStatus.readyForPickup) {
          notification = 'Votre réservation est validée et prête à être retirée !';
        } else if (orderUpdate.status == FlashOrderStatus.delivered ||
            orderUpdate.isPickedUp) {
          notification = "Commande délivrée et clôturée par l'officine.";
        }

        final status = orderUpdate.offers.isNotEmpty &&
                state.status != FlashReservationStatus.reservationConfirmed
            ? FlashReservationStatus.offersReceived
            : (state.status == FlashReservationStatus.initial
                ? FlashReservationStatus.waveActive
                : state.status);

        emit(state.copyWith(
          currentOrder: orderUpdate,
          status: status,
          realtimeNotification: notification,
        ),);
      },
    );
  }

  void _startAutoEscalationTimer() {
    _escalationTimer?.cancel();
    if (!_enableAutoEscalation) return;

    _escalationTimer = Timer(_autoEscalationDuration, () async {
      if (isClosed) return;
      final currentOrder = state.currentOrder;
      if (currentOrder != null && currentOrder.selectedOffer == null) {
        await escalateWave();
      }
    });
  }

  /// Efface la notification temps réel courante
  void clearNotification() {
    emit(state.copyWith(clearNotification: true));
  }

  /// Réinitialise l'ensemble du flux de réservation
  void reset() {
    _offersSubscription?.cancel();
    _orderSubscription?.cancel();
    _escalationTimer?.cancel();
    emit(const FlashReservationState());
  }

  @override
  Future<void> close() {
    _offersSubscription?.cancel();
    _orderSubscription?.cancel();
    _escalationTimer?.cancel();
    return super.close();
  }
}
