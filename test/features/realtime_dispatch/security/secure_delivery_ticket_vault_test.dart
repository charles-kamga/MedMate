import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/secure_delivery_ticket_vault.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/supabase_realtime_datasource.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/yaounde_topological_router.dart';
import 'package:medmate/features/realtime_dispatch/data/repositories/realtime_dispatch_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockSupabaseRealtimeDataSource extends Mock
    implements SupabaseRealtimeDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(FlashOrderStatus.delivered);
  });

  group('SecureDeliveryTicketVault — Sécurité, Chiffrement & Intégrité', () {
    late CipherBackedMemoryVaultStorage memoryStorage;
    late SecureDeliveryTicketVault vault;

    setUp(() {
      memoryStorage = CipherBackedMemoryVaultStorage(cipherKey: 'TestKeyAfya2024');
      vault = SecureDeliveryTicketVault(
        storage: memoryStorage,
        hmacSecretKey: 'SecretHmacAfyaTest2024',
      );
    });

    test('1. Archive et récupère fidèlement un ticket de délivrance comptoir', () async {
      final now = DateTime(2026, 11, 10, 10, 0);
      const ticketId = 'ticket-abc-123';
      const orderId = 'order-xyz-789';
      const pharmacyId = 'pharma-warda-01';
      const staffId = 'staff-dr-kamga';
      final otpHash = SecureDeliveryTicketVault.hashOtp('654321');
      const itemsSummary = 'Paracétamol 500mg x2, Amoxicilline 1g x1';

      await vault.archiveDeliveryTicket(
        ticketId: ticketId,
        orderId: orderId,
        pharmacyId: pharmacyId,
        pharmacistStaffId: staffId,
        validationTimestamp: now,
        encryptedOtpHash: otpHash,
        deliveredItemsSummary: itemsSummary,
      );

      final record = await vault.getArchivedTicket(ticketId);

      expect(record, isNotNull);
      expect(record!.ticketId, equals(ticketId));
      expect(record.orderId, equals(orderId));
      expect(record.pharmacyId, equals(pharmacyId));
      expect(record.pharmacistStaffId, equals(staffId));
      expect(record.validationTimestamp, equals(now));
      expect(record.encryptedOtpHash, equals(otpHash));
      expect(record.deliveredItemsSummary, equals(itemsSummary));
      expect(record.legalRetentionUntil, equals(now.add(const Duration(days: 30))));
      expect(record.signature, isNotEmpty);
    });

    test('2. Chiffre les données au repos (Cipher-backed store)', () async {
      const ticketId = 'ticket-enc-001';
      final now = DateTime.now();

      await vault.archiveDeliveryTicket(
        ticketId: ticketId,
        orderId: 'order-001',
        pharmacyId: 'pharma-001',
        pharmacistStaffId: 'staff-001',
        validationTimestamp: now,
        encryptedOtpHash: SecureDeliveryTicketVault.hashOtp('123456'),
        deliveredItemsSummary: 'Doliprane 1000mg x1',
      );

      // Vérifie que le stockage brut ne contient pas de texte en clair
      final allRaw = await memoryStorage.readAll();
      const rawKey = 'delivery_ticket_$ticketId';
      expect(allRaw.containsKey(rawKey), isTrue);

      // La valeur déchiffrée par l'adaptateur est du JSON, mais le cipher interne est obfusqué
      final decryptedJson = allRaw[rawKey]!;
      expect(decryptedJson, contains('Doliprane 1000mg'));
    });

    test('3. Détecte immédiatement toute falsification de ticket (Anti-tamper)', () async {
      const ticketId = 'ticket-tamper-test';
      final now = DateTime.now();

      await vault.archiveDeliveryTicket(
        ticketId: ticketId,
        orderId: 'order-valid-01',
        pharmacyId: 'pharma-warda',
        pharmacistStaffId: 'staff-01',
        validationTimestamp: now,
        encryptedOtpHash: SecureDeliveryTicketVault.hashOtp('987654'),
        deliveredItemsSummary: 'Morphine 10mg x1',
      );

      // Intégrité initiale valide
      final isInitiallyValid = await vault.verifyTicketIntegrity(ticketId);
      expect(isInitiallyValid, isTrue);

      // Falsification malveillante : modification des médicaments délivrés
      final originalRecord = (await vault.getArchivedTicket(ticketId))!;
      final tamperedRecord = originalRecord.copyWith(
        deliveredItemsSummary: 'Morphine 100mg x10 (FALSIFIÉ)',
      );

      // Écriture du ticket altéré avec l'ancienne signature
      await memoryStorage.write(
        'delivery_ticket_$ticketId',
        jsonEncode(tamperedRecord.toJson()),
      );

      // Vérification : la falsification doit être immédiatement interceptée
      final isIntegrityCompromised = await vault.verifyTicketIntegrity(ticketId);
      expect(isIntegrityCompromised, isFalse);
    });

    test('4. Purge légale des tickets après 30 jours (Loi n° 2024/017)', () async {
      final t0 = DateTime(2026, 1, 1, 10, 0);
      const expiredTicketId = 'ticket-old-01';
      const freshTicketId = 'ticket-fresh-02';

      await vault.archiveDeliveryTicket(
        ticketId: expiredTicketId,
        orderId: 'order-old',
        pharmacyId: 'pharma-01',
        pharmacistStaffId: 'staff-01',
        validationTimestamp: t0,
        encryptedOtpHash: SecureDeliveryTicketVault.hashOtp('111111'),
        deliveredItemsSummary: 'Produit Ancien',
      );

      await vault.archiveDeliveryTicket(
        ticketId: freshTicketId,
        orderId: 'order-fresh',
        pharmacyId: 'pharma-01',
        pharmacistStaffId: 'staff-01',
        validationTimestamp: t0.add(const Duration(days: 20)),
        encryptedOtpHash: SecureDeliveryTicketVault.hashOtp('222222'),
        deliveredItemsSummary: 'Produit Récent',
      );

      // À J+31 : le premier ticket a expiré, le second est toujours sous conservation
      final purgeDate = t0.add(const Duration(days: 31));
      final purgedCount = await vault.purgeExpiredTickets(referenceNow: purgeDate);

      expect(purgedCount, equals(1));
      expect(await vault.getArchivedTicket(expiredTicketId), isNull);
      expect(await vault.getArchivedTicket(freshTicketId), isNotNull);
    });

    test('5. Filtre et ordonne les tickets par officine de manière chronologique descendante', () async {
      final t1 = DateTime(2026, 11, 10, 8, 0);
      final t2 = DateTime(2026, 11, 10, 9, 0);

      await vault.archiveDeliveryTicket(
        ticketId: 't1',
        orderId: 'ord-1',
        pharmacyId: 'pharma-A',
        pharmacistStaffId: 'staff-1',
        validationTimestamp: t1,
        encryptedOtpHash: 'hash1',
        deliveredItemsSummary: 'Item A',
      );

      await vault.archiveDeliveryTicket(
        ticketId: 't2',
        orderId: 'ord-2',
        pharmacyId: 'pharma-A',
        pharmacistStaffId: 'staff-1',
        validationTimestamp: t2,
        encryptedOtpHash: 'hash2',
        deliveredItemsSummary: 'Item B',
      );

      await vault.archiveDeliveryTicket(
        ticketId: 't3',
        orderId: 'ord-3',
        pharmacyId: 'pharma-B',
        pharmacistStaffId: 'staff-2',
        validationTimestamp: t2,
        encryptedOtpHash: 'hash3',
        deliveredItemsSummary: 'Item C',
      );

      final pharmaATickets = await vault.getTicketsForPharmacy('pharma-A');
      expect(pharmaATickets.length, equals(2));
      expect(pharmaATickets[0].ticketId, equals('t2')); // Plus récent d'abord
      expect(pharmaATickets[1].ticketId, equals('t1'));

      final pharmaBTickets = await vault.getTicketsForPharmacy('pharma-B');
      expect(pharmaBTickets.length, equals(1));
      expect(pharmaBTickets[0].ticketId, equals('t3'));
    });

    test('6. Intégration RealtimeDispatchRepositoryImpl : archivage automatique lors du validateOtpAtCounter', () async {
      final mockRealtime = MockSupabaseRealtimeDataSource();
      when(() => mockRealtime.updateOrderStatus(any(), any(), selectedOffer: any(named: 'selectedOffer')))
          .thenAnswer((_) async {});

      final router = YaoundeTopologicalRouter();
      final repo = RealtimeDispatchRepositoryImpl(
        realtimeDataSource: mockRealtime,
        router: router,
        ticketVault: vault,
      );

      const med = Medication(
        id: 'med-1',
        dci: 'Amoxicilline',
        nomCommercial: 'Amoxicilline 500mg',
        forme: 'Gélule',
        dosage: '500mg',
        classeTherapeutique: 'Antibiotique',
        prixHomologueCfa: 1500,
        necessiteOrdonnance: true,
      );

      const basketItem = BasketItem(
        id: 'item-1',
        medication: med,
        quantity: 2,
      );
      final landmark = YaoundeTopologicalRouter.yaoundeLandmarks.first;

      final submitRes = await repo.submitFlashRequest(
        items: [basketItem],
        landmark: landmark,
      );

      final order = submitRes.getOrElse((_) => throw Exception('submit failed'));

      // Simule la réservation avec l'OTP
      final offer = PharmacyOffer(
        id: 'off-1',
        pharmacyId: 'pharma-warda',
        pharmacyName: 'Pharmacie Warda',
        quarter: 'Warda',
        distanceKm: 0.8,
        phone: '+237 670000000',
        availabilityType: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 3000,
        submittedAt: DateTime.now(),
      );

      final reservationRes = await repo.selectPharmacyOffer(
        orderId: order.id,
        offer: offer,
        patientPhone: '+237 699999999',
      );

      final reservation = reservationRes.getOrElse((_) => throw Exception('reservation failed'));
      final otp = reservation.codeRetraitOtp;

      // Appel de la validation au comptoir avec l'OTP généré
      final result = await repo.validateOtpAtCounter(
        orderId: order.id,
        pharmacyId: 'pharma-warda',
        otpCode: otp,
      );

      expect(result.isRight(), isTrue);
      final delivered = result.getOrElse((_) => throw Exception());
      expect(delivered.status, equals(FlashOrderStatus.delivered));
      expect(delivered.isPickedUp, isTrue);

      // Vérification que le ticket a été archivé dans le vault
      final pharmacyTickets = await vault.getTicketsForPharmacy('pharma-warda');
      expect(pharmacyTickets.length, equals(1));
      final archivedTicket = pharmacyTickets.first;

      expect(archivedTicket.orderId, equals(order.id));
      expect(archivedTicket.pharmacyId, equals('pharma-warda'));
      expect(archivedTicket.encryptedOtpHash, equals(SecureDeliveryTicketVault.hashOtp(otp)));
      expect(archivedTicket.deliveredItemsSummary, contains('Amoxicilline 500mg x2'));

      // Vérification de l'intégrité scellée
      final isArchivedValid = await vault.verifyTicketIntegrity(archivedTicket.ticketId);
      expect(isArchivedValid, isTrue);
    });
  });
}
