import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/datasources/flash_order_data_source.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/data/models/pharmacy_offer_model.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

void main() {
  late InMemoryFlashOrderStore store;
  late FlashOrderDataSourceImpl dataSource;

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
    dataSource = FlashOrderDataSourceImpl(store: store);
  });

  group('FlashOrderDataSourceImpl', () {
    test('submitFlashRequest delegates to store and returns active request', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'ds-req-1',
        clientRequestId: 'client-ds-1',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );

      final result = await dataSource.submitFlashRequest(request);
      expect(result.id, equals('ds-req-1'));
      expect(result.statut, equals(FlashRequestStatus.active));
      expect(result.pharmaciesNotifieesIds, isNotEmpty);
    });

    test('escalateDispatchWave updates wave number and notified pharmacies', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'ds-req-2',
        clientRequestId: 'client-ds-2',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await dataSource.submitFlashRequest(request);

      final escalated = await dataSource.escalateDispatchWave(
        demandeId: 'ds-req-2',
        nextWaveNumber: 2,
        eligiblePharmacyIds: ['pharma-mokolo-01'],
      );

      expect(escalated.vagueActuelle, equals(2));
      expect(escalated.pharmaciesNotifieesIds, contains('pharma-mokolo-01'));
    });

    test('selectPharmacyOffer and confirmReservationOtp workflow', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'ds-req-3',
        clientRequestId: 'client-ds-3',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: [
          PharmacyOfferModel(
            id: 'offer-ds-1',
            demandeId: 'ds-req-3',
            pharmacyId: 'pharma-bastos-01',
            pharmacyNom: 'Pharmacie Bastos',
            quartier: 'Bastos',
            items: const [
              OfferItemResponseModel(
                medicationId: 'med-para-500',
                status: ItemAvailabilityStatus.available,
                prixUnitaireCommunicParPharmacien: 1500,
              ),
            ],
            montantTotalPropose: 3000,
            livraisonDisponible: false,
            createdAt: now,
          ),
        ],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await dataSource.submitFlashRequest(request);

      final reservation = await dataSource.selectPharmacyOffer(
        clientReservationId: 'client-res-ds',
        demandeId: 'ds-req-3',
        offreId: 'offer-ds-1',
        patientPhone: '+237699001122',
      );

      expect(reservation.statut, equals(ReservationStatus.pending));

      final confirmed = await dataSource.confirmReservationOtp(
        reservationId: reservation.id,
        otpCode: reservation.codeRetraitOtp6Chiffres,
      );

      expect(confirmed.statut, equals(ReservationStatus.confirmedAtCounter));
    });

    test('getFlashRequestById and getReservationById retrieve stored items', () async {
      final now = DateTime.now();
      final request = FlashRequestModel(
        id: 'ds-req-4',
        clientRequestId: 'client-ds-4',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );
      await dataSource.submitFlashRequest(request);

      final fetched = await dataSource.getFlashRequestById('ds-req-4');
      expect(fetched.id, equals('ds-req-4'));
    });
  });
}
