import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';
import '../../../realtime_dispatch/domain/repositories/realtime_dispatch_repository.dart';
import '../../domain/usecases/get_pending_counter_orders.dart';
import '../../domain/usecases/submit_counter_quote.dart';
import '../../domain/usecases/validate_counter_otp.dart';
import 'pharmacist_counter_state.dart';

/// Contrôleur BLoC/Cubit pour le portail comptoir officine
class PharmacistCounterCubit extends Cubit<PharmacistCounterState> {
  PharmacistCounterCubit({
    required GetPendingCounterOrdersUseCase getPendingOrders,
    required SubmitCounterQuoteUseCase submitQuoteUseCase,
    required ValidateCounterOtpUseCase validateOtpUseCase,
    RealtimeDispatchRepository? realtimeRepository,
    bool enableAutoRefresh = false,
    Duration autoRefreshInterval = const Duration(seconds: 30),
  })  : _getPendingOrders = getPendingOrders,
        _submitQuoteUseCase = submitQuoteUseCase,
        _validateOtpUseCase = validateOtpUseCase,
        _realtimeRepository = realtimeRepository,
        _enableAutoRefresh = enableAutoRefresh,
        _autoRefreshInterval = autoRefreshInterval,
        super(const PharmacistCounterState());

  final GetPendingCounterOrdersUseCase _getPendingOrders;
  final SubmitCounterQuoteUseCase _submitQuoteUseCase;
  final ValidateCounterOtpUseCase _validateOtpUseCase;
  final RealtimeDispatchRepository? _realtimeRepository;
  final bool _enableAutoRefresh;
  final Duration _autoRefreshInterval;

  Timer? _refreshTimer;
  Timer? _countdownTimer;
  StreamSubscription<List<FlashOrder>>? _ordersSubscription;
  String? _activePharmacyId;

