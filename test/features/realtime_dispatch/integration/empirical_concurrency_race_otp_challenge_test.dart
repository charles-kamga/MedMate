import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pending_counter_orders.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_counter_otp.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/realtime_dispatch/domain/repositories/realtime_dispatch_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/escalate_dispatch_wave.dart';
import 'package:medmate/features/reservation/domain/usecases/select_pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/usecases/submit_flash_request.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockRealtimeDispatchRepository extends Mock
    implements RealtimeDispatchRepository {}

class MockSubmitFlashRequestUseCase extends Mock
    implements SubmitFlashRequestUseCase {}

class MockEscalateDispatchWaveUseCase extends Mock
    implements EscalateDispatchWaveUseCase {}

class MockSelectPharmacyOfferUseCase extends Mock
    implements SelectPharmacyOfferUseCase {}

void main() {
  const pharmacyAlphaId = 'pharma-alpha-warda';
  const pharmacyBetaId = 'pharma-beta-centre';

  const testMedication = Medication(
    id: 'med-parac-500',
    dci: 'Paracétamol',
    nomCommercial: 'Efferalgan 500mg',
    forme: 'Comprimé',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1200,
    necessiteOrdonnance: false,
  );

  const testBasketItem = BasketItem(
    id: 'item-race-1',
    medication: testMedication,
    quantity: 2,
  );

  const landmarkWarda = YaoundeLandmark(
    id: 'carrefour-warda',
    nom: 'Carrefour Warda',
    quartier: 'Poste Centrale',
    arrondissement: 'Yaoundé 1er',
    latitude: 3.8688,
    longitude: 11.5175,
    description: 'Face au Bois Sainte-Anastasie',
  );

  const targetAlpha = DispatchedPharmacy(
    id: pharmacyAlphaId,
    name: 'Pharmacie Alpha Warda',
    quarter: 'Carrefour Warda',
    distanceKm: 0.3,
    phone: '+237 677 00 00 01',
    waveIndex: 1,
  );

  const targetBeta = DispatchedPharmacy(
    id: pharmacyBetaId,
    name: 'Pharmacie Beta Centre',
    quarter: 'Poste Centrale',
    distanceKm: 0.8,
    phone: '+237 677 00 00 02',
    waveIndex: 1,
  );

  final competingOrder = FlashOrder(
    id: 'ORD-CONCURRENCY-999',
    items: const [testBasketItem],
    quarter: landmarkWarda.quartier,
    targets: const [targetAlpha, targetBeta],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
    status: FlashOrderStatus.dispatchingWave,
    currentWave: 1,
    waveTimeRemainingSeconds: 120,
  );

  setUpAll(() {
    registerFallbackValue(landmarkWarda);
    registerFallbackValue(competingOrder);
  });

  group('EMPIRICAL CHALLENGE 1: Concurrency Race Condition & Competitor Inbox Purge', () {
    late MockRealtimeDispatchRepository mockRepo;
    late StreamController<List<FlashOrder>> alphaInboxController;
    late StreamController<List<FlashOrder>> betaInboxController;
    late PharmacistPortalRepositoryImpl portalRepository;
    late GetPendingCounterOrdersUseCase getPendingUseCase;
    late SubmitCounterQuoteUseCase submitQuoteUseCase;
    late ValidateCounterOtpUseCase validateOtpUseCase;

    setUp(() {
      mockRepo = MockRealtimeDispatchRepository();
      alphaInboxController = StreamController<List<FlashOrder>>.broadcast();
      betaInboxController = StreamController<List<FlashOrder>>.broadcast();

      portalRepository = PharmacistPortalRepositoryImpl(
        initialOrders: {competingOrder.id: competingOrder},
      );
      getPendingUseCase = GetPendingCounterOrdersUseCase(portalRepository);
      submitQuoteUseCase = SubmitCounterQuoteUseCase(portalRepository);
      validateOtpUseCase = ValidateCounterOtpUseCase(portalRepository);

      when(() => mockRepo.watchPendingOrdersForPharmacy(pharmacyAlphaId))
          .thenAnswer((_) => alphaInboxController.stream);
      when(() => mockRepo.watchPendingOrdersForPharmacy(pharmacyBetaId))
          .thenAnswer((_) => betaInboxController.stream);
    });

    tearDown(() async {
      await alphaInboxController.close();
      await betaInboxController.close();
    });

    test('Two pharmacies receive the same wave order; when Beta claims it, Alpha inbox purges order & clears selection', () async {
      // 1. Initialisation des deux Cubits officine (Alpha et Beta)
      final cubitAlpha = PharmacistCounterCubit(
        getPendingOrders: getPendingUseCase,
        submitQuoteUseCase: submitQuoteUseCase,
        validateOtpUseCase: validateOtpUseCase,
        realtimeRepository: mockRepo,
        enableAutoRefresh: false,
      );

      final cubitBeta = PharmacistCounterCubit(
        getPendingOrders: getPendingUseCase,
        submitQuoteUseCase: submitQuoteUseCase,
        validateOtpUseCase: validateOtpUseCase,
        realtimeRepository: mockRepo,
        enableAutoRefresh: false,
      );

      // Charger les commandes initiales pour Alpha et Beta
      await cubitAlpha.loadPendingOrders(pharmacyAlphaId);
      await cubitBeta.loadPendingOrders(pharmacyBetaId);

      expect(cubitAlpha.state.orders.length, 1);
      expect(cubitBeta.state.orders.length, 1);
      expect(cubitAlpha.state.orders.first.id, competingOrder.id);
      expect(cubitBeta.state.orders.first.id, competingOrder.id);

      // 2. Les deux officines sélectionnent la commande pour préparer leur proposition
      cubitAlpha.selectOrder(competingOrder);
      cubitBeta.selectOrder(competingOrder);

      expect(cubitAlpha.state.selectedOrder?.id, competingOrder.id);
      expect(cubitBeta.state.selectedOrder?.id, competingOrder.id);

      // 3. Pharmacy Beta soumet son devis et remporte l'attribution
      final betaOffer = PharmacyOffer(
        id: 'OFFER-BETA',
        pharmacyId: pharmacyBetaId,
        pharmacyName: 'Pharmacie Beta Centre',
        quarter: 'Poste Centrale',
        distanceKm: 0.8,
        phone: '+237 677 00 00 02',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2100,
        submittedAt: DateTime.now(),
        isAccepted: true,
      );

      final claimedByBetaOrder = competingOrder.copyWith(
        status: FlashOrderStatus.accepted,
        selectedOffer: betaOffer,
      );

      // Mise à jour du store sous-jacent (simulant confirmation patient côté serveur)
      portalRepository = PharmacistPortalRepositoryImpl(
        initialOrders: {claimedByBetaOrder.id: claimedByBetaOrder},
      );
      final refreshedSubmitQuoteUseCase = SubmitCounterQuoteUseCase(portalRepository);

      // 4. Émission CDC temps réel vers les flux officines
      // Beta reçoit la confirmation que son offre est retenue
      betaInboxController.add([claimedByBetaOrder]);
      // Alpha reçoit l'ordre mis à jour (déjà accepté par Beta)
      alphaInboxController.add([claimedByBetaOrder]);
      await pumpEventQueue();

      // 5. VÉRIFICATION STRICTE DE PURGE CONCURRENTE :
      // Pharmacy Alpha doit avoir son inbox purgée de cette commande
      expect(cubitAlpha.state.orders.isEmpty, isTrue,
          reason: 'L’inbox du concurrent Alpha doit purger la commande attribuée à Beta',);
      expect(cubitAlpha.state.selectedOrder, isNull,
          reason: 'La sélection active de l’officine concurrente doit être immédiatement annulée',);
      expect(cubitAlpha.state.selectedOrderWaveRemainingSeconds, isNull,
          reason: 'Le compte à rebours de vague doit être invalidé et remis à null',);

      // Pharmacy Beta voit toujours sa commande confirmée
      expect(cubitBeta.state.orders.length, 1);
      expect(cubitBeta.state.orders.first.selectedOffer?.pharmacyId, pharmacyBetaId);

      // 6. Tentative tardive de soumission par Alpha -> rejet avec OrderAlreadyClaimedFailure
      final lateSubmissionResult = await refreshedSubmitQuoteUseCase(
        orderId: competingOrder.id,
        pharmacyId: pharmacyAlphaId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
      );

      expect(lateSubmissionResult.isLeft(), isTrue);
      lateSubmissionResult.fold(
        (failure) => expect(failure, isA<OrderAlreadyClaimedFailure>()),
        (_) => fail('Alpha aurait dû être rejeté car la commande est déjà attribuée à Beta'),
      );

      await cubitAlpha.close();
      await cubitBeta.close();
    });
  });

  group('EMPIRICAL CHALLENGE 2: Wave Escalation & Wave Deadline Expiry', () {
    late MockRealtimeDispatchRepository mockRepo;
    late MockSubmitFlashRequestUseCase mockSubmitFlash;
    late MockEscalateDispatchWaveUseCase mockEscalateWave;
    late MockSelectPharmacyOfferUseCase mockSelectOffer;

    setUp(() {
      mockRepo = MockRealtimeDispatchRepository();
      mockSubmitFlash = MockSubmitFlashRequestUseCase();
      mockEscalateWave = MockEscalateDispatchWaveUseCase();
      mockSelectOffer = MockSelectPharmacyOfferUseCase();

      when(() => mockRepo.watchOffersForOrder(any()))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockRepo.watchFlashOrder(any()))
          .thenAnswer((_) => const Stream.empty());
    });

    test('FlashReservationCubit automatically triggers wave escalation at deadline when no offers selected', () async {
      when(() => mockSubmitFlash(
            items: any(named: 'items'),
            landmark: any(named: 'landmark'),
          ),).thenAnswer((_) async => Right(competingOrder));

      final escalatedWaveOrder = competingOrder.copyWith(
        currentWave: 2,
        targets: [
          ...competingOrder.targets,
          const DispatchedPharmacy(
            id: 'pharma-gamma-obili',
            name: 'Pharmacie Gamma Obili',
            quarter: 'Carrefour Obili',
            distanceKm: 1.5,
            phone: '+237 677 00 00 03',
            waveIndex: 2,
          ),
        ],
      );

      when(() => mockEscalateWave(competingOrder.id))
          .thenAnswer((_) async => Right(escalatedWaveOrder));

      final cubit = FlashReservationCubit(
        submitFlashRequestUseCase: mockSubmitFlash,
        escalateDispatchWaveUseCase: mockEscalateWave,
        selectPharmacyOfferUseCase: mockSelectOffer,
        reservationRepository: mockRepo,
        realtimeRepository: mockRepo,
        enableAutoEscalation: true,
        autoEscalationDuration: const Duration(milliseconds: 50),
      )
        ..addItem(testMedication, quantity: 2)
        ..selectLandmark(landmarkWarda);

      await cubit.submitFlashRequest();
      expect(cubit.state.currentOrder?.currentWave, 1);

      // Attente du déclenchement du timer automatique
      await Future<void>.delayed(const Duration(milliseconds: 90));

      verify(() => mockEscalateWave(competingOrder.id)).called(1);
      expect(cubit.state.currentOrder?.currentWave, 2);
      expect(cubit.state.currentOrder?.targets.length, 3);

      await cubit.close();
    });

    test('Submission of quote past the wave deadline is rejected with WaveExpiredFailure', () async {
      final expiredWaveOrder = competingOrder.copyWith(
        waveTimeRemainingSeconds: 0,
      );

      final portalRepo = PharmacistPortalRepositoryImpl(
        initialOrders: {expiredWaveOrder.id: expiredWaveOrder},
      );
      final submitQuote = SubmitCounterQuoteUseCase(portalRepo);

      final result = await submitQuote(
        orderId: expiredWaveOrder.id,
        pharmacyId: pharmacyAlphaId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2200,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) {
          expect(failure, isA<WaveExpiredFailure>());
          expect(failure.message, contains('2 minutes'));
        },
        (_) => fail('Le devis hors délai de vague aurait dû être rejeté'),
      );
    });
  });

  group('EMPIRICAL CHALLENGE 3: OTP Full Lifecycle Testing', () {
    late PharmacistPortalRepositoryImpl repository;
    late ValidateCounterOtpUseCase validateOtpUseCase;

    const validOtp = '739201';

    final readyOrder = competingOrder.copyWith(
      id: 'ORD-OTP-LIFECYCLE',
      status: FlashOrderStatus.readyForPickup,
      reservationOtpCode: validOtp,
      phoneNumber: '+237 690 00 11 22',
      expiresAt: DateTime.now().add(const Duration(hours: 1, minutes: 50)),
      selectedOffer: PharmacyOffer(
        id: 'OFFER-WINNER',
        pharmacyId: pharmacyAlphaId,
        pharmacyName: 'Pharmacie Alpha Warda',
        quarter: 'Carrefour Warda',
        distanceKm: 0.3,
        phone: '+237 677 00 00 01',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
        submittedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        isAccepted: true,
      ),
    );

    setUp(() {
      repository = PharmacistPortalRepositoryImpl(
        initialOrders: {readyOrder.id: readyOrder},
      );
      validateOtpUseCase = ValidateCounterOtpUseCase(repository);
    });

    test('1. Valid OTP code -> Success: order transitions to delivered & isPickedUp', () async {
      final result = await validateOtpUseCase(
        orderId: readyOrder.id,
        pharmacyId: pharmacyAlphaId,
        otpCode: validOtp,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Validation OTP valide devrait réussir'),
        (delivered) {
          expect(delivered.status, FlashOrderStatus.delivered);
          expect(delivered.isPickedUp, isTrue);
        },
      );
    });

    test('2. Wrong OTP code -> Failure: InvalidOtpFailure', () async {
      final result = await validateOtpUseCase(
        orderId: readyOrder.id,
        pharmacyId: pharmacyAlphaId,
        otpCode: '000000',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InvalidOtpFailure>()),
        (_) => fail('Validation avec code erroné aurait dû échouer'),
      );
    });

    test('3. Malformed OTP code (!= 6 digits) -> Failure: InvalidOtpFailure', () async {
      final result = await validateOtpUseCase(
        orderId: readyOrder.id,
        pharmacyId: pharmacyAlphaId,
        otpCode: '12',
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<InvalidOtpFailure>()),
        (_) => fail('Code non-conforme aurait dû échouer'),
      );
    });

    test('4. Expired OTP code (> 2h TTL) -> Failure: ExpiredOtpFailure', () async {
      final expiredOtpOrder = FlashOrder(
        id: 'ORD-EXPIRED-OTP',
        items: readyOrder.items,
        quarter: readyOrder.quarter,
        targets: readyOrder.targets,
        currentWave: readyOrder.currentWave,
        waveTimeRemainingSeconds: 0,
        status: FlashOrderStatus.readyForPickup,
        reservationOtpCode: validOtp,
        phoneNumber: readyOrder.phoneNumber,
        selectedOffer: readyOrder.selectedOffer,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      final repo = PharmacistPortalRepositoryImpl(
        initialOrders: {expiredOtpOrder.id: expiredOtpOrder},
      );
      final useCase = ValidateCounterOtpUseCase(repo);

      final result = await useCase(
        orderId: expiredOtpOrder.id,
        pharmacyId: pharmacyAlphaId,
        otpCode: validOtp,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ExpiredOtpFailure>()),
        (_) => fail('Validation code expiré aurait dû échouer'),
      );
    });

    test('5. Already consumed OTP code -> Failure: ConsumedOtpFailure', () async {
      // Première validation réussie
      final firstRes = await validateOtpUseCase(
        orderId: readyOrder.id,
        pharmacyId: pharmacyAlphaId,
        otpCode: validOtp,
      );
      expect(firstRes.isRight(), isTrue);

      // Seconde tentative de validation du même code
      final secondRes = await validateOtpUseCase(
        orderId: readyOrder.id,
        pharmacyId: pharmacyAlphaId,
        otpCode: validOtp,
      );

      expect(secondRes.isLeft(), isTrue);
      secondRes.fold(
        (failure) => expect(failure, isA<ConsumedOtpFailure>()),
        (_) => fail('Validation sur commande déjà délivrée aurait dû échouer'),
      );
    });
  });
}
