import 'dart:math';
import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/basket_item.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import '../../domain/entities/reservation.dart';
import '../../domain/repositories/reservation_repository.dart';

/// Implémentation opérationnelle du ReservationRepository
class ReservationRepositoryImpl implements ReservationRepository {
  ReservationRepositoryImpl({Random? random}) : _random = random ?? Random();

  final Random _random;
  final Map<String, FlashOrder> _orders = {};

  /// Offres simulées de vague 1 pour alimenter la comparaison libre du patient
  static final List<DispatchedPharmacy> defaultWave1Pharmacies = [
    const DispatchedPharmacy(
      id: 'pharma-soleil',
      name: 'Pharmacie du Soleil',
      quarter: 'Carrefour Warda',
      distanceKm: 0.4,
      phone: '+237 677 12 34 56',
      waveIndex: 1,
    ),
    const DispatchedPharmacy(
      id: 'pharma-centre',
      name: 'Grande Pharmacie du Centre',
      quarter: 'Poste Centrale',
      distanceKm: 0.9,
      phone: '+237 699 88 77 66',
      waveIndex: 1,
    ),
  ];

  /// Offres de vague 2 pour l'escalade (2 pharmacies partenaires supplémentaires)
  static final List<DispatchedPharmacy> defaultWave2Pharmacies = [
    const DispatchedPharmacy(
      id: 'pharma-obili',
      name: "Pharmacie d'Obili",
      quarter: 'Carrefour Obili',
      distanceKm: 1.8,
      phone: '+237 655 44 33 22',
      waveIndex: 2,
    ),
    const DispatchedPharmacy(
      id: 'pharma-acacia',
      name: 'Pharmacie Acacia Biyem-Assi',
      quarter: 'Carrefour Acacia',
      distanceKm: 2.4,
      phone: '+237 670 99 88 77',
      waveIndex: 2,
    ),
  ];

  @override
  Future<Either<Failure, FlashOrder>> submitFlashRequest({
    required List<BasketItem> items,
    required YaoundeLandmark landmark,
  }) async {
    try {
      if (items.isEmpty) {
        return const Left(
            ReservationFailure('Le panier de médicaments est vide.'),);
      }

      final now = DateTime.now();
      final orderId = 'ORD-${now.millisecondsSinceEpoch % 1000000}';
      final expiresAt = now.add(const Duration(hours: 2));

      // 2 pharmacies partenaires les plus proches du repère sélectionné
      final targets = defaultWave1Pharmacies
          .map((p) => p.copyWith(status: PharmacistReplyType.waiting))
          .toList();

      // Devis émis en temps réel par les 2 pharmaciens sollicités
      final offers = [
        PharmacyOffer(
          id: 'OFFER-$orderId-1',
          pharmacyId: targets[0].id,
          pharmacyName: targets[0].name,
          quarter: targets[0].quarter,
          distanceKm: targets[0].distanceKm,
          phone: targets[0].phone,
          availabilityType: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 3100,
          proposesDelivery: false,
          submittedAt: now,
        ),
        PharmacyOffer(
          id: 'OFFER-$orderId-2',
          pharmacyId: targets[1].id,
          pharmacyName: targets[1].name,
          quarter: targets[1].quarter,
          distanceKm: targets[1].distanceKm,
          phone: targets[1].phone,
          availabilityType: PharmacyAvailabilityType.conditional,
          quotedPriceCfa: 3400,
          conditionRequirements: const [
            'Ordonnance physique originale requise',
          ],
          conditionNote: 'Vérification de l’ordonnance au comptoir',
          proposesDelivery: true,
          deliveryFeeCfa: 1000,
          estimatedDeliveryMinutes: 25,
          submittedAt: now,
        ),
      ];

      final order = FlashOrder(
        id: orderId,
        items: List.unmodifiable(items),
        quarter: '${landmark.nom}, ${landmark.quartier}',
        targets: targets,
        currentWave: 1,
        waveTimeRemainingSeconds: 120,
        offers: offers,
        status: FlashOrderStatus.offersReceived,
        createdAt: now,
        expiresAt: expiresAt,
      );

      _orders[orderId] = order;
      return Right(order);
    } catch (e) {
      return Left(
          ServerFailure('Impossible d’initialiser la demande flash : $e'),);
    }
  }

