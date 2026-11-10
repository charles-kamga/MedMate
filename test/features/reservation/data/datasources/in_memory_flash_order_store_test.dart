import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

void main() {
  late InMemoryFlashOrderStore store;

  const tMedication = Medication(
    id: 'med-para-500',
    codeNational: 'CIP-3400936184729',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  const tBasketItem = BasketItemModel(
    medication: tMedication,
    quantite: 2,
  );

  setUp(() {
    store = InMemoryFlashOrderStore()..reset();
  });

  group('InMemoryFlashOrderStore', () {
    test('submitFlashRequest stores request and dispatches initial wave of 2 partner pharmacies', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-test-1',
        clientRequestId: 'client-req-1',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos - Carrefour Warda',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );

      final submitted = await store.submitFlashRequest(request);

      expect(submitted.statut, equals(FlashRequestStatus.active));
      expect(submitted.vagueActuelle, equals(1));
      expect(submitted.pharmaciesNotifieesIds.length, equals(2));
      expect(submitted.pharmaciesNotifieesIds, contains('pharma-bastos-01'));

      // Check incoming demands created for notified pharmacies
      final bastosDemands = await store.getIncomingDemands('pharma-bastos-01');
      expect(bastosDemands.length, equals(1));
      expect(bastosDemands.first.demandeId, equals('req-test-1'));
      expect(bastosDemands.first.isResponded, isFalse);

      // Check analytics incremented
      final analytics = await store.getPharmacyAnalytics(
        pharmacyId: 'pharma-bastos-01',
        date: now,
      );
      expect(analytics.totalDemandsReceived, equals(1));
    });

    test('escalateDispatchWave notifies next wave of partner pharmacies', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-escalate-1',
        clientRequestId: 'client-req-2',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );

      await store.submitFlashRequest(request);

      final escalated = await store.escalateDispatchWave(
        demandeId: 'req-escalate-1',
        nextWaveNumber: 2,
        eligiblePharmacyIds: ['pharma-mokolo-01', 'pharma-tsinga-01'],
      );

      expect(escalated.vagueActuelle, equals(2));
      expect(escalated.pharmaciesNotifieesIds.length, equals(4));
      expect(escalated.pharmaciesNotifieesIds, contains('pharma-mokolo-01'));

      final mokoloDemands = await store.getIncomingDemands('pharma-mokolo-01');
      expect(mokoloDemands.length, equals(1));
      expect(mokoloDemands.first.demandeId, equals('req-escalate-1'));
    });

    test('submitCounterQuote creates PharmacyOffer and updates demand and analytics', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-quote-1',
        clientRequestId: 'client-req-3',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await store.submitFlashRequest(request);

      const submission = CounterQuoteSubmissionModel(
        demandId: 'req-quote-1',
        pharmacyId: 'pharma-bastos-01',
        itemResponses: [
          OfferItemResponseModel(
            medicationId: 'med-para-500',
            status: ItemAvailabilityStatus.available,
            prixUnitaireCommunicParPharmacien: 1500,
          ),
        ],
        montantTotal: 3000,
        livraisonPossible: true,
        fraisLivraison: 500,
        delaiMinutes: 20,
        notes: 'En stock',
      );

      final offer = await store.submitCounterQuote(submission);

      expect(offer.demandeId, equals('req-quote-1'));
      expect(offer.pharmacyId, equals('pharma-bastos-01'));
      expect(offer.montantTotalPropose, equals(3000));
      expect(offer.pharmacyNom, equals('Pharmacie Bastos'));

      // Check request has received offer and status is partiallyAnswered
      final updatedReq = await store.getFlashRequestById('req-quote-1');
      expect(updatedReq.statut, equals(FlashRequestStatus.partiallyAnswered));
      expect(updatedReq.offresRecues.length, equals(1));

      // Check incoming demand is marked responded
      final demands = await store.getIncomingDemands('pharma-bastos-01');
      expect(demands.first.isResponded, isTrue);

      // Check analytics
      final analytics = await store.getPharmacyAnalytics(
        pharmacyId: 'pharma-bastos-01',
        date: now,
      );
      expect(analytics.totalQuotesSubmitted, equals(1));
    });

    test('selectPharmacyOffer creates Reservation with 6-digit numeric OTP and 2h TTL', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-select-1',
        clientRequestId: 'client-req-4',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await store.submitFlashRequest(request);

      const submission = CounterQuoteSubmissionModel(
        demandId: 'req-select-1',
        pharmacyId: 'pharma-bastos-01',
        itemResponses: [
          OfferItemResponseModel(
            medicationId: 'med-para-500',
            status: ItemAvailabilityStatus.available,
            prixUnitaireCommunicParPharmacien: 1500,
          ),
        ],
        montantTotal: 3000,
        livraisonPossible: false,
      );
      final offer = await store.submitCounterQuote(submission);

      final reservation = await store.selectPharmacyOffer(
        clientReservationId: 'client-res-1',
        demandeId: 'req-select-1',
        offreId: offer.id,
        patientPhone: '+237699001122',
      );

      expect(reservation.demandeId, equals('req-select-1'));
      expect(reservation.offreId, equals(offer.id));
      expect(reservation.pharmacyId, equals('pharma-bastos-01'));
      expect(reservation.statut, equals(ReservationStatus.pending));

      // Strict 6-digit numeric OTP
      expect(RegExp(r'^\d{6}$').hasMatch(reservation.codeRetraitOtp6Chiffres), isTrue);

      // Strict 2-hour TTL (~120 minutes)
      final duration = reservation.expiresAt.difference(reservation.createdAt);
      expect(duration.inHours, equals(2));

      // Request status fulfilled
      final updatedReq = await store.getFlashRequestById('req-select-1');
      expect(updatedReq.statut, equals(FlashRequestStatus.fulfilled));
    });

    test('validatePickupOtp validates matching OTP, confirms reservation, and increments analytics', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-otp-1',
        clientRequestId: 'client-req-5',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await store.submitFlashRequest(request);

      const submission = CounterQuoteSubmissionModel(
        demandId: 'req-otp-1',
        pharmacyId: 'pharma-bastos-01',
        itemResponses: [
          OfferItemResponseModel(
            medicationId: 'med-para-500',
            status: ItemAvailabilityStatus.available,
            prixUnitaireCommunicParPharmacien: 1500,
          ),
        ],
        montantTotal: 3000,
        livraisonPossible: false,
      );
      final offer = await store.submitCounterQuote(submission);

      final reservation = await store.selectPharmacyOffer(
        clientReservationId: 'client-res-2',
        demandeId: 'req-otp-1',
        offreId: offer.id,
        patientPhone: '+237699001122',
      );

      final confirmed = await store.validatePickupOtp(
        pharmacyId: 'pharma-bastos-01',
        reservationId: reservation.id,
        otpCode: reservation.codeRetraitOtp6Chiffres,
      );

      expect(confirmed.statut, equals(ReservationStatus.confirmedAtCounter));

      // Check analytics incremented
      final analytics = await store.getPharmacyAnalytics(
        pharmacyId: 'pharma-bastos-01',
        date: now,
      );
      expect(analytics.totalReservationsConfirmed, equals(1));
      expect(analytics.conversionRate, greaterThan(0));
    });

    test('validatePickupOtp throws ValidationException on invalid OTP', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-wrong-otp',
        clientRequestId: 'client-req-6',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await store.submitFlashRequest(request);

      const submission = CounterQuoteSubmissionModel(
        demandId: 'req-wrong-otp',
        pharmacyId: 'pharma-bastos-01',
        itemResponses: [
          OfferItemResponseModel(
            medicationId: 'med-para-500',
            status: ItemAvailabilityStatus.available,
            prixUnitaireCommunicParPharmacien: 1500,
          ),
        ],
        montantTotal: 1500,
        livraisonPossible: false,
      );
      final offer = await store.submitCounterQuote(submission);

      final reservation = await store.selectPharmacyOffer(
        clientReservationId: 'client-res-3',
        demandeId: 'req-wrong-otp',
        offreId: offer.id,
        patientPhone: '+237699001122',
      );

      expect(
        () => store.validatePickupOtp(
          pharmacyId: 'pharma-bastos-01',
          reservationId: reservation.id,
          otpCode: '000000',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validatePickupOtp throws AuthException when validated by wrong pharmacy', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-wrong-pharma',
        clientRequestId: 'client-req-7',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await store.submitFlashRequest(request);

      const submission = CounterQuoteSubmissionModel(
        demandId: 'req-wrong-pharma',
        pharmacyId: 'pharma-bastos-01',
        itemResponses: [
          OfferItemResponseModel(
            medicationId: 'med-para-500',
            status: ItemAvailabilityStatus.available,
            prixUnitaireCommunicParPharmacien: 1500,
          ),
        ],
        montantTotal: 1500,
        livraisonPossible: false,
      );
      final offer = await store.submitCounterQuote(submission);

      final reservation = await store.selectPharmacyOffer(
        clientReservationId: 'client-res-4',
        demandeId: 'req-wrong-pharma',
        offreId: offer.id,
        patientPhone: '+237699001122',
      );

      expect(
        () => store.validatePickupOtp(
          pharmacyId: 'pharma-mokolo-01', // Different pharmacy
          reservationId: reservation.id,
          otpCode: reservation.codeRetraitOtp6Chiffres,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('custom partner pharmacy can be added and notified', () async {
      const customPharma = Pharmacy(
        id: 'pharma-custom-99',
        nom: 'Pharmacie Nouvelle',
        licenceOnpc: 'ONPC-CMR-9999',
        quartier: 'Bastos',
        carrefourRepere: 'Carrefour Bastos',
        latitude: 3.885,
        longitude: 11.515,
        telephoneGarde: '+237699999999',
        estOuverte: true,
        estDeGarde: true,
        estPartenaire: true,
        distanceMetres: 100,
      );
      store.addPartnerPharmacy(customPharma);

      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'req-custom-1',
        clientRequestId: 'client-req-8',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Carrefour Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );

      final submitted = await store.submitFlashRequest(request);
      expect(submitted.pharmaciesNotifieesIds, contains('pharma-custom-99'));
    });
  });
}
