import 'dart:async';
import 'dart:math';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/errors/failures.dart';
import '../../../../features/flash_order/domain/entities/basket_item.dart';
import '../../../../features/flash_order/domain/entities/flash_order.dart';
import '../../../../features/flash_order/domain/entities/pharmacy_offer.dart';
import '../../../../features/pharmacy_search/domain/entities/reservation.dart';
import '../../domain/repositories/realtime_dispatch_repository.dart';
import '../datasources/adaptive_polling_fallback_manager.dart';
import '../datasources/secure_delivery_ticket_vault.dart';
import '../datasources/supabase_realtime_datasource.dart';
import '../datasources/yaounde_topological_router.dart';

/// Implémentation concrète de [RealtimeDispatchRepository]
/// Orchestre la datasource temps réel Supabase, le routeur topologique de Yaoundé
/// et les fallbacks de résilience réseau (3G/EDGE).
class RealtimeDispatchRepositoryImpl implements RealtimeDispatchRepository {
  RealtimeDispatchRepositoryImpl({
    required this.realtimeDataSource,
    required this.router,
    SecureDeliveryTicketVault? ticketVault,
    Uuid? uuid,
  })  : ticketVault = ticketVault ?? SecureDeliveryTicketVault(),
        _uuid = uuid ?? const Uuid();

  final SupabaseRealtimeDataSource realtimeDataSource;
  final YaoundeTopologicalRouter router;
  final SecureDeliveryTicketVault ticketVault;
  final Uuid _uuid;

  // Cache mémoire pour l'idempotence et les tests offline
  final Map<String, FlashOrder> _ordersCache = {};
  final Map<String, List<PharmacyOffer>> _offersCache = {};

  @override
  Stream<FlashOrder> watchFlashOrder(String orderId) {
    return realtimeDataSource.watchFlashOrder(orderId);
  }

  @override
  Stream<List<PharmacyOffer>> watchOffersForOrder(String orderId) {
    return realtimeDataSource.watchOffersForOrder(orderId);
  }

  @override
  Stream<List<FlashOrder>> watchPendingOrdersForPharmacy(String pharmacyId) {
    return realtimeDataSource.watchPendingOrdersForPharmacy(pharmacyId);
  }

  @override
  Stream<RealtimeConnectionStatus> get connectionStatusStream =>
      realtimeDataSource.fallbackManager.statusStream;

  @override
  Future<Either<Failure, FlashOrder>> submitFlashRequest({
    required List<BasketItem> items,
    required YaoundeLandmark landmark,
  }) async {
    try {
      final orderId = _uuid.v4();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 2));

      // Calcul des cibles de la Vague 1 (< 5 min) via le routeur topologique
      final wave1LandmarkIds = router.getEligibleLandmarksForWave(landmark.id, 1);
      final targets = _buildInitialTargets(wave1LandmarkIds, landmark);

      final order = FlashOrder(
        id: orderId,
        items: items,
        quarter: landmark.quartier,
        targets: targets,
        createdAt: now,
        expiresAt: expiresAt,
        currentWave: 1,
        waveTimeRemainingSeconds: 120,
        status: FlashOrderStatus.dispatchingWave,
      );

