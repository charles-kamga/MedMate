import 'package:equatable/equatable.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import 'basket_item.dart';
import 'pharmacy_offer.dart';

/// Statuts possibles de réponse d'un pharmacien selon les exigences du client
enum PharmacistReplyType {
  waiting,
  available,
  unavailable,
  conditional,
}

/// Méthodes de paiement / retrait supportées
enum FlashPaymentMethod {
  cashCounter,
  orangeMoney,
  mtnMoMo,
}

/// Statuts de transaction de paiement (Section 6.2 du CDC)
enum FlashPaymentStatus {
  pending,
  confirmed,
  failed,
  refunded,
}

/// Statut global du flux de commande / recherche en vagues
enum FlashOrderStatus {
  idle,
  dispatchingWave,
  offersReceived,
  accepted,
  readyForPickup,
  delivered,
  expired,
}

/// Pharmacie contactée lors du dispatch en vagues (2 pharmacies partenaires par vague)
class DispatchedPharmacy extends Equatable {
  const DispatchedPharmacy({
    required this.id,
    required this.name,
    required this.quarter,
    required this.distanceKm,
    required this.phone,
    this.waveIndex = 1,
    this.status = PharmacistReplyType.waiting,
    this.conditionNote,
    this.respondedAt,
    this.quotedPriceCfa,
  });

  final String id;
  final String name;
  final String quarter;
  final double distanceKm;
  final String phone;
  final int waveIndex;
  final PharmacistReplyType status;
  final String? conditionNote;
  final DateTime? respondedAt;
  final int? quotedPriceCfa;

  DispatchedPharmacy copyWith({
    int? waveIndex,
    PharmacistReplyType? status,
    String? conditionNote,
    DateTime? respondedAt,
    int? quotedPriceCfa,
  }) {
    return DispatchedPharmacy(
      id: id,
      name: name,
      quarter: quarter,
      distanceKm: distanceKm,
      phone: phone,
      waveIndex: waveIndex ?? this.waveIndex,
      status: status ?? this.status,
      conditionNote: conditionNote ?? this.conditionNote,
      respondedAt: respondedAt ?? this.respondedAt,
      quotedPriceCfa: quotedPriceCfa ?? this.quotedPriceCfa,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        quarter,
        distanceKm,
        phone,
        waveIndex,
        status,
        conditionNote,
        respondedAt,
        quotedPriceCfa,
      ];
}

/// Entité maîtresse de la commande en vagues successives Afya Santé V2
class FlashOrder extends Equatable {
  const FlashOrder({
    required this.id,
    required this.items,
    required this.quarter,
    required this.targets,
    required this.createdAt,
    required this.expiresAt,
    this.currentWave = 1,
    this.waveTimeRemainingSeconds = 120,
    this.offers = const [],
    this.selectedOffer,
    this.status = FlashOrderStatus.dispatchingWave,
    this.paymentMethod,
    this.paymentStatus = FlashPaymentStatus.pending,
    this.phoneNumber,
    this.reservationOtpCode,
    this.isPickedUp = false,
  });

  final String id;
  final List<BasketItem> items;
  final String quarter;
  final List<DispatchedPharmacy> targets;
  final int currentWave;
  final int waveTimeRemainingSeconds;
  final List<PharmacyOffer> offers;
  final PharmacyOffer? selectedOffer;
  final FlashOrderStatus status;
  final FlashPaymentMethod? paymentMethod;
  final FlashPaymentStatus paymentStatus;
  final String? phoneNumber;
  final String? reservationOtpCode;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isPickedUp;

  /// Compatibilité & Accesseurs
  Medication get medication => items.isNotEmpty
      ? items.first.medication
      : const Medication(
          id: 'default',
          nomCommercial: 'Médicament',
          dci: 'DCI',
          forme: 'Comprimé',
          dosage: 'Standard',
          classeTherapeutique: 'Général',
          prixHomologueCfa: 0,
          necessiteOrdonnance: false,
        );

  int get quantity => items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Montant total calculé STRICTEMENT à partir de l'offre acceptée du pharmacien
  /// Afya Santé ne fixe aucun montant automatique.
  int get totalAmountCfa => selectedOffer?.grandTotalCfa ?? 0;

  DispatchedPharmacy? get winnerPharmacy {
    if (selectedOffer == null) return null;
    return targets.cast<DispatchedPharmacy?>().firstWhere(
          (t) => t?.id == selectedOffer!.pharmacyId,
          orElse: () => null,
        );
  }

  PharmacistReplyType? get winnerReplyType {
    if (selectedOffer == null) return null;
    switch (selectedOffer!.availabilityType) {
      case PharmacyAvailabilityType.fullyAvailable:
        return PharmacistReplyType.available;
      case PharmacyAvailabilityType.partiallyAvailable:
      case PharmacyAvailabilityType.conditional:
        return PharmacistReplyType.conditional;
      case PharmacyAvailabilityType.unavailable:
        return PharmacistReplyType.unavailable;
    }
  }

  String? get conditionNote => selectedOffer?.conditionNote;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  FlashOrder copyWith({
    String? id,
    List<BasketItem>? items,
    String? quarter,
    List<DispatchedPharmacy>? targets,
    int? currentWave,
    int? waveTimeRemainingSeconds,
    List<PharmacyOffer>? offers,
    PharmacyOffer? selectedOffer,
    FlashOrderStatus? status,
    FlashPaymentMethod? paymentMethod,
    FlashPaymentStatus? paymentStatus,
    String? phoneNumber,
    String? reservationOtpCode,
    DateTime? expiresAt,
    bool? isPickedUp,
  }) {
    return FlashOrder(
      id: id ?? this.id,
      items: items ?? this.items,
      quarter: quarter ?? this.quarter,
      targets: targets ?? this.targets,
      currentWave: currentWave ?? this.currentWave,
      waveTimeRemainingSeconds: waveTimeRemainingSeconds ?? this.waveTimeRemainingSeconds,
      offers: offers ?? this.offers,
      selectedOffer: selectedOffer ?? this.selectedOffer,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      reservationOtpCode: reservationOtpCode ?? this.reservationOtpCode,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isPickedUp: isPickedUp ?? this.isPickedUp,
    );
  }

  @override
  List<Object?> get props => [
        id,
        items,
        quarter,
        targets,
        currentWave,
        waveTimeRemainingSeconds,
        offers,
        selectedOffer,
        status,
        paymentMethod,
        paymentStatus,
        phoneNumber,
        reservationOtpCode,
        createdAt,
        expiresAt,
        isPickedUp,
      ];
}
