import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/secure_delivery_ticket_vault.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/supabase_realtime_datasource.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/yaounde_topological_router.dart';
import 'package:medmate/features/realtime_dispatch/data/models/flash_order_dto.dart';
import 'package:medmate/features/realtime_dispatch/data/repositories/realtime_dispatch_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseRealtimeDataSource extends Mock
    implements SupabaseRealtimeDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(FlashOrderStatus.accepted);
    registerFallbackValue(FlashOrderStatus.delivered);
    registerFallbackValue(
      PharmacyOffer(
        id: 'mock-off',
        pharmacyId: 'p-1',
        pharmacyName: 'Pharma Test',
        quarter: 'Warda',
        distanceKm: 1,
        phone: '+237 600000000',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2000,
        submittedAt: DateTime.now(),
      ),
    );
  });

  group('Déontologie ONPC & Anonymisation Patient (Loi n° 2024/017)', () {
    late MockSupabaseRealtimeDataSource mockRealtime;
    late YaoundeTopologicalRouter router;
    late SecureDeliveryTicketVault vault;
    late RealtimeDispatchRepositoryImpl repository;

    const testMedication = Medication(
      id: 'med-doliprane-1000',
      dci: 'Paracétamol',
      nomCommercial: 'Doliprane 1000mg',
      forme: 'Comprimé effervescent',
      dosage: '1000mg',
      classeTherapeutique: 'Antalgique / Antipyrétique',
      prixHomologueCfa: 1200,
      necessiteOrdonnance: false,
    );

    const testPrescriptionMedication = Medication(
      id: 'med-amox-500',
      dci: 'Amoxicilline',
      nomCommercial: 'Amoxicilline Biogaran 500mg',
      forme: 'Gélule',
      dosage: '500mg',
      classeTherapeutique: 'Antibiotique',
      prixHomologueCfa: 2500,
      necessiteOrdonnance: true,
    );

    setUp(() {
      mockRealtime = MockSupabaseRealtimeDataSource();
      when(
        () => mockRealtime.updateOrderStatus(
          any(),
          any(),
          selectedOffer: any(named: 'selectedOffer'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockRealtime.submitQuote(any(), any()))
          .thenAnswer((_) async {});

      router = YaoundeTopologicalRouter();
      vault = SecureDeliveryTicketVault(
        storage: CipherBackedMemoryVaultStorage(),
      );
      repository = RealtimeDispatchRepositoryImpl(
        realtimeDataSource: mockRealtime,
        router: router,
        ticketVault: vault,
      );
    });

    test('1. Anonymisation stricte dans la vague : le numéro du patient est STRICTEMENT NULL', () async {
      final items = [
        const BasketItem(id: 'item-1', medication: testMedication, quantity: 2),
      ];
      final originLandmark = YaoundeTopologicalRouter.yaoundeLandmarks.firstWhere(
        (l) => l.id == 'carrefour-warda',
      );

      final result = await repository.submitFlashRequest(
        items: items,
        landmark: originLandmark,
      );

      expect(result.isRight(), isTrue);
      final order = result.getOrElse((_) => throw Exception());

      // Vérifications déontologiques strictes :
      // 1. Le téléphone du patient ne doit JAMAIS être diffusé dans la vague
      expect(order.phoneNumber, isNull);
      expect(order.reservationOtpCode, isNull);

      // 2. Seuls les médicaments demandés et le repère urbain (carrefour/quartier) sont visibles
      expect(order.quarter, equals(originLandmark.quartier));
      expect(order.items.length, equals(1));
      expect(order.items.first.medication.nomCommercial, equals('Doliprane 1000mg'));

      // 3. Les cibles officines reçoivent l'ordre anonymisé sans PII (Personally Identifiable Information)
      expect(order.targets, isNotEmpty);
      final jsonDto = FlashOrderDto.toJson(order);
      expect(jsonDto['phone_number'], isNull);
      expect(jsonDto['reservation_otp_code'], isNull);
    });

    test(
      "2. L'escalade de vague maintient l'anonymisation absolue du patient",
      () async {
      final items = [
        const BasketItem(id: 'item-2', medication: testMedication, quantity: 1),
      ];
      final originLandmark = YaoundeTopologicalRouter.yaoundeLandmarks.firstWhere(
        (l) => l.id == 'poste-centrale',
      );

      final initialOrder = (await repository.submitFlashRequest(
        items: items,
        landmark: originLandmark,
      )).getOrElse((_) => throw Exception());

      // Escalade vers Vague 2 (corridors artériels)
      final escalatedResult = await repository.escalateDispatchWave(initialOrder.id);
      expect(escalatedResult.isRight(), isTrue);

      final escalatedOrder = escalatedResult.getOrElse((_) => throw Exception());
      expect(escalatedOrder.currentWave, equals(2));
      // Toujours strictement anonymisé après escalade
      expect(escalatedOrder.phoneNumber, isNull);
      expect(escalatedOrder.reservationOtpCode, isNull);
    });

    test(
      "3. Transmission sécurisée du numéro UNIQUEMENT à l'officine lauréate après acceptation",
      () async {
      final items = [
        const BasketItem(id: 'item-3', medication: testMedication, quantity: 1),
      ];
      final originLandmark = YaoundeTopologicalRouter.yaoundeLandmarks.first;
      final order = (await repository.submitFlashRequest(
        items: items,
        landmark: originLandmark,
      )).getOrElse((_) => throw Exception());

      const patientPhone = '+237 699112233';
      final winningOffer = PharmacyOffer(
        id: 'off-laureate-01',
        pharmacyId: 'pharma-centre-yaounde',
        pharmacyName: 'Pharmacie du Centre',
        quarter: 'Centre Ville',
        distanceKm: 0.5,
        phone: '+237 622000000',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 1200,
        submittedAt: DateTime.now(),
      );

      final reservationResult = await repository.selectPharmacyOffer(
        orderId: order.id,
        offer: winningOffer,
        patientPhone: patientPhone,
      );

      expect(reservationResult.isRight(), isTrue);
      final reservation = reservationResult.getOrElse((_) => throw Exception());

      // La réservation lie l'officine lauréate et génère un OTP à 6 chiffres
      expect(reservation.pharmacyId, equals('pharma-centre-yaounde'));
      expect(reservation.codeRetraitOtp, matches(r'^\d{6}$'));

      // La commande flash reflète désormais l'acceptation et transmet le contact à la pharmacie choisie
      final updatedOrder = (await repository.getFlashRequestById(order.id))
          .getOrElse((_) => throw Exception());

      expect(updatedOrder.status, equals(FlashOrderStatus.accepted));
      expect(updatedOrder.phoneNumber, equals(patientPhone));
      expect(updatedOrder.selectedOffer?.pharmacyId, equals('pharma-centre-yaounde'));
      expect(updatedOrder.reservationOtpCode, equals(reservation.codeRetraitOtp));
    });

    test('4. Respect strict des 3 statuts officiels ONPC et de la neutralité tarifaire', () async {
      final items = [
        const BasketItem(id: 'it-onpc', medication: testPrescriptionMedication, quantity: 1),
      ];
      final landmark = YaoundeTopologicalRouter.yaoundeLandmarks.first;
      final order = (await repository.submitFlashRequest(
        items: items,
        landmark: landmark,
      )).getOrElse((_) => throw Exception());

      // 1. Statut fullyAvailable : produit immédiatement disponible
      final resFull = await repository.submitQuote(
        orderId: order.id,
        pharmacyId: 'pharma-1',
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2500,
        proposesDelivery: true,
        deliveryFeeCfa: 1000, // Frais mototaxi distincts
        estimatedDeliveryMinutes: 25,
      );
      expect(resFull.isRight(), isTrue);
      final offerFull = resFull.getOrElse((_) => throw Exception());
      expect(offerFull.availabilityType, equals(PharmacyAvailabilityType.fullyAvailable));
      expect(offerFull.quotedPriceCfa, equals(2500));
      expect(offerFull.deliveryFeeCfa, equals(1000));

      // 2. Statut conditional : réserve ordonnance obligatoire
      final resCond = await repository.submitQuote(
        orderId: order.id,
        pharmacyId: 'pharma-2',
        availability: PharmacyAvailabilityType.conditional,
        quotedPriceCfa: 2400,
        conditionRequirements: ['Ordonnance physique originale obligatoire au comptoir'],
        conditionNote: 'Présentation requise avant délivrance selon réglementation ONPC',
      );
      expect(resCond.isRight(), isTrue);
      final offerCond = resCond.getOrElse((_) => throw Exception());
      expect(offerCond.availabilityType, equals(PharmacyAvailabilityType.conditional));
      expect(offerCond.conditionRequirements, contains('Ordonnance physique originale obligatoire au comptoir'));

      // 3. Statut unavailable : rupture de stock
      final resUnavail = await repository.submitQuote(
        orderId: order.id,
        pharmacyId: 'pharma-3',
        availability: PharmacyAvailabilityType.unavailable,
        quotedPriceCfa: 0,
      );
      expect(resUnavail.isRight(), isTrue);
      final offerUnavail = resUnavail.getOrElse((_) => throw Exception());
      expect(offerUnavail.availabilityType, equals(PharmacyAvailabilityType.unavailable));
      expect(offerUnavail.quotedPriceCfa, equals(0));
    });

    test('5. Règle anti-concurrence déontologique : refus de devis sur commande déjà accordée', () async {
      final items = [
        const BasketItem(id: 'it-race', medication: testMedication, quantity: 1),
      ];
      final landmark = YaoundeTopologicalRouter.yaoundeLandmarks.first;
      final order = (await repository.submitFlashRequest(
        items: items,
        landmark: landmark,
      )).getOrElse((_) => throw Exception());

      final winningOffer = PharmacyOffer(
        id: 'off-winner',
        pharmacyId: 'pharma-winner',
        pharmacyName: 'Pharmacie Gagnante',
        quarter: 'Mokolo',
        distanceKm: 1,
        phone: '+237 600000000',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 1200,
        submittedAt: DateTime.now(),
      );

      // Le patient valide l'offre de Pharmacie Gagnante
      await repository.selectPharmacyOffer(
        orderId: order.id,
        offer: winningOffer,
        patientPhone: '+237 690000000',
      );

      // Une autre officine tente de soumettre un devis a posteriori
      final lateSubmission = await repository.submitQuote(
        orderId: order.id,
        pharmacyId: 'pharma-late',
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 1100,
      );

      expect(lateSubmission.isLeft(), isTrue);
      lateSubmission.fold(
        (failure) => expect(failure.message, contains('déjà été acceptée par un confrère')),
        (_) => fail('Should have rejected quote on accepted order'),
      );
    });

    test('6. Vérification formelle du schéma SQL RLS (supabase/migrations/20261110000001_realtime_dispatch_schema.sql)', () {
      final sqlFile = File('supabase/migrations/20261110000001_realtime_dispatch_schema.sql');
      expect(sqlFile.existsSync(), isTrue, reason: 'Migration SQL temps réel requise');

      final content = sqlFile.readAsStringSync();

      // Vérification RLS activée et forcée
      expect(content, contains('ALTER TABLE public.flash_orders ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('ALTER TABLE public.flash_orders FORCE ROW LEVEL SECURITY;'));
      expect(content, contains('ALTER TABLE public.pharmacy_quotes ENABLE ROW LEVEL SECURITY;'));
      expect(content, contains('ALTER TABLE public.pharmacy_quotes FORCE ROW LEVEL SECURITY;'));

      // Vérification publication Realtime Supabase
      expect(content, contains('CREATE PUBLICATION supabase_realtime;'));
      expect(content, contains('ALTER PUBLICATION supabase_realtime ADD TABLE public.flash_orders, public.pharmacy_quotes;'));

      // Vérification conformité déontologique Loi n° 2024/017
      expect(content, contains('Loi n° 2024/017'));
      expect(content, contains('idx_flash_orders_location_gist'));
    });
  });
}
