import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';

/// Statuts du cycle de vie du portail comptoir pharmacien
enum PharmacistCounterStatus {
  initial,
  loading,
  loaded,
  submittingQuote,
  quoteSubmitted,
  validatingOtp,
  otpSuccess,
  failure,
}

/// État immuable du comptoir pharmacien
class PharmacistCounterState extends Equatable {
  const PharmacistCounterState({
    this.status = PharmacistCounterStatus.initial,
    this.orders = const [],
    this.selectedOrder,
    this.filterStatus,
    this.selectedOrderWaveRemainingSeconds,
    this.errorMessage,
    this.failure,
    this.lastSubmittedQuote,
    this.lastValidatedOrder,
    this.successMessage,
  });

  final PharmacistCounterStatus status;
  final List<FlashOrder> orders;
  final FlashOrder? selectedOrder;
  final String? filterStatus;
  final int? selectedOrderWaveRemainingSeconds;
  final String? errorMessage;
  final Failure? failure;
  final PharmacyOffer? lastSubmittedQuote;
  final FlashOrder? lastValidatedOrder;
  final String? successMessage;

  // Getters utilitaires
  bool get isInitial => status == PharmacistCounterStatus.initial;
  bool get isLoading => status == PharmacistCounterStatus.loading;
  bool get isLoaded => status == PharmacistCounterStatus.loaded;
  bool get isSubmittingQuote => status == PharmacistCounterStatus.submittingQuote;
  bool get isQuoteSubmitted => status == PharmacistCounterStatus.quoteSubmitted;
  bool get isValidatingOtp => status == PharmacistCounterStatus.validatingOtp;
  bool get isOtpSuccess => status == PharmacistCounterStatus.otpSuccess;
  bool get isFailure => status == PharmacistCounterStatus.failure;

  /// Liste filtrée selon le statut éventuel (ex: 'pending', 'readyForPickup', etc.)
  List<FlashOrder> get filteredOrders {
    if (filterStatus == null || filterStatus!.isEmpty) {
      return orders;
    }
    return orders.where((order) => order.status.name == filterStatus).toList();
  }

  PharmacistCounterState copyWith({
    PharmacistCounterStatus? status,
    List<FlashOrder>? orders,
    FlashOrder? selectedOrder,
    bool clearSelectedOrder = false,
    String? filterStatus,
    bool clearFilter = false,
    int? selectedOrderWaveRemainingSeconds,
    bool clearWaveRemaining = false,
    String? errorMessage,
    bool clearError = false,
    Failure? failure,
    PharmacyOffer? lastSubmittedQuote,
    FlashOrder? lastValidatedOrder,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return PharmacistCounterState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      selectedOrder:
          clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      filterStatus: clearFilter ? null : (filterStatus ?? this.filterStatus),
      selectedOrderWaveRemainingSeconds: clearWaveRemaining
          ? null
          : (selectedOrderWaveRemainingSeconds ??
              this.selectedOrderWaveRemainingSeconds),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failure: clearError ? null : (failure ?? this.failure),
      lastSubmittedQuote: lastSubmittedQuote ?? this.lastSubmittedQuote,
      lastValidatedOrder: lastValidatedOrder ?? this.lastValidatedOrder,
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        orders,
        selectedOrder,
        filterStatus,
        selectedOrderWaveRemainingSeconds,
        errorMessage,
        failure,
        lastSubmittedQuote,
        lastValidatedOrder,
        successMessage,
      ];
}
