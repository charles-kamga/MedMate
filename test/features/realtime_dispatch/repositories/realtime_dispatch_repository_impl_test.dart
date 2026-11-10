import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/reservation.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/adaptive_polling_fallback_manager.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/supabase_realtime_datasource.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/yaounde_topological_router.dart';
import 'package:medmate/features/realtime_dispatch/data/repositories/realtime_dispatch_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseRealtimeDataSource extends Mock
    implements SupabaseRealtimeDataSource {}

void main() {
  late MockSupabaseRealtimeDataSource mockDataSource;
  late YaoundeTopologicalRouter router;
  late AdaptivePollingFallbackManager fallbackManager;
  late RealtimeDispatchRepositoryImpl repository;

  const sampleMed = Medication(
    id: 'med-parac-500',
    dci: 'Paracétamol',
    nomCommercial: 'Efferalgan 500mg',
    forme: 'Comprimé',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1200,
    necessiteOrdonnance: false,
  );

  const sampleBasketItem = BasketItem(
    id: 'item-1',
    medication: sampleMed,
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

  setUpAll(() {
    registerFallbackValue(FlashOrderStatus.dispatchingWave);
    registerFallbackValue(
      PharmacyOffer(
        id: 'dummy',
        pharmacyId: 'p-dummy',
        pharmacyName: 'Dummy',
        quarter: 'Dummy',
        distanceKm: 1,
        phone: '000',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 1000,
        submittedAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockDataSource = MockSupabaseRealtimeDataSource();
    router = YaoundeTopologicalRouter();
    fallbackManager = AdaptivePollingFallbackManager();

    when(() => mockDataSource.fallbackManager).thenReturn(fallbackManager);
    when(
      () => mockDataSource.updateOrderStatus(
        any(),
        any(),
        selectedOffer: any(named: 'selectedOffer'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockDataSource.submitQuote(any(), any()))
        .thenAnswer((_) async {});

    repository = RealtimeDispatchRepositoryImpl(
      realtimeDataSource: mockDataSource,
      router: router,
    );
  });

  tearDown(() {
    fallbackManager.dispose();
  });

  group('RealtimeDispatchRepositoryImpl Tests', () {
    test('submitFlashRequest generates order with Wave 1 targets', () async {
      final result = await repository.submitFlashRequest(
        items: const [sampleBasketItem],
        landmark: sampleLandmark,
      );

      expect(result.isRight(), isTrue);
      result.fold((l) => fail('Should succeed'), (order) {
        expect(order.quarter, equals('Poste Centrale'));
        expect(order.currentWave, equals(1));
        expect(order.status, equals(FlashOrderStatus.dispatchingWave));
        expect(order.targets.isNotEmpty, isTrue);
        expect(order.targets.first.waveIndex, equals(1));
      });
    });

    test('escalateDispatchWave expands targets to Wave 2 corridors', () async {
      final createRes = await repository.submitFlashRequest(
        items: const [sampleBasketItem],
        landmark: sampleLandmark,
      );

      late String orderId;
      createRes.fold((l) => fail('Failed to create'), (o) => orderId = o.id);

      final escalateRes = await repository.escalateDispatchWave(orderId);
      expect(escalateRes.isRight(), isTrue);

      escalateRes.fold((l) => fail('Escalation failed'), (order) {
        expect(order.currentWave, equals(2));
        expect(order.targets.any((t) => t.waveIndex == 2), isTrue);
      });

      verify(() => mockDataSource.updateOrderStatus(orderId, FlashOrderStatus.dispatchingWave))
          .called(1);
    });

    test('selectPharmacyOffer validates choice and generates 6-digit OTP ticket (TTL 2h)', () async {
      final createRes = await repository.submitFlashRequest(
        items: const [sampleBasketItem],
        landmark: sampleLandmark,
      );

      late String orderId;
      createRes.fold((l) => fail('Failed to create'), (o) => orderId = o.id);

      final offer = PharmacyOffer(
        id: 'offer-soleil',
        pharmacyId: 'pharma-soleil',
        pharmacyName: 'Pharmacie du Soleil',
        quarter: 'Poste Centrale',
        distanceKm: 0.5,
        phone: '+237 671234567',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
        submittedAt: DateTime.now(),
      );

      final selectRes = await repository.selectPharmacyOffer(
        orderId: orderId,
        offer: offer,
        patientPhone: '+237 699001122',
      );

      expect(selectRes.isRight(), isTrue);
      selectRes.fold((l) => fail('Failed to select offer'), (reservation) {
        expect(reservation.pharmacyId, equals('pharma-soleil'));
        expect(reservation.statut, equals(ReservationStatus.confirmed));
        expect(reservation.codeRetraitOtp.length, equals(6));
        expect(reservation.expiresAt.isAfter(DateTime.now()), isTrue);
      });

      final updatedOrderRes = await repository.getFlashRequestById(orderId);
      updatedOrderRes.fold((l) => fail('Failed to get order'), (order) {
        expect(order.status, equals(FlashOrderStatus.accepted));
        expect(order.selectedOffer?.id, equals('offer-soleil'));
        expect(order.reservationOtpCode, isNotNull);
        expect(order.reservationOtpCode!.length, equals(6));
      });
    });

    test('submitQuote rejects if order was already accepted by another pharmacist (Race condition)', () async {
      final createRes = await repository.submitFlashRequest(
        items: const [sampleBasketItem],
        landmark: sampleLandmark,
      );

      late String orderId;
      createRes.fold((l) => fail('Failed to create'), (o) => orderId = o.id);

      final winningOffer = PharmacyOffer(
        id: 'winner-1',
        pharmacyId: 'pharma-winner',
        pharmacyName: 'Pharmacie Gagnante',
        quarter: 'Poste Centrale',
        distanceKm: 0.3,
        phone: '+237 670000001',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2000,
        submittedAt: DateTime.now(),
      );

      await repository.selectPharmacyOffer(
        orderId: orderId,
        offer: winningOffer,
        patientPhone: '+237 699000000',
      );

      // Tentative de soumission par un confrère après acceptation
      final lateQuoteRes = await repository.submitQuote(
        orderId: orderId,
        pharmacyId: 'pharma-late',
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2200,
      );

      expect(lateQuoteRes.isLeft(), isTrue);
      lateQuoteRes.fold(
        (failure) {
          expect(failure.message, contains('déjà été acceptée par un confrère'));
        },
        (r) => fail('Should have failed'),
      );
    });

    test('validateOtpAtCounter marks order delivered on valid OTP, rejects on invalid', () async {
      final createRes = await repository.submitFlashRequest(
        items: const [sampleBasketItem],
        landmark: sampleLandmark,
      );

      late String orderId;
      createRes.fold((l) => fail('Failed to create'), (o) => orderId = o.id);

      final offer = PharmacyOffer(
        id: 'offer-1',
        pharmacyId: 'pharma-soleil',
        pharmacyName: 'Pharmacie Soleil',
        quarter: 'Poste Centrale',
        distanceKm: 0.5,
        phone: '+237 670000000',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
        submittedAt: DateTime.now(),
      );

      final selectRes = await repository.selectPharmacyOffer(
        orderId: orderId,
        offer: offer,
        patientPhone: '+237 699000000',
      );

      late String generatedOtp;
      selectRes.fold((l) => fail('Failed to select'), (r) => generatedOtp = r.codeRetraitOtp);

      // Test 1: OTP invalide
      final invalidRes = await repository.validateOtpAtCounter(
        orderId: orderId,
        pharmacyId: 'pharma-soleil',
        otpCode: '000000',
      );
      expect(invalidRes.isLeft(), isTrue);

      // Test 2: OTP valide
      final validRes = await repository.validateOtpAtCounter(
        orderId: orderId,
        pharmacyId: 'pharma-soleil',
        otpCode: generatedOtp,
      );
      expect(validRes.isRight(), isTrue);
      validRes.fold((l) => fail('Failed to validate'), (delivered) {
        expect(delivered.status, equals(FlashOrderStatus.delivered));
        expect(delivered.isPickedUp, isTrue);
      });

      // Test 3: Déjà retiré
      final alreadyPickedUpRes = await repository.validateOtpAtCounter(
        orderId: orderId,
        pharmacyId: 'pharma-soleil',
        otpCode: generatedOtp,
      );
      expect(alreadyPickedUpRes.isLeft(), isTrue);
    });
  });
}
