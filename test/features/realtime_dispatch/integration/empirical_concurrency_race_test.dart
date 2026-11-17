import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pending_counter_orders.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_counter_otp.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/realtime_dispatch/domain/repositories/realtime_dispatch_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRealtimeDispatchRepository extends Mock
    implements RealtimeDispatchRepository {}

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

  group(
    'EMPIRICAL CHALLENGE 1: Concurrency Race Condition & Competitor Inbox Purge',
    () {
      late _MockRealtimeDispatchRepository mockRepo;
      late StreamController<List<FlashOrder>> alphaInboxController;
      late StreamController<List<FlashOrder>> betaInboxController;
      late PharmacistPortalRepositoryImpl portalRepository;
      late GetPendingCounterOrdersUseCase getPendingUseCase;
      late SubmitCounterQuoteUseCase submitQuoteUseCase;
      late ValidateCounterOtpUseCase validateOtpUseCase;

      setUp(() {
        mockRepo = _MockRealtimeDispatchRepository();
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

      test(
        'Two pharmacies receive the same wave order; when Beta claims it, Alpha inbox purges order & clears selection',
        () async {
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

          await cubitAlpha.loadPendingOrders(pharmacyAlphaId);
          await cubitBeta.loadPendingOrders(pharmacyBetaId);

          expect(cubitAlpha.state.orders.length, 1);
          expect(cubitBeta.state.orders.length, 1);
          expect(cubitAlpha.state.orders.first.id, competingOrder.id);
          expect(cubitBeta.state.orders.first.id, competingOrder.id);

          cubitAlpha.selectOrder(competingOrder);
          cubitBeta.selectOrder(competingOrder);

          expect(cubitAlpha.state.selectedOrder?.id, competingOrder.id);
          expect(cubitBeta.state.selectedOrder?.id, competingOrder.id);

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

          portalRepository = PharmacistPortalRepositoryImpl(
            initialOrders: {claimedByBetaOrder.id: claimedByBetaOrder},
          );
          final refreshedSubmitQuoteUseCase =
              SubmitCounterQuoteUseCase(portalRepository);

          betaInboxController.add([claimedByBetaOrder]);
          alphaInboxController.add([claimedByBetaOrder]);
          await pumpEventQueue();

          expect(
            cubitAlpha.state.orders.isEmpty,
            isTrue,
            reason:
                'L’inbox du concurrent Alpha doit purger la commande attribuée à Beta',
          );
          expect(
            cubitAlpha.state.selectedOrder,
            isNull,
            reason:
                'La sélection active de l’officine concurrente doit être immédiatement annulée',
          );
          expect(
            cubitAlpha.state.selectedOrderWaveRemainingSeconds,
            isNull,
            reason:
                'Le compte à rebours de vague doit être invalidé et remis à null',
          );

          expect(cubitBeta.state.orders.length, 1);
          expect(
            cubitBeta.state.orders.first.selectedOffer?.pharmacyId,
            pharmacyBetaId,
          );

          final lateSubmissionResult = await refreshedSubmitQuoteUseCase(
            orderId: competingOrder.id,
            pharmacyId: pharmacyAlphaId,
            availability: PharmacyAvailabilityType.fullyAvailable,
            quotedPriceCfa: 2400,
          );

          expect(lateSubmissionResult.isLeft(), isTrue);
          lateSubmissionResult.fold(
            (failure) => expect(failure, isA<OrderAlreadyClaimedFailure>()),
            (_) => fail(
              'Alpha aurait dû être rejeté car la commande est déjà attribuée à Beta',
            ),
          );

          await cubitAlpha.close();
          await cubitBeta.close();
        },
      );
    },
  );
}
