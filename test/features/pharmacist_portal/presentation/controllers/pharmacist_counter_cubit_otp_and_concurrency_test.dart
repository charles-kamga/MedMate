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

  final testDeliveredOrder = testOrder1.copyWith(
    status: FlashOrderStatus.delivered,
    isPickedUp: true,
  );

  setUpAll(() {
    registerFallbackValue(PharmacyAvailabilityType.fullyAvailable);
  });

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

  group('PharmacistCounterCubit - Concurrence et conflits réseau', () {
    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '1. OrderAlreadyClaimedFailure : état d’erreur avec message clair',
      build: () {
        when(() => mockSubmitQuoteUseCase(
              orderId: any(named: 'orderId'),
              pharmacyId: any(named: 'pharmacyId'),
              availability: any(named: 'availability'),
              quotedPriceCfa: any(named: 'quotedPriceCfa'),
              conditionRequirements: any(named: 'conditionRequirements'),
              conditionNote: any(named: 'conditionNote'),
              proposesDelivery: any(named: 'proposesDelivery'),
              deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
              estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
            ),).thenAnswer((_) async => const Left(OrderAlreadyClaimedFailure()));
        return cubit;
      },
      act: (cubit) => cubit.submitQuote(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2500,
      ),
      expect: () => [
        const PharmacistCounterState(
          status: PharmacistCounterStatus.submittingQuote,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.failure &&
              state.failure is OrderAlreadyClaimedFailure &&
              state.errorMessage!.contains('déjà été acceptée');
        }),
      ],
    );

    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '2. WaveExpiredFailure : état d’erreur signalant l’expiration de la vague',
      build: () {
        when(() => mockSubmitQuoteUseCase(
              orderId: any(named: 'orderId'),
              pharmacyId: any(named: 'pharmacyId'),
              availability: any(named: 'availability'),
              quotedPriceCfa: any(named: 'quotedPriceCfa'),
              conditionRequirements: any(named: 'conditionRequirements'),
              conditionNote: any(named: 'conditionNote'),
              proposesDelivery: any(named: 'proposesDelivery'),
              deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
              estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
            ),).thenAnswer((_) async => const Left(WaveExpiredFailure()));
        return cubit;
      },
      act: (cubit) => cubit.submitQuote(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2500,
      ),
      expect: () => [
        const PharmacistCounterState(
          status: PharmacistCounterStatus.submittingQuote,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.failure &&
              state.failure is WaveExpiredFailure &&
              state.errorMessage!.contains('2 minutes');
        }),
      ],
    );
  });

  group('PharmacistCounterCubit - Validation du code OTP au comptoir', () {
    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '1. Code valide (6 chiffres, TTL < 2h) -> succès et transition delivered',
      seed: () => PharmacistCounterState(
        status: PharmacistCounterStatus.loaded,
        orders: [testOrder1],
      ),
      build: () {
        when(() => mockValidateOtpUseCase(
              orderId: testOrder1.id,
              pharmacyId: testPharmacyId,
              otpCode: '482910',
            ),).thenAnswer((_) async => Right(testDeliveredOrder));
        return cubit;
      },
      act: (cubit) => cubit.validateOtpAtCounter(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        otpCode: '482910',
      ),
      expect: () => [
        PharmacistCounterState(
          status: PharmacistCounterStatus.validatingOtp,
          orders: [testOrder1],
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.otpSuccess &&
              state.lastValidatedOrder?.status == FlashOrderStatus.delivered &&
              (state.lastValidatedOrder?.isPickedUp ?? false);
        }),
      ],
    );

    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '2. Code erroné -> échec InvalidOtpFailure',
      build: () {
        when(() => mockValidateOtpUseCase(
              orderId: testOrder1.id,
              pharmacyId: testPharmacyId,
              otpCode: '000000',
            ),).thenAnswer((_) async => const Left(InvalidOtpFailure()));
        return cubit;
      },
      act: (cubit) => cubit.validateOtpAtCounter(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        otpCode: '000000',
      ),
      expect: () => [
        const PharmacistCounterState(
          status: PharmacistCounterStatus.validatingOtp,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.failure &&
              state.failure is InvalidOtpFailure;
        }),
      ],
    );

    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '3. Code expiré (> 2h) -> échec ExpiredOtpFailure',
      build: () {
        when(() => mockValidateOtpUseCase(
              orderId: testOrder1.id,
              pharmacyId: testPharmacyId,
              otpCode: '482910',
            ),).thenAnswer((_) async => const Left(ExpiredOtpFailure()));
        return cubit;
      },
      act: (cubit) => cubit.validateOtpAtCounter(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        otpCode: '482910',
      ),
      expect: () => [
        const PharmacistCounterState(
          status: PharmacistCounterStatus.validatingOtp,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.failure &&
              state.failure is ExpiredOtpFailure;
        }),
      ],
    );

    blocTest<PharmacistCounterCubit, PharmacistCounterState>(
      '4. Code déjà consommé -> échec ConsumedOtpFailure',
      build: () {
        when(() => mockValidateOtpUseCase(
              orderId: testOrder1.id,
              pharmacyId: testPharmacyId,
              otpCode: '482910',
            ),).thenAnswer((_) async => const Left(ConsumedOtpFailure()));
        return cubit;
      },
      act: (cubit) => cubit.validateOtpAtCounter(
        orderId: testOrder1.id,
        pharmacyId: testPharmacyId,
        otpCode: '482910',
      ),
      expect: () => [
        const PharmacistCounterState(
          status: PharmacistCounterStatus.validatingOtp,
        ),
        predicate<PharmacistCounterState>((state) {
          return state.status == PharmacistCounterStatus.failure &&
              state.failure is ConsumedOtpFailure;
        }),
      ],
    );
  });
}