  @override
  Future<Either<Failure, FlashOrder>> escalateDispatchWave(
      String orderId,) async {
    try {
      final existingOrder = _orders[orderId];
      if (existingOrder == null) {
        return const Left(NotFoundFailure('Demande flash introuvable.'));
      }

      if (existingOrder.currentWave >= 2) {
        return Right(existingOrder);
      }

      final now = DateTime.now();
      final wave2Targets = defaultWave2Pharmacies
          .map((p) => p.copyWith(status: PharmacistReplyType.waiting))
          .toList();

      final combinedTargets = [...existingOrder.targets, ...wave2Targets];

      final newWave2Offer = PharmacyOffer(
        id: 'OFFER-$orderId-W2',
        pharmacyId: wave2Targets[0].id,
        pharmacyName: wave2Targets[0].name,
        quarter: wave2Targets[0].quarter,
        distanceKm: wave2Targets[0].distanceKm,
        phone: wave2Targets[0].phone,
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2900,
        proposesDelivery: true,
        deliveryFeeCfa: 1500,
        estimatedDeliveryMinutes: 35,
        submittedAt: now,
      );

      final updatedOffers = [...existingOrder.offers, newWave2Offer];

      final escalatedOrder = existingOrder.copyWith(
        currentWave: 2,
        targets: combinedTargets,
        offers: updatedOffers,
        waveTimeRemainingSeconds: 120,
        status: FlashOrderStatus.offersReceived,
      );

      _orders[orderId] = escalatedOrder;
      return Right(escalatedOrder);
    } catch (e) {
      return Left(ServerFailure('Erreur lors de l’escalade de vague : $e'));
    }
  }

  @override
  Future<Either<Failure, FlashOrder>> getFlashRequestById(
      String orderId,) async {
    final existingOrder = _orders[orderId];
    if (existingOrder == null) {
      return const Left(NotFoundFailure('Demande flash introuvable.'));
    }
    return Right(existingOrder);
  }

  @override
  Future<Either<Failure, Reservation>> selectPharmacyOffer({
    required String orderId,
    required PharmacyOffer offer,
    required String patientPhone,
  }) async {
    try {
      final existingOrder = _orders[orderId];
      if (existingOrder == null) {
        return const Left(NotFoundFailure('Demande flash introuvable.'));
      }

      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 2));

      // Génération stricte d'un code OTP à 6 chiffres
      final otp6Digits = (100000 + _random.nextInt(900000)).toString();

      final reservationId = 'RES-${now.millisecondsSinceEpoch % 1000000}';
      final medicationSummary = existingOrder.items
          .map((i) => '${i.medication.nomCommercial} (x${i.quantity})')
          .join(', ');
      final totalQuantity =
          existingOrder.items.fold<int>(0, (sum, i) => sum + i.quantity);

      final reservation = Reservation(
        id: reservationId,
        clientReservationId: orderId,
        pharmacyId: offer.pharmacyId,
        pharmacyName: offer.pharmacyName,
        medicationId: existingOrder.items.isNotEmpty
            ? existingOrder.items.first.medication.id
            : 'multi',
        medicationName: medicationSummary,
        quantite: totalQuantity,
        codeRetraitOtp: otp6Digits,
        statut: ReservationStatus.confirmed,
        createdAt: now,
        expiresAt: expiresAt,
      );

      final updatedOffers = existingOrder.offers
          .map((o) => o.copyWith(isAccepted: o.id == offer.id))
          .toList();

      final updatedOrder = existingOrder.copyWith(
        selectedOffer: offer.copyWith(isAccepted: true),
        offers: updatedOffers,
        status: FlashOrderStatus.readyForPickup,
        reservationOtpCode: otp6Digits,
        phoneNumber: patientPhone,
      );

      _orders[orderId] = updatedOrder;
      return Right(reservation);
    } catch (e) {
      return Left(
          ReservationFailure('Échec de la validation de réservation : $e'),);
    }
  }
}
