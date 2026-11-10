import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacist_portal/data/datasources/pharmacist_portal_data_source.dart';
import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

void main() {
  late InMemoryFlashOrderStore store;
  late PharmacistPortalDataSourceImpl dataSource;

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
    dataSource = PharmacistPortalDataSourceImpl(store: store);
  });

  group('PharmacistPortalDataSourceImpl', () {
    test('getIncomingDemands returns list of demands dispatched to pharmacy', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'pp-req-1',
        clientRequestId: 'client-pp-1',
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

      final demands = await dataSource.getIncomingDemands('pharma-bastos-01');
      expect(demands, isNotEmpty);
      expect(demands.first.demandeId, equals('pp-req-1'));
    });

    test('submitCounterQuote delegates to store and returns PharmacyOfferModel', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'pp-req-2',
        clientRequestId: 'client-pp-2',
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
        demandId: 'pp-req-2',
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
      );

      final offer = await dataSource.submitCounterQuote(submission);
      expect(offer.demandeId, equals('pp-req-2'));
      expect(offer.pharmacyId, equals('pharma-bastos-01'));
      expect(offer.montantTotalPropose, equals(3000));
    });

    test('validatePickupOtp validates OTP and returns confirmed reservation', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'pp-req-3',
        clientRequestId: 'client-pp-3',
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
        demandId: 'pp-req-3',
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
        clientReservationId: 'client-res-pp-3',
        demandeId: 'pp-req-3',
        offreId: offer.id,
        patientPhone: '+237699001122',
      );

      final confirmed = await dataSource.validatePickupOtp(
        pharmacyId: 'pharma-bastos-01',
        reservationId: reservation.id,
        otpCode: reservation.codeRetraitOtp6Chiffres,
      );

      expect(confirmed.statut, equals(ReservationStatus.confirmedAtCounter));
    });

    test('getPharmacyAnalytics returns operational metrics', () async {
      final analytics = await dataSource.getPharmacyAnalytics(
        pharmacyId: 'pharma-bastos-01',
        date: DateTime.now(),
      );
      expect(analytics.pharmacyId, equals('pharma-bastos-01'));
      expect(analytics.totalDemandsReceived, greaterThanOrEqualTo(0));
    });
  });
}
