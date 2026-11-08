import 'package:equatable/equatable.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/basket_item.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';

export '../../domain/entities/flash_order.dart'
    show FlashOrderStatus, FlashPaymentMethod, FlashPaymentStatus, PharmacistReplyType;

enum UserRole {
  patient,
  pharmacist,
}

/// État réactif du flux Afya Santé V2 (Panier, Vagues 2 min, Devis, Retrait OTP)
class FlashOrderState extends Equatable {
  const FlashOrderState({
    this.userRole = UserRole.patient,
    this.basketItems = const [],
    this.selectedQuarter = 'Carrefour Warda, Poste Centrale',
    this.activeOrder,
    this.activePharmacistIndex = 0,
    this.otpValidationSuccess,
    this.otpValidationError,
    this.errorMessage,
  });

  final UserRole userRole;
  final List<BasketItem> basketItems;
  final String selectedQuarter;
  final FlashOrder? activeOrder;
  final int activePharmacistIndex;
  final bool? otpValidationSuccess;
  final String? otpValidationError;
  final String? errorMessage;

  /// Compatibilité ascendante
  Medication? get selectedMedication => basketItems.isNotEmpty ? basketItems.first.medication : null;
  int get quantity => basketItems.fold<int>(0, (sum, item) => sum + item.quantity);

  bool get hasActiveOrder => activeOrder != null;
  bool get isDispatching => activeOrder?.status == FlashOrderStatus.dispatchingWave;
  int get currentWave => activeOrder?.currentWave ?? 1;
  int get waveTimeRemainingSeconds => activeOrder?.waveTimeRemainingSeconds ?? 120;
  List<PharmacyOffer> get receivedOffers => activeOrder?.offers ?? const [];
  bool get hasOffers => receivedOffers.isNotEmpty;
  PharmacyOffer? get selectedOffer => activeOrder?.selectedOffer;
  bool get hasAcceptedOffer => selectedOffer != null;
  bool get hasWinner => selectedOffer != null;
  bool get isConfirmed =>
      activeOrder?.status == FlashOrderStatus.accepted ||
      activeOrder?.status == FlashOrderStatus.readyForPickup;
  String? get reservationOtpCode => activeOrder?.reservationOtpCode;

  FlashOrderState copyWith({
    UserRole? userRole,
    List<BasketItem>? basketItems,
    String? selectedQuarter,
    FlashOrder? activeOrder,
    bool clearActiveOrder = false,
    int? activePharmacistIndex,
    bool? otpValidationSuccess,
    bool clearOtpStatus = false,
    String? otpValidationError,
    String? errorMessage,
  }) {
    return FlashOrderState(
      userRole: userRole ?? this.userRole,
      basketItems: basketItems ?? this.basketItems,
      selectedQuarter: selectedQuarter ?? this.selectedQuarter,
      activeOrder: clearActiveOrder ? null : (activeOrder ?? this.activeOrder),
      activePharmacistIndex: activePharmacistIndex ?? this.activePharmacistIndex,
      otpValidationSuccess: clearOtpStatus ? null : (otpValidationSuccess ?? this.otpValidationSuccess),
      otpValidationError: clearOtpStatus ? null : (otpValidationError ?? this.otpValidationError),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        userRole,
        basketItems,
        selectedQuarter,
        activeOrder,
        activePharmacistIndex,
        otpValidationSuccess,
        otpValidationError,
        errorMessage,
      ];
}