  /// Charge la liste des demandes de réservation pour l'officine
  Future<void> loadPendingOrders(String pharmacyId) async {
    _activePharmacyId = pharmacyId;
    emit(state.copyWith(
      status: PharmacistCounterStatus.loading,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _getPendingOrders(pharmacyId);
    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PharmacistCounterStatus.failure,
          errorMessage: failure.message,
          failure: failure,
        ),);
      },
      (orders) {
        FlashOrder? updatedSelected;
        int? remainingSeconds;

        if (state.selectedOrder != null) {
          final found = orders
              .where((o) => o.id == state.selectedOrder!.id)
              .firstOrNull;
          updatedSelected = found ?? state.selectedOrder;
          remainingSeconds = updatedSelected?.waveTimeRemainingSeconds;
        }

        emit(state.copyWith(
          status: PharmacistCounterStatus.loaded,
          orders: orders,
          selectedOrder: updatedSelected,
          selectedOrderWaveRemainingSeconds: remainingSeconds,
        ),);

        _setupAutoRefreshIfNeeded();
        _subscribeToRealtimeOrders(pharmacyId);
      },
    );
  }

  /// Sélectionne une commande pour afficher son détail au comptoir
  void selectOrder(FlashOrder? order) {
    _countdownTimer?.cancel();
    if (order == null) {
      emit(state.copyWith(
        clearSelectedOrder: true,
        clearWaveRemaining: true,
      ),);
      return;
    }

    final remaining = order.waveTimeRemainingSeconds;
    emit(state.copyWith(
      selectedOrder: order,
      selectedOrderWaveRemainingSeconds: remaining,
    ),);

    if (_enableAutoRefresh && remaining > 0) {
      _startCountdownTimer();
    }
  }

  /// Décrémente manuellement ou par simulation le temps restant de vague
  void tickCountdown([int seconds = 1]) {
    final current = state.selectedOrderWaveRemainingSeconds;
    if (current == null || current <= 0) return;
    final next = (current - seconds) < 0 ? 0 : (current - seconds);
    emit(state.copyWith(selectedOrderWaveRemainingSeconds: next));
  }

  /// Émet une proposition de devis officine pour la demande courante
  Future<void> submitQuote({
    required String orderId,
    required String pharmacyId,
    required PharmacyAvailabilityType availability,
    required int quotedPriceCfa,
    List<String> conditionRequirements = const [],
    String? conditionNote,
    bool proposesDelivery = false,
    int deliveryFeeCfa = 0,
    int? estimatedDeliveryMinutes,
  }) async {
    emit(state.copyWith(
      status: PharmacistCounterStatus.submittingQuote,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _submitQuoteUseCase(
      orderId: orderId,
      pharmacyId: pharmacyId,
      availability: availability,
      quotedPriceCfa: quotedPriceCfa,
      conditionRequirements: conditionRequirements,
      conditionNote: conditionNote,
      proposesDelivery: proposesDelivery,
      deliveryFeeCfa: deliveryFeeCfa,
      estimatedDeliveryMinutes: estimatedDeliveryMinutes,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PharmacistCounterStatus.failure,
          errorMessage: failure.message,
          failure: failure,
        ),);
      },
      (offer) {
        final updatedOrders = state.orders.map((order) {
          if (order.id == orderId) {
            final offers = List<PharmacyOffer>.from(
              order.offers.where((o) => o.pharmacyId != pharmacyId),
            )..add(offer);
            return order.copyWith(offers: offers);
          }
          return order;
        }).toList();

        final updatedSelected = state.selectedOrder?.id == orderId
            ? updatedOrders.firstWhere((o) => o.id == orderId)
            : state.selectedOrder;

        emit(state.copyWith(
          status: PharmacistCounterStatus.quoteSubmitted,
          orders: updatedOrders,
          selectedOrder: updatedSelected,
          lastSubmittedQuote: offer,
          successMessage: 'Devis soumis au patient avec succès.',
        ),);
      },
    );
  }

  /// Valide le code OTP à 6 chiffres présenté par le client
  Future<void> validateOtpAtCounter({
    required String orderId,
    required String pharmacyId,
    required String otpCode,
  }) async {
    emit(state.copyWith(
      status: PharmacistCounterStatus.validatingOtp,
      clearError: true,
      clearSuccess: true,
    ),);

    final result = await _validateOtpUseCase(
      orderId: orderId,
      pharmacyId: pharmacyId,
      otpCode: otpCode,
    );

    result.fold(
      (failure) {
        emit(state.copyWith(
          status: PharmacistCounterStatus.failure,
          errorMessage: failure.message,
          failure: failure,
        ),);
      },
      (deliveredOrder) {
        final updatedOrders = state.orders.map((order) {
          return order.id == orderId ? deliveredOrder : order;
        }).toList();

        emit(state.copyWith(
          status: PharmacistCounterStatus.otpSuccess,
          orders: updatedOrders,
          selectedOrder: deliveredOrder,
          lastValidatedOrder: deliveredOrder,
          successMessage: 'Code OTP validé. Médicaments remis au patient.',
        ),);
      },
    );
  }

  /// Filtre les commandes par statut
  void setFilterStatus(String? filter) {
    emit(state.copyWith(
      filterStatus: filter,
      clearFilter: filter == null || filter.isEmpty,
    ),);
  }

  /// Réinitialise les messages de retour utilisateur et repasse en mode chargé
  void clearFeedback() {
    final nextStatus = (state.status == PharmacistCounterStatus.failure ||
            state.status == PharmacistCounterStatus.quoteSubmitted ||
            state.status == PharmacistCounterStatus.otpSuccess)
        ? PharmacistCounterStatus.loaded
        : state.status;

    emit(state.copyWith(
      status: nextStatus,
      clearError: true,
      clearSuccess: true,
    ),);
  }

  /// Efface le signalement discret de nouvelle commande reçue
  void clearNewOrderAlert() {
    emit(state.copyWith(
      hasNewOrderAlert: false,
      newOrdersCount: 0,
    ),);
  }

  void _subscribeToRealtimeOrders(String pharmacyId) {
    if (_realtimeRepository == null) return;

    _ordersSubscription?.cancel();
    _ordersSubscription = _realtimeRepository
        .watchPendingOrdersForPharmacy(pharmacyId)
        .listen((incomingOrders) {
      if (isClosed) return;
      _handleRealtimeOrdersUpdate(pharmacyId, incomingOrders);
    });
  }

  void _handleRealtimeOrdersUpdate(
    String pharmacyId,
    List<FlashOrder> incomingOrders,
  ) {
    final validOrders = incomingOrders.where((order) {
      if (order.selectedOffer != null &&
          order.selectedOffer!.pharmacyId != pharmacyId) {
        return false;
      }
      if (order.status != FlashOrderStatus.dispatchingWave &&
          order.selectedOffer?.pharmacyId != pharmacyId) {
        return false;
      }
      return true;
    }).toList();

    final existingIds = state.orders.map((o) => o.id).toSet();
    final newCount =
        validOrders.where((o) => !existingIds.contains(o.id)).length;
    final hasNew = newCount > 0;

    FlashOrder? updatedSelected;
    int? remainingSeconds;
    var clearSelected = false;

    if (state.selectedOrder != null) {
      final selectedId = state.selectedOrder!.id;
      final found = validOrders.where((o) => o.id == selectedId).firstOrNull;
      if (found == null) {
        _countdownTimer?.cancel();
        clearSelected = true;
      } else {
        updatedSelected = found;
        remainingSeconds = found.waveTimeRemainingSeconds;
      }
    }

    emit(state.copyWith(
      status: PharmacistCounterStatus.loaded,
      orders: validOrders,
      selectedOrder: updatedSelected,
      clearSelectedOrder: clearSelected,
      selectedOrderWaveRemainingSeconds: remainingSeconds,
      clearWaveRemaining: clearSelected,
      hasNewOrderAlert: hasNew || state.hasNewOrderAlert,
      newOrdersCount: state.newOrdersCount + newCount,
    ),);
  }

  void _setupAutoRefreshIfNeeded() {
    if (!_enableAutoRefresh || _refreshTimer != null) return;
    _refreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (_activePharmacyId != null) {
        _silentRefresh(_activePharmacyId!);
      }
    });
  }

  Future<void> _silentRefresh(String pharmacyId) async {
    final result = await _getPendingOrders(pharmacyId);
    result.fold(
      (_) => null,
      (orders) {
        if (!isClosed) {
          emit(state.copyWith(orders: orders));
        }
      },
    );
  }

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.selectedOrderWaveRemainingSeconds;
      if (current == null || current <= 0) {
        timer.cancel();
        return;
      }
      if (!isClosed) {
        emit(state.copyWith(selectedOrderWaveRemainingSeconds: current - 1));
      }
    });
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    return super.close();
  }
}
