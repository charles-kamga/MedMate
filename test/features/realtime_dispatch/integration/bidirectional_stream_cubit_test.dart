import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pending_counter_orders.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_counter_otp.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/realtime_dispatch/domain/repositories/realtime_dispatch_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/escalate_dispatch_wave.dart';
import 'package:medmate/features/reservation/domain/usecases/select_pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/usecases/submit_flash_request.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';
import 'package:mocktail/mocktail.dart';

class MockRealtimeDispatchRepository extends Mock
    implements RealtimeDispatchRepository {}

class MockSubmitFlashRequestUseCase extends Mock
    implements SubmitFlashRequestUseCase {}

class MockEscalateDispatchWaveUseCase extends Mock
    implements EscalateDispatchWaveUseCase {}

class MockSelectPharmacyOfferUseCase extends Mock
    implements SelectPharmacyOfferUseCase {}

class MockGetPendingCounterOrdersUseCase extends Mock
    implements GetPendingCounterOrdersUseCase {}

class MockSubmitCounterQuoteUseCase extends Mock
    implements SubmitCounterQuoteUseCase {}

class MockValidateCounterOtpUseCase extends Mock
    implements ValidateCounterOtpUseCase {}

void main() {
  late MockRealtimeDispatchRepository mockRepo;
  late MockSubmitFlashRequestUseCase mockSubmitFlash;
  late MockEscalateDispatchWaveUseCase mockEscalateWave;
  late MockSelectPharmacyOfferUseCase mockSelectOffer;
  late MockGetPendingCounterOrdersUseCase mockGetPendingOrders;
  late MockSubmitCounterQuoteUseCase mockSubmitQuote;
  late MockValidateCounterOtpUseCase mockValidateOtp;

  late StreamController<List<PharmacyOffer>> offersController;
  late StreamController<FlashOrder> orderController;
  late StreamController<List<FlashOrder>> pendingOrdersController;

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

  const sampleItem = BasketItem(
    id: 'item-1',
    medication: sampleMedication,
    quantity: 2,
  );

  const sampleLandmark = YaoundeLandmark(
    id: 'carrefour-warda',
    nom: 'Carrefour Warda',
    quartier: 'Poste Centrale',
    arrondissement: 'Yaoundé 1er',
    latitude: 3.8688,
    longitude: 11.5175,
    description: 'Face au Bois Sainte-Anastasie',
  );

  final baseOrder = FlashOrder(
    id: 'ORD-TEST-1',
    items: const [sampleItem],
    quarter: sampleLandmark.quartier,
    targets: const [
      DispatchedPharmacy(
        id: 'pharma-soleil',
        name: 'Pharmacie du Soleil',
        quarter: 'Carrefour Warda',
        distanceKm: 0.3,
        phone: '+237 677 00 00 01',
        waveIndex: 1,
      ),
    ],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
    status: FlashOrderStatus.dispatchingWave,
    currentWave: 1,
  );

  setUpAll(() {
    registerFallbackValue(sampleLandmark);
    registerFallbackValue(PharmacyAvailabilityType.fullyAvailable);
    registerFallbackValue(baseOrder);
  });

  setUp(() {
    mockRepo = MockRealtimeDispatchRepository();
    mockSubmitFlash = MockSubmitFlashRequestUseCase();
    mockEscalateWave = MockEscalateDispatchWaveUseCase();
    mockSelectOffer = MockSelectPharmacyOfferUseCase();
    mockGetPendingOrders = MockGetPendingCounterOrdersUseCase();
    mockSubmitQuote = MockSubmitCounterQuoteUseCase();
    mockValidateOtp = MockValidateCounterOtpUseCase();

    offersController = StreamController<List<PharmacyOffer>>.broadcast();
    orderController = StreamController<FlashOrder>.broadcast();
    pendingOrdersController = StreamController<List<FlashOrder>>.broadcast();

    when(() => mockRepo.watchOffersForOrder(any()))
        .thenAnswer((_) => offersController.stream);
    when(() => mockRepo.watchFlashOrder(any()))
        .thenAnswer((_) => orderController.stream);
    when(() => mockRepo.watchPendingOrdersForPharmacy(any()))
        .thenAnswer((_) => pendingOrdersController.stream);
  });

  tearDown(() async {
    await offersController.close();
    await orderController.close();
    await pendingOrdersController.close();
  });

  group('FlashReservationCubit — Flux Temps Réel Patient', () {
    test("1. Réception instantanée d'un devis officine via stream réactif",
        () async {
      when(() => mockSubmitFlash(
            items: any(named: 'items'),
            landmark: any(named: 'landmark'),
          ),).thenAnswer((_) async => Right(baseOrder));

      final patientCubit = FlashReservationCubit(
        submitFlashRequestUseCase: mockSubmitFlash,
        escalateDispatchWaveUseCase: mockEscalateWave,
        selectPharmacyOfferUseCase: mockSelectOffer,
        reservationRepository: mockRepo,
        realtimeRepository: mockRepo,
        enableAutoEscalation: false,
      )
        ..addItem(sampleMedication, quantity: 2)
        ..selectLandmark(sampleLandmark);

      await patientCubit.submitFlashRequest();
      expect(patientCubit.state.status, FlashReservationStatus.waveActive);
      expect(patientCubit.state.currentOrder?.offers.isEmpty, isTrue);

      final incomingQuote = PharmacyOffer(
        id: 'quote-pharma-soleil',
        pharmacyId: 'pharma-soleil',
        pharmacyName: 'Pharmacie du Soleil',
        quarter: 'Carrefour Warda',
        distanceKm: 0.3,
        phone: '+237 677 00 00 01',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
        submittedAt: DateTime.now(),
      );

      // Émission instantanée du devis par le WebSocket CDC
      offersController.add([incomingQuote]);
      await pumpEventQueue();

      expect(patientCubit.state.status, FlashReservationStatus.offersReceived);
      expect(patientCubit.state.currentOrder?.offers.length, 1);
      expect(patientCubit.state.currentOrder?.offers.first.quotedPriceCfa, 2400);

      await patientCubit.close();
    });

    test("2. Escalade automatique de vague à l'expiration du délai (2 min)",
        () async {
      when(() => mockSubmitFlash(
            items: any(named: 'items'),
            landmark: any(named: 'landmark'),
          ),).thenAnswer((_) async => Right(baseOrder));

      final wave2Order = baseOrder.copyWith(
        currentWave: 2,
        targets: [
          ...baseOrder.targets,
          const DispatchedPharmacy(
            id: 'pharma-obili',
            name: "Pharmacie d'Obili",
            quarter: 'Carrefour Obili',
            distanceKm: 1.2,
            phone: '+237 677 00 00 02',
            waveIndex: 2,
          ),
        ],
      );

      when(() => mockEscalateWave(baseOrder.id))
          .thenAnswer((_) async => Right(wave2Order));

      final patientCubit = FlashReservationCubit(
        submitFlashRequestUseCase: mockSubmitFlash,
        escalateDispatchWaveUseCase: mockEscalateWave,
        selectPharmacyOfferUseCase: mockSelectOffer,
        reservationRepository: mockRepo,
        realtimeRepository: mockRepo,
        enableAutoEscalation: true,
        autoEscalationDuration: const Duration(milliseconds: 60),
      )
        ..addItem(sampleMedication, quantity: 2)
        ..selectLandmark(sampleLandmark);

      await patientCubit.submitFlashRequest();
      expect(patientCubit.state.currentOrder?.currentWave, 1);

      // Attente du déclenchement du timer d'escalade
      await Future<void>.delayed(const Duration(milliseconds: 100));

      verify(() => mockEscalateWave(baseOrder.id)).called(1);
      expect(patientCubit.state.currentOrder?.currentWave, 2);
      expect(patientCubit.state.currentOrder?.targets.length, 2);

      await patientCubit.close();
    });

    test('3. Notification temps réel de confirmation / délivrance', () async {
      when(() => mockSubmitFlash(
            items: any(named: 'items'),
            landmark: any(named: 'landmark'),
          ),).thenAnswer((_) async => Right(baseOrder));

      final patientCubit = FlashReservationCubit(
        submitFlashRequestUseCase: mockSubmitFlash,
        escalateDispatchWaveUseCase: mockEscalateWave,
        selectPharmacyOfferUseCase: mockSelectOffer,
        reservationRepository: mockRepo,
        realtimeRepository: mockRepo,
      )
        ..addItem(sampleMedication, quantity: 2)
        ..selectLandmark(sampleLandmark);
      await patientCubit.submitFlashRequest();

      // Notification de commande prête
      orderController.add(baseOrder.copyWith(
        status: FlashOrderStatus.readyForPickup,
      ),);
      await pumpEventQueue();

      expect(patientCubit.state.hasRealtimeNotification, isTrue);
      expect(
        patientCubit.state.realtimeNotification,
        contains('prête à être retirée'),
      );

      // Notification de délivrance finale
      orderController.add(baseOrder.copyWith(
        status: FlashOrderStatus.delivered,
        isPickedUp: true,
      ),);
      await pumpEventQueue();

      expect(
        patientCubit.state.realtimeNotification,
        contains('délivrée et clôturée'),
      );

      await patientCubit.close();
    });
  });

  group('PharmacistCounterCubit — Flux Temps Réel Officine & Résolution de Concurrence', () {
    test("4. Arrivée instantanée d'une nouvelle demande avec signalement discret",
        () async {
      when(() => mockGetPendingOrders('pharma-soleil'))
          .thenAnswer((_) async => const Right([]));

      final counterCubit = PharmacistCounterCubit(
        getPendingOrders: mockGetPendingOrders,
        submitQuoteUseCase: mockSubmitQuote,
        validateOtpUseCase: mockValidateOtp,
        realtimeRepository: mockRepo,
        enableAutoRefresh: false,
      );

      await counterCubit.loadPendingOrders('pharma-soleil');
      expect(counterCubit.state.orders.isEmpty, isTrue);
      expect(counterCubit.state.hasNewOrderAlert, isFalse);
      expect(counterCubit.state.newOrdersCount, 0);

      // Émission d'une nouvelle commande dans le flux WebSocket
      pendingOrdersController.add([baseOrder]);
      await pumpEventQueue();

      expect(counterCubit.state.orders.length, 1);
      expect(counterCubit.state.orders.first.id, baseOrder.id);
      expect(counterCubit.state.hasNewOrderAlert, isTrue);
      expect(counterCubit.state.newOrdersCount, 1);

      // Effacement du signalement discret par l'action du pharmacien
      counterCubit.clearNewOrderAlert();
      expect(counterCubit.state.hasNewOrderAlert, isFalse);
      expect(counterCubit.state.newOrdersCount, 0);

      await counterCubit.close();
    });

    test("5. Retrait immédiat d'une commande dès prise par un confrère (Stop the race)",
        () async {
      when(() => mockGetPendingOrders('pharma-soleil'))
          .thenAnswer((_) async => Right([baseOrder]));

      final counterCubit = PharmacistCounterCubit(
        getPendingOrders: mockGetPendingOrders,
        submitQuoteUseCase: mockSubmitQuote,
        validateOtpUseCase: mockValidateOtp,
        realtimeRepository: mockRepo,
        enableAutoRefresh: false,
      );

      await counterCubit.loadPendingOrders('pharma-soleil');
      counterCubit.selectOrder(baseOrder);

      expect(counterCubit.state.orders.length, 1);
      expect(counterCubit.state.selectedOrder?.id, baseOrder.id);

      // Un confrère concurrent accepte et remporte l'offre
      final competitorOffer = PharmacyOffer(
        id: 'quote-competitor',
        pharmacyId: 'pharma-centre-concurrent',
        pharmacyName: 'Grande Pharmacie du Centre',
        quarter: 'Poste Centrale',
        distanceKm: 0.5,
        phone: '+237 677 99 99 99',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2200,
        submittedAt: DateTime.now(),
      );

      final claimedByCompetitorOrder = baseOrder.copyWith(
        selectedOffer: competitorOffer,
        status: FlashOrderStatus.accepted,
      );

      // Notification en temps réel de l'attribution au confrère
      pendingOrdersController.add([claimedByCompetitorOrder]);
      await pumpEventQueue();

      // La commande est instantanément retirée de l'inbox et désélectionnée
      expect(counterCubit.state.orders.isEmpty, isTrue);
      expect(counterCubit.state.selectedOrder, isNull);
      expect(counterCubit.state.selectedOrderWaveRemainingSeconds, isNull);

      await counterCubit.close();
    });
  });
}