      _ordersCache[orderId] = order;
      return Right(order);
    } catch (e) {
      return Left(ServerFailure('Erreur lors de la création de la commande: $e'));
    }
  }

  @override
  Future<Either<Failure, FlashOrder>> escalateDispatchWave(String orderId) async {
    try {
      final existing = _ordersCache[orderId];
      if (existing == null) {
        return const Left(ServerFailure('Commande introuvable pour escalade'));
      }

      final nextWave = existing.currentWave + 1;
      final originLandmark = YaoundeTopologicalRouter.yaoundeLandmarks.firstWhere(
        (l) => l.quartier.toLowerCase() == existing.quarter.toLowerCase(),
        orElse: () => YaoundeTopologicalRouter.yaoundeLandmarks.first,
      );

      // Expansion vers les corridors artériels de Vague 2 (5-15 min)
      final waveLandmarkIds = router.getEligibleLandmarksForWave(originLandmark.id, nextWave);
      final updatedTargets = List<DispatchedPharmacy>.from(existing.targets);

      for (final id in waveLandmarkIds) {
        final lm = router.findLandmarkById(id);
        if (lm != null && !updatedTargets.any((t) => t.quarter == lm.quartier)) {
          final route = router.calculateTopologicalRoute(originLandmark.id, lm.id);
          updatedTargets.add(
            DispatchedPharmacy(
              id: 'pharmacy-$id',
              name: 'Pharmacie ${lm.nom}',
              quarter: lm.quartier,
              distanceKm: route.distanceKm,
              phone: '+237 600000000',
              waveIndex: nextWave,
            ),
          );
        }
      }

      final updatedOrder = existing.copyWith(
        currentWave: nextWave,
        waveTimeRemainingSeconds: 120,
        targets: updatedTargets,
        status: FlashOrderStatus.dispatchingWave,
      );

      _ordersCache[orderId] = updatedOrder;
      await realtimeDataSource.updateOrderStatus(orderId, updatedOrder.status);
      return Right(updatedOrder);
    } catch (e) {
      return Left(ServerFailure("Erreur lors de l'escalade de vague: $e"));
    }
  }

  @override
  Future<Either<Failure, FlashOrder>> getFlashRequestById(String orderId) async {
    final cached = _ordersCache[orderId];
    if (cached != null) return Right(cached);
    return const Left(ServerFailure('Commande flash introuvable'));
  }

  @override
  Future<Either<Failure, Reservation>> selectPharmacyOffer({
    required String orderId,
    required PharmacyOffer offer,
    required String patientPhone,
  }) async {
    try {
      final order = _ordersCache[orderId];
      if (order == null) {
        return const Left(ServerFailure('Commande flash introuvable'));
      }

      // Génération code OTP à 6 chiffres pour retrait comptoir
      final otpCode = _generateOtpCode();
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 2));

      final reservation = Reservation(
        id: _uuid.v4(),
        clientReservationId: _uuid.v4(),
        pharmacyId: offer.pharmacyId,
        pharmacyName: offer.pharmacyName,
        medicationId: order.medication.id,
        medicationName: order.medication.nomCommercial,
        quantite: order.quantity,
        codeRetraitOtp: otpCode,
        statut: ReservationStatus.confirmed,
        createdAt: now,
        expiresAt: expiresAt,
      );

      final acceptedOffer = offer.copyWith(isAccepted: true);
      final updatedOrder = order.copyWith(
        status: FlashOrderStatus.accepted,
        selectedOffer: acceptedOffer,
        phoneNumber: patientPhone,
        reservationOtpCode: otpCode,
      );

      _ordersCache[orderId] = updatedOrder;
      await realtimeDataSource.updateOrderStatus(
        orderId,
        FlashOrderStatus.accepted,
        selectedOffer: acceptedOffer,
      );

      return Right(reservation);
    } catch (e) {
      return Left(ServerFailure("Erreur lors de la sélection de l'offre: $e"));
    }
  }

  @override
  Future<Either<Failure, List<FlashOrder>>> getPendingOrdersForPharmacy(
    String pharmacyId,
  ) async {
    try {
      final pending = _ordersCache.values.where((o) {
        return o.status == FlashOrderStatus.dispatchingWave ||
            o.status == FlashOrderStatus.offersReceived;
      }).toList();
      return Right(pending);
    } catch (e) {
      return Left(ServerFailure('Erreur de récupération des commandes en attente: $e'));
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
      final order = _ordersCache[orderId];
      if (order != null && order.status == FlashOrderStatus.accepted) {
        return const Left(ServerFailure('Cette commande a déjà été acceptée par un confrère'));
      }

      final offer = PharmacyOffer(
        id: _uuid.v4(),
        pharmacyId: pharmacyId,
        pharmacyName: 'Pharmacie Partenaire Yaoundé',
        quarter: order?.quarter ?? 'Yaoundé',
        distanceKm: 1.5,
        phone: '+237 670000000',
        availabilityType: availability,
        quotedPriceCfa: quotedPriceCfa,
        conditionRequirements: conditionRequirements,
        conditionNote: conditionNote,
        proposesDelivery: proposesDelivery,
        deliveryFeeCfa: deliveryFeeCfa,
        estimatedDeliveryMinutes: estimatedDeliveryMinutes,
        submittedAt: DateTime.now(),
      );

      _offersCache.putIfAbsent(orderId, () => []).add(offer);

      if (order != null) {
        final updatedOffers = List<PharmacyOffer>.from(order.offers)..add(offer);
        _ordersCache[orderId] = order.copyWith(
          offers: updatedOffers,
          status: FlashOrderStatus.offersReceived,
        );
      }

      await realtimeDataSource.submitQuote(offer, orderId);
      return Right(offer);
    } catch (e) {
      return Left(ServerFailure("Erreur lors de l'émission du devis: $e"));
    }
  }

  @override
  Future<Either<Failure, FlashOrder>> validateOtpAtCounter({
    required String orderId,
    required String pharmacyId,
    required String otpCode,
  }) async {
    try {
      final order = _ordersCache[orderId];
      if (order == null) {
        return const Left(ServerFailure('Commande introuvable au comptoir'));
      }

      if (order.isPickedUp || order.status == FlashOrderStatus.delivered) {
        return const Left(ServerFailure('Cette commande a déjà été retirée au comptoir'));
      }

      if (order.isExpired) {
        return const Left(ServerFailure('Ce code de retrait OTP a expiré (> 2 heures)'));
      }

      if (order.reservationOtpCode != otpCode) {
        return const Left(ServerFailure('Code OTP de retrait invalide'));
      }

      final deliveredOrder = order.copyWith(
        status: FlashOrderStatus.delivered,
        isPickedUp: true,
      );

      _ordersCache[orderId] = deliveredOrder;
      await realtimeDataSource.updateOrderStatus(orderId, FlashOrderStatus.delivered);

      // Archivage sécurisé du ticket de délivrance (Loi n° 2024/017 & ONPC)
      final itemsSummary = order.items.isNotEmpty
          ? order.items.map((i) => '${i.medication.nomCommercial} x${i.quantity}').join(', ')
          : '${order.medication.nomCommercial} x${order.quantity}';

      final ticketId = _uuid.v4();
      final otpHash = SecureDeliveryTicketVault.hashOtp(otpCode);

      await ticketVault.archiveDeliveryTicket(
        ticketId: ticketId,
        orderId: orderId,
        pharmacyId: pharmacyId,
        pharmacistStaffId: 'staff-$pharmacyId',
        validationTimestamp: DateTime.now(),
        encryptedOtpHash: otpHash,
        deliveredItemsSummary: itemsSummary,
      );

      return Right(deliveredOrder);
    } catch (e) {
      return Left(ServerFailure('Erreur de validation OTP au comptoir: $e'));
    }
  }

  @override
  void dispose() {
    realtimeDataSource.dispose();
  }

  List<DispatchedPharmacy> _buildInitialTargets(
    List<String> landmarkIds,
    YaoundeLandmark origin,
  ) {
    final targets = <DispatchedPharmacy>[];
    for (final id in landmarkIds) {
      final lm = router.findLandmarkById(id);
      if (lm != null) {
        final route = router.calculateTopologicalRoute(origin.id, lm.id);
        targets.add(
          DispatchedPharmacy(
            id: 'pharmacy-$id',
            name: 'Pharmacie ${lm.nom}',
            quarter: lm.quartier,
            distanceKm: route.distanceKm,
            phone: '+237 600000000',
            waveIndex: 1,
          ),
        );
      }
    }
    return targets;
  }

  String _generateOtpCode() {
    final rnd = Random();
    return (100000 + rnd.nextInt(900000)).toString();
  }
}
