import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pending_counter_orders.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_counter_otp.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetPendingCounterOrdersUseCase extends Mock
    implements GetPendingCounterOrdersUseCase {}

class MockSubmitCounterQuoteUseCase extends Mock
    implements SubmitCounterQuoteUseCase {}

class MockValidateCounterOtpUseCase extends Mock
    implements ValidateCounterOtpUseCase {}

void main() {
  late MockGetPendingCounterOrdersUseCase mockGetPendingOrders;
  late MockSubmitCounterQuoteUseCase mockSubmitQuoteUseCase;
  late MockValidateCounterOtpUseCase mockValidateOtpUseCase;
  late PharmacistCounterCubit cubit;

  const testPharmacyId = 'pharma-soleil';

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

  const testDispatchedPharma = DispatchedPharmacy(
    id: testPharmacyId,
    name: 'Pharmacie du Soleil',
    quarter: 'Carrefour Warda',
    distanceKm: 0.4,
    phone: '+237 677 12 34 56',
    waveIndex: 1,
    status: PharmacistReplyType.waiting,
  );

  final testOrder1 = FlashOrder(
    id: 'ORD-101',
    items: const [
      BasketItem(id: 'item-1', medication: testMedication, quantity: 2),
    ],
    quarter: 'Carrefour Warda, Poste Centrale',
    targets: const [testDispatchedPharma],
    currentWave: 1,
    waveTimeRemainingSeconds: 90,
    status: FlashOrderStatus.dispatchingWave,
    createdAt: DateTime(2026, 11, 10, 8, 0),
    expiresAt: DateTime(2026, 11, 10, 10, 0),
  );

  final testOfferAvailable = PharmacyOffer(
    id: 'OFFER-101-pharma-soleil',
    pharmacyId: testPharmacyId,
    pharmacyName: 'Pharmacie du Soleil',
    quarter: 'Carrefour Warda',
    distanceKm: 0.4,
    phone: '+237 677 12 34 56',
    availabilityType: PharmacyAvailabilityType.fullyAvailable,
    quotedPriceCfa: 2400,
    submittedAt: DateTime(2026, 11, 10, 8, 1),
  );

  final testOfferConditional = PharmacyOffer(
    id: 'OFFER-101-cond',
    pharmacyId: testPharmacyId,
    pharmacyName: 'Pharmacie du Soleil',
    quarter: 'Carrefour Warda',
    distanceKm: 0.4,
    phone: '+237 677 12 34 56',
    availabilityType: PharmacyAvailabilityType.conditional,
    quotedPriceCfa: 3000,
    conditionRequirements: const ['Ordonnance originale requise'],
    conditionNote: 'Vérification obligatoire au comptoir',
    submittedAt: DateTime(2026, 11, 10, 8, 1),
  );

  final testOfferUnavailable = PharmacyOffer(
    id: 'OFFER-101-unavail',
    pharmacyId: testPharmacyId,
    pharmacyName: 'Pharmacie du Soleil',
    quarter: 'Carrefour Warda',
    distanceKm: 0.4,
    phone: '+237 677 12 34 56',
    availabilityType: PharmacyAvailabilityType.unavailable,
    quotedPriceCfa: 0,
    conditionNote: 'Rupture nationale',
    submittedAt: DateTime(2026, 11, 10, 8, 1),
  );

  setUp(() {
    mockGetPendingOrders = MockGetPendingCounterOrdersUseCase();
    mockSubmitQuoteUseCase = MockSubmitCounterQuoteUseCase();
    mockValidateOtpUseCase = MockValidateCounterOtpUseCase();

    cubit = PharmacistCounterCubit(
      getPendingOrders: mockGetPendingOrders,
      submitQuoteUseCase: mockSubmitQuoteUseCase,
      validateOtpUseCase: mockValidateOtpUseCase,
      enableAutoRefresh: false,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('PharmacistCounterCubit - Initial State', () {
    test('a un état initial correct', () {
      expect(cubit.state.status, PharmacistCounterStatus.initial);
      expect(cubit.state.orders, isEmpty);
      expect(cubit.state.selectedOrder, isNull);
      expect(cubit.state.isInitial, isTrue);
    });
  });

  group('PharmacistCounterCubit - loadPendingOrders', () {
    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      'émet [loading, loaded] lors d’un chargement réussi',
      build: () {
        when(() => mockGetPendingOrders(testPharmacyId)).thenAnswer(
          (_) async => Right([testOrder1]),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadPendingOrders(testPharmacyId),
      expect: () => [
        const PharmacistCounterState(status: PharmacistCounterStatus.loading),
        PharmacistCounterState(
          status: PharmacistCounterStatus.loaded,
          orders: [testOrder1],
        ),
      ],
      verify: (_) {
        verify(() => mockGetPendingOrders(testPharmacyId)).called(1);
      },
    );

    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      'émet [loading, failure] en cas d’échec du repository',
      build: () {
        when(() => mockGetPendingOrders(testPharmacyId)).thenAnswer(
          (_) async => const Left(ServerFailure('Erreur réseau')),
        );
        return cubit;
      },
      act: (cubit) => cubit.loadPendingOrders(testPharmacyId),
      expect: () => [
        const PharmacistCounterState(status: PharmacistCounterStatus.loading),
        const PharmacistCounterState(
          status: PharmacistCounterStatus.failure,
          errorMessage: 'Erreur réseau',
          failure: ServerFailure('Erreur réseau'),
        ),
      ],
    );
  });

  group('PharmacistCounterCubit - Émission de devis (3 statuts ONPC)', () {
    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '1. fullyAvailable : émet [submittingQuote, quoteSubmitted] avec montant',
      seed: () => PharmacistCounterState(
        status: PharmacistCounterStatus.loaded,
        orders: [testOrder1],
        selectedOrder: testOrder1,
      ),
      build: () {
        when(() => mockSubmitQuoteUseCase(
              orderId: testOrder1.id,
              pharmacyId: testPharmacyId,
              availability: PharmacyAvailabilityType.fullyAvailable,
              quotedPriceCfa: 2400,
              conditionRequirements: any(named: 'conditionRequirements'),
              conditionNote: any(named: 'conditionNote'),
              proposesDelivery: any(named: 'proposesDelivery'),
              deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
              estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
            ),).thenAnswer((_) async => Right(testOfferAvailable));
        return cubit;
      },
      act: (cubit) => cubit.submitQuote(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
      ),
      expect: () => [
        PharmacistCounterState(
          status: PharmacistCounterStatus.submittingQuote,
          orders: [testOrder1],
          selectedOrder: testOrder1,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.quoteSubmitted &&
              state.lastSubmittedQuote == testOfferAvailable &&
              state.successMessage != null;
        }),
      ],
    );

    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '2. conditional : émet [submittingQuote, quoteSubmitted] avec note et conditions',
      seed: () => PharmacistCounterState(
        status: PharmacistCounterStatus.loaded,
        orders: [testOrder1],
        selectedOrder: testOrder1,
      ),
      build: () {
        when(() => mockSubmitQuoteUseCase(
              orderId: testOrder1.id,
              pharmacyId: testPharmacyId,
              availability: PharmacyAvailabilityType.conditional,
              quotedPriceCfa: 3000,
              conditionRequirements: ['Ordonnance originale requise'],
              conditionNote: 'Vérification obligatoire au comptoir',
              proposesDelivery: false,
              deliveryFeeCfa: 0,
              estimatedDeliveryMinutes: null,
            ),).thenAnswer((_) async => Right(testOfferConditional));
        return cubit;
      },
      act: (cubit) => cubit.submitQuote(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        availability: PharmacyAvailabilityType.conditional,
        quotedPriceCfa: 3000,
        conditionRequirements: const ['Ordonnance originale requise'],
        conditionNote: 'Vérification obligatoire au comptoir',
      ),
      expect: () => [
        PharmacistCounterState(
          status: PharmacistCounterStatus.submittingQuote,
          orders: [testOrder1],
          selectedOrder: testOrder1,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.quoteSubmitted &&
              state.lastSubmittedQuote == testOfferConditional &&
              (state.lastSubmittedQuote?.conditionRequirements.isNotEmpty ?? false);
        }),
      ],
    );

    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '3. unavailable : émet [submittingQuote, quoteSubmitted] avec prix 0 et motif',
      seed: () => PharmacistCounterState(
        status: PharmacistCounterStatus.loaded,
        orders: [testOrder1],
        selectedOrder: testOrder1,
      ),
      build: () {
        when(() => mockSubmitQuoteUseCase(
              orderId: testOrder1.id,
              pharmacyId: testPharmacyId,
              availability: PharmacyAvailabilityType.unavailable,
              quotedPriceCfa: 0,
              conditionRequirements: any(named: 'conditionRequirements'),
              conditionNote: 'Rupture nationale',
              proposesDelivery: any(named: 'proposesDelivery'),
              deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
              estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
            ),).thenAnswer((_) async => Right(testOfferUnavailable));
        return cubit;
      },
      act: (cubit) => cubit.submitQuote(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        availability: PharmacyAvailabilityType.unavailable,
        quotedPriceCfa: 0,
        conditionNote: 'Rupture nationale',
      ),
      expect: () => [
        PharmacistCounterState(
          status: PharmacistCounterStatus.submittingQuote,
          orders: [testOrder1],
          selectedOrder: testOrder1,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.quoteSubmitted &&
              state.lastSubmittedQuote?.availabilityType ==
                  PharmacyAvailabilityType.unavailable;
        }),
      ],
    );
  });

  group('PharmacistCounterCubit - Utilitaires UI et sélection', () {
    test('selectOrder met à jour la commande et le temps de vague', () {
      cubit.selectOrder(testOrder1);
      expect(cubit.state.selectedOrder, testOrder1);
      expect(cubit.state.selectedOrderWaveRemainingSeconds, 90);

      cubit.tickCountdown(10);
      expect(cubit.state.selectedOrderWaveRemainingSeconds, 80);

      cubit.selectOrder(null);
      expect(cubit.state.selectedOrder, isNull);
      expect(cubit.state.selectedOrderWaveRemainingSeconds, isNull);
    });

    test('clearFeedback réinitialise statut et messages', () {
      cubit
        ..emit(
          const PharmacistCounterState(
            status: PharmacistCounterStatus.failure,
            errorMessage: 'Erreur',
          ),
        )
        ..clearFeedback();
      expect(cubit.state.status, PharmacistCounterStatus.loaded);
      expect(cubit.state.errorMessage, isNull);
    });

    test('setFilterStatus filtre correctement la liste', () {
      cubit
        ..emit(
          PharmacistCounterState(
            status: PharmacistCounterStatus.loaded,
            orders: [
              testOrder1,
              testOrder1.copyWith(
                id: 'ORD-READY',
                status: FlashOrderStatus.readyForPickup,
              ),
            ],
          ),
        )
        ..setFilterStatus('readyForPickup');
      expect(cubit.state.filteredOrders.length, 1);
      expect(cubit.state.filteredOrders.first.id, 'ORD-READY');

      cubit.setFilterStatus(null);
      expect(cubit.state.filteredOrders.length, 2);
    });
  });
}
