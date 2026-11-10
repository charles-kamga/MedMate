import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/errors/failures.dart';
import '../../../flash_order/domain/entities/basket_item.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/repositories/pharmacist_portal_repository.dart';

/// Implémentation in-memory robuste du référentiel comptoir pharmacien
class PharmacistPortalRepositoryImpl implements PharmacistPortalRepository {
  PharmacistPortalRepositoryImpl({Map<String, FlashOrder>? initialOrders}) {
    if (initialOrders != null) {
      _orders.addAll(initialOrders);
    } else {
      _seedDefaultDemoOrders();
    }
  }

  final Map<String, FlashOrder> _orders = {};

  @override
  Future<Either<Failure, List<FlashOrder>>> getPendingOrdersForPharmacy(
    String pharmacyId,
  ) async {
    try {
      final list = _orders.values.where((order) {
        final isTargeted = order.targets.any((t) => t.id == pharmacyId);
        final isAssigned = order.selectedOffer?.pharmacyId == pharmacyId;
        return isTargeted || isAssigned;
      }).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return Right(List.unmodifiable(list));
    } catch (e) {
      return Left(ServerFailure('Erreur lors du chargement des commandes : $e'));
    }
  }

  @override
  Future<Either<Failure, PharmacyOffer>> submitQuote({
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
    try {
      final order = _orders[orderId];
      if (order == null) {
        return const Left(NotFoundFailure('Demande flash introuvable.'));
      }

      // Vérification du ciblage de l'officine
      final targetIndex = order.targets.indexWhere((t) => t.id == pharmacyId);
      if (targetIndex == -1) {
        return const Left(NotFoundFailure("Cette officine n'est pas ciblée par cette demande."));
      }

      // Vérification de l'expiration de la vague (2 minutes max)
      if (order.waveTimeRemainingSeconds <= 0 || order.isExpired) {
        return const Left(WaveExpiredFailure());
      }

      // Détection de conflit de concurrence : déjà attribuée à un confrère
      final isAlreadyClaimedByOther = (order.status == FlashOrderStatus.accepted ||
              order.status == FlashOrderStatus.readyForPickup ||
              order.status == FlashOrderStatus.delivered) &&
          order.selectedOffer != null &&
          order.selectedOffer!.pharmacyId != pharmacyId;

      if (isAlreadyClaimedByOther) {
        return const Left(OrderAlreadyClaimedFailure());
      }

      // Conversion du statut de réponse pour l'officine ciblée
      final replyType = switch (availability) {
        PharmacyAvailabilityType.fullyAvailable => PharmacistReplyType.available,
        PharmacyAvailabilityType.partiallyAvailable ||
        PharmacyAvailabilityType.conditional =>
          PharmacistReplyType.conditional,
        PharmacyAvailabilityType.unavailable => PharmacistReplyType.unavailable,
      };

      final targetPharma = order.targets[targetIndex];
      final now = DateTime.now();

      final offer = PharmacyOffer(
        id: 'OFFER-${order.id}-$pharmacyId',
        pharmacyId: pharmacyId,
        pharmacyName: targetPharma.name,
        quarter: targetPharma.quarter,
        distanceKm: targetPharma.distanceKm,
        phone: targetPharma.phone,
        availabilityType: availability,
        quotedPriceCfa: quotedPriceCfa,
        conditionRequirements: conditionRequirements,
        conditionNote: conditionNote,
        proposesDelivery: proposesDelivery,
        deliveryFeeCfa: proposesDelivery ? deliveryFeeCfa : 0,
        estimatedDeliveryMinutes: estimatedDeliveryMinutes,
        submittedAt: now,
      );

      // Mise à jour de la cible correspondante dans l'ordre
      final updatedTargets = List<DispatchedPharmacy>.from(order.targets);
      updatedTargets[targetIndex] = targetPharma.copyWith(
        status: replyType,
        conditionNote: conditionNote,
        quotedPriceCfa: quotedPriceCfa,
        respondedAt: now,
      );

      // Mise à jour de la liste des offres reçues
      final updatedOffers = List<PharmacyOffer>.from(
        order.offers.where((o) => o.pharmacyId != pharmacyId),
      )..add(offer);

      final updatedOrder = order.copyWith(
        targets: updatedTargets,
        offers: updatedOffers,
        status: FlashOrderStatus.offersReceived,
      );

      _orders[orderId] = updatedOrder;
      return Right(offer);
    } catch (e) {
      return Left(ServerFailure("Erreur lors de l'enregistrement du devis : $e"));
    }
  }

  @override
  Future<Either<Failure, FlashOrder>> validateOtpAtCounter({
    required String orderId,
    required String pharmacyId,
    required String otpCode,
  }) async {
    try {
      final order = _orders[orderId];
      if (order == null) {
        return const Left(NotFoundFailure('Demande de retrait introuvable.'));
      }

      // Vérification du format à 6 chiffres
      final otpRegex = RegExp(r'^\d{6}$');
      if (!otpRegex.hasMatch(otpCode.trim())) {
        return const Left(InvalidOtpFailure());
      }

      // Vérification si déjà consommé
      if (order.status == FlashOrderStatus.delivered || order.isPickedUp) {
        return const Left(ConsumedOtpFailure());
      }

      // Vérification de la validité temporelle (TTL 2h max)
      final now = DateTime.now();
      final isTtlExpired = now.isAfter(order.expiresAt) ||
          now.difference(order.createdAt).inHours >= 2;
      if (isTtlExpired) {
        return const Left(ExpiredOtpFailure());
      }

      // Vérification de concordance du code OTP
      if (order.reservationOtpCode == null ||
          order.reservationOtpCode!.trim() != otpCode.trim()) {
        return const Left(InvalidOtpFailure());
      }

      // Vérification que la commande est bien attribuée à cette officine
      if (order.selectedOffer != null &&
          order.selectedOffer!.pharmacyId != pharmacyId) {
        return const Left(OrderAlreadyClaimedFailure());
      }

      // Transition vers statut livré et retrait consommé
      final deliveredOrder = order.copyWith(
        status: FlashOrderStatus.delivered,
        isPickedUp: true,
      );

      _orders[orderId] = deliveredOrder;
      return Right(deliveredOrder);
    } catch (e) {
      return Left(ServerFailure('Erreur lors de la validation OTP : $e'));
    }
  }

  /// Initialisation de jeux de données représentatifs du tissu urbain de Yaoundé
  void _seedDefaultDemoOrders() {
    final now = DateTime.now();
    final landmarkWarda = YaoundeLandmarks.list.firstWhere(
      (l) => l.id == 'carrefour-warda',
      orElse: () => YaoundeLandmarks.list.first,
    );
    final landmarkObili = YaoundeLandmarks.list.firstWhere(
      (l) => l.id == 'carrefour-obili',
      orElse: () => YaoundeLandmarks.list.first,
    );

    const medParacetamol = Medication(
      id: 'med-parac-500',
      dci: 'Paracétamol',
      nomCommercial: 'Efferalgan 500mg',
      forme: 'Comprimé effervescent',
      dosage: '500 mg',
      classeTherapeutique: 'Antalgique / Antipyrétique',
      prixHomologueCfa: 1200,
      necessiteOrdonnance: false,
    );

    const medAmox = Medication(
      id: 'med-amox-500',
      dci: 'Amoxicilline',
      nomCommercial: 'Clamoxyl 500mg',
      forme: 'Gélule',
      dosage: '500 mg',
      classeTherapeutique: 'Antibactérien',
      prixHomologueCfa: 2500,
      necessiteOrdonnance: true,
    );

    const medCoartem = Medication(
      id: 'med-art-lum',
      dci: 'Artéméther + Luméfantrine',
      nomCommercial: 'Coartem 20/120mg',
      forme: 'Comprimé',
      dosage: '20 mg / 120 mg',
      classeTherapeutique: 'Antipaludique CTA',
      prixHomologueCfa: 3200,
      necessiteOrdonnance: true,
    );

    const targetSoleil = DispatchedPharmacy(
      id: 'pharma-soleil',
      name: 'Pharmacie du Soleil',
      quarter: 'Carrefour Warda',
      distanceKm: 0.4,
      phone: '+237 677 12 34 56',
      waveIndex: 1,
      status: PharmacistReplyType.waiting,
    );

    const targetCentre = DispatchedPharmacy(
      id: 'pharma-centre',
      name: 'Grande Pharmacie du Centre',
      quarter: 'Poste Centrale',
      distanceKm: 0.9,
      phone: '+237 699 88 77 66',
      waveIndex: 1,
      status: PharmacistReplyType.waiting,
    );

    // 1. Demande en attente (Vague 1 en cours - 95s restantes)
    final order1 = FlashOrder(
      id: 'ORD-YAO-101',
      items: const [
        BasketItem(id: 'item-1', medication: medParacetamol, quantity: 2),
        BasketItem(
          id: 'item-2',
          medication: medAmox,
          quantity: 1,
          hasPrescription: true,
          prescriptionNote: 'Ordonnance Dr Kamga du 09/11/2026',
        ),
      ],
      quarter: '${landmarkWarda.nom}, ${landmarkWarda.quartier}',
      targets: const [targetSoleil, targetCentre],
      currentWave: 1,
      waveTimeRemainingSeconds: 95,
      status: FlashOrderStatus.dispatchingWave,
      createdAt: now.subtract(const Duration(seconds: 25)),
      expiresAt: now.add(const Duration(hours: 2)),
    );

    // 2. Demande prête pour retrait au comptoir avec code OTP (Test OTP)
    final acceptedOfferSoleil = PharmacyOffer(
      id: 'OFFER-ORD-YAO-102-pharma-soleil',
      pharmacyId: targetSoleil.id,
      pharmacyName: targetSoleil.name,
      quarter: targetSoleil.quarter,
      distanceKm: targetSoleil.distanceKm,
      phone: targetSoleil.phone,
      availabilityType: PharmacyAvailabilityType.fullyAvailable,
      quotedPriceCfa: 3200,
      isAccepted: true,
      submittedAt: now.subtract(const Duration(minutes: 15)),
    );

    final order2 = FlashOrder(
      id: 'ORD-YAO-102',
      items: const [
        BasketItem(id: 'item-3', medication: medCoartem, quantity: 1),
      ],
      quarter: '${landmarkObili.nom}, ${landmarkObili.quartier}',
      targets: [targetSoleil.copyWith(status: PharmacistReplyType.available)],
      currentWave: 1,
      waveTimeRemainingSeconds: 0,
      offers: [acceptedOfferSoleil],
      selectedOffer: acceptedOfferSoleil,
      status: FlashOrderStatus.readyForPickup,
      reservationOtpCode: '482910',
      phoneNumber: '+237 690 12 34 56',
      createdAt: now.subtract(const Duration(minutes: 20)),
      expiresAt: now.add(const Duration(minutes: 100)),
    );

    _orders[order1.id] = order1;
    _orders[order2.id] = order2;
  }
}
