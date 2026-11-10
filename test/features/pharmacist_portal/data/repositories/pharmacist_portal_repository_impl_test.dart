import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';

void main() {
  late PharmacistPortalRepositoryImpl repository;

  const pharmaSoleilId = 'pharma-soleil';
  const pharmaOtherId = 'pharma-centre';

  const sampleMedication = Medication(
    id: 'med-parac-500',
    dci: 'Paracétamol',
    nomCommercial: 'Efferalgan 500mg',
    forme: 'Comprimé',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1200,
    necessiteOrdonnance: false,
  );

  const targetSoleil = DispatchedPharmacy(
    id: pharmaSoleilId,
    name: 'Pharmacie du Soleil',
    quarter: 'Carrefour Warda',
    distanceKm: 0.4,
    phone: '+237 677 12 34 56',
    waveIndex: 1,
  );

  const targetOther = DispatchedPharmacy(
    id: pharmaOtherId,
    name: 'Grande Pharmacie du Centre',
    quarter: 'Poste Centrale',
    distanceKm: 0.9,
    phone: '+237 699 88 77 66',
    waveIndex: 1,
  );

  final sampleActiveOrder = FlashOrder(
    id: 'ORD-ACTIVE-1',
    items: const [
      BasketItem(id: 'item-1', medication: sampleMedication, quantity: 1),
    ],
    quarter: 'Carrefour Warda, Yaoundé',
    targets: const [targetSoleil, targetOther],
    currentWave: 1,
    waveTimeRemainingSeconds: 85,
    status: FlashOrderStatus.dispatchingWave,
    createdAt: DateTime.now().subtract(const Duration(seconds: 35)),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  final sampleOtpOrder = FlashOrder(
    id: 'ORD-OTP-1',
    items: const [
      BasketItem(id: 'item-2', medication: sampleMedication, quantity: 1),
    ],
    quarter: 'Carrefour Warda, Yaoundé',
    targets: const [targetSoleil],
    currentWave: 1,
    waveTimeRemainingSeconds: 0,
    status: FlashOrderStatus.readyForPickup,
    reservationOtpCode: '123456',
    phoneNumber: '+237 690 00 11 22',
    createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    expiresAt: DateTime.now().add(const Duration(hours: 1, minutes: 45)),
    selectedOffer: PharmacyOffer(
      id: 'OFFER-OTP-1',
      pharmacyId: pharmaSoleilId,
      pharmacyName: 'Pharmacie du Soleil',
      quarter: 'Carrefour Warda',
      distanceKm: 0.4,
      phone: '+237 677 12 34 56',
      availabilityType: PharmacyAvailabilityType.fullyAvailable,
      quotedPriceCfa: 1500,
      submittedAt: DateTime.now().subtract(const Duration(minutes: 15)),
      isAccepted: true,
    ),
  );

  setUp(() {
    repository = PharmacistPortalRepositoryImpl(
      initialOrders: {
        sampleActiveOrder.id: sampleActiveOrder,
        sampleOtpOrder.id: sampleOtpOrder,
      },
    );
  });

  group('PharmacistPortalRepositoryImpl - getPendingOrdersForPharmacy', () {
    test('retourne les commandes ciblant ou attribuées à l’officine', () async {
      final result = await repository.getPendingOrdersForPharmacy(pharmaSoleilId);
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Devrait réussir'),
        (orders) {
          expect(orders.length, 2);
          expect(orders.map((o) => o.id), contains(sampleActiveOrder.id));
          expect(orders.map((o) => o.id), contains(sampleOtpOrder.id));
        },
      );
    });

    test('utilise les données de démo par défaut si aucun store initial fourni', () async {
      final defaultRepo = PharmacistPortalRepositoryImpl();
      final result = await defaultRepo.getPendingOrdersForPharmacy('pharma-soleil');
      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Devrait réussir'),
        (orders) => expect(orders.isNotEmpty, isTrue),
      );
    });
  });

  group('PharmacistPortalRepositoryImpl - submitQuote', () {
    test('émet un devis fullyAvailable avec succès', () async {
      final result = await repository.submitQuote(
        orderId: sampleActiveOrder.id,
        pharmacyId: pharmaSoleilId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2000,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Devrait réussir'),
        (offer) {
          expect(offer.quotedPriceCfa, 2000);
          expect(offer.availabilityType, PharmacyAvailabilityType.fullyAvailable);
          expect(offer.pharmacyId, pharmaSoleilId);
        },
      );
    });

    test('rejette si le temps de vague restant est <= 0 (WaveExpiredFailure)', () async {
      final expiredWaveOrder = sampleActiveOrder.copyWith(
        id: 'ORD-EXPIRED-WAVE',
        waveTimeRemainingSeconds: 0,
      );
      final repo = PharmacistPortalRepositoryImpl(
        initialOrders: {expiredWaveOrder.id: expiredWaveOrder},
      );

      final result = await repo.submitQuote(
        orderId: expiredWaveOrder.id,
        pharmacyId: pharmaSoleilId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2000,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<WaveExpiredFailure>()),
        (_) => fail('Devrait échouer'),
      );
    });

    test('rejette si la commande a déjà été acceptée par une autre officine (OrderAlreadyClaimedFailure)', () async {
      final claimedByOtherOrder = sampleActiveOrder.copyWith(
        id: 'ORD-CLAIMED',
        status: FlashOrderStatus.readyForPickup,
        selectedOffer: PharmacyOffer(
          id: 'OFFER-OTHER',
          pharmacyId: pharmaOtherId,
          pharmacyName: 'Autre Pharmacie',
          quarter: 'Poste Centrale',
          distanceKm: 0.9,
          phone: '123',
          availabilityType: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 2500,
          submittedAt: DateTime.now(),
        ),
      );
      final repo = PharmacistPortalRepositoryImpl(
        initialOrders: {claimedByOtherOrder.id: claimedByOtherOrder},
      );

      final result = await repo.submitQuote(
        orderId: claimedByOtherOrder.id,
        pharmacyId: pharmaSoleilId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2000,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<OrderAlreadyClaimedFailure>()),
        (_) => fail('Devrait échouer'),
      );
    });
  });

  group('PharmacistPortalRepositoryImpl - validateOtpAtCounter', () {
    test('valide avec succès le code OTP 6 chiffres et passe à delivered', () async {
      final result = await repository.validateOtpAtCounter(
        orderId: sampleOtpOrder.id,
        pharmacyId: pharmaSoleilId,
        otpCode: '123456',
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Devrait réussir'),
        (delivered) {
          expect(delivered.status, FlashOrderStatus.delivered);
          expect(delivered.isPickedUp, isTrue);
        },
      );
    });

    test('rejette un code OTP erroné (InvalidOtpFailure)', () async {
      final result = await repository.validateOtpAtCounter(
        orderId: sampleOtpOrder.id,
        pharmacyId: pharmaSoleilId,
        otpCode: '999999',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InvalidOtpFailure>()),
        (_) => fail('Devrait échouer'),
      );
    });

    test('rejette un code OTP de format invalide (!= 6 chiffres)', () async {
      final result = await repository.validateOtpAtCounter(
        orderId: sampleOtpOrder.id,
        pharmacyId: pharmaSoleilId,
        otpCode: '123',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InvalidOtpFailure>()),
        (_) => fail('Devrait échouer'),
      );
    });

    test('rejette un code déjà consommé / commande livrée (ConsumedOtpFailure)', () async {
      // D'abord on valide
      await repository.validateOtpAtCounter(
        orderId: sampleOtpOrder.id,
        pharmacyId: pharmaSoleilId,
        otpCode: '123456',
      );

      // On tente une seconde fois
      final secondAttempt = await repository.validateOtpAtCounter(
        orderId: sampleOtpOrder.id,
        pharmacyId: pharmaSoleilId,
        otpCode: '123456',
      );

      expect(secondAttempt.isLeft(), isTrue);
      secondAttempt.fold(
        (failure) => expect(failure, isA<ConsumedOtpFailure>()),
        (_) => fail('Devrait échouer'),
      );
    });

    test('rejette un code expiré > 2h (ExpiredOtpFailure)', () async {
      final expiredOrder = sampleOtpOrder.copyWith(
        id: 'ORD-EXPIRED-OTP',
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      final repo = PharmacistPortalRepositoryImpl(
        initialOrders: {expiredOrder.id: expiredOrder},
      );

      final result = await repo.validateOtpAtCounter(
        orderId: expiredOrder.id,
        pharmacyId: pharmaSoleilId,
        otpCode: '123456',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ExpiredOtpFailure>()),
        (_) => fail('Devrait échouer'),
      );
    });
  });
}
