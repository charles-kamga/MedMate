import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';

void main() {
  group('FlashRequest Entity', () {
    final fixedCreatedAt = DateTime(2026, 11, 9, 20, 0, 0);
    final futureExpiresAt = DateTime.now().add(const Duration(minutes: 15));
    final pastExpiresAt = DateTime.now().subtract(const Duration(minutes: 5));

    const sampleMedication = Medication(
      id: 'med-para-500',
      codeNational: 'CIP-3400936184729',
      nomCommercial: 'Paracétamol Biogaran',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '500 mg',
      necessiteOrdonnance: false,
    );

    const sampleBasketItem = BasketItem(
      medication: sampleMedication,
      quantite: 1,
    );

    final sampleOffer = PharmacyOffer(
      id: 'offer-1',
      demandeId: 'flash-1',
      pharmacyId: 'pharma-1',
      pharmacyNom: 'Pharmacie Bastos',
      quartier: 'Bastos',
      items: const [
        OfferItemResponse(
          medicationId: 'med-para-500',
          status: ItemAvailabilityStatus.available,
          prixUnitaireCommunicParPharmacien: 1200,
        ),
      ],
      montantTotalPropose: 1200,
      livraisonDisponible: false,
      createdAt: fixedCreatedAt,
    );

    final requestA = FlashRequest(
      id: 'flash-1',
      clientRequestId: 'client-req-uuid-1',
      items: const [sampleBasketItem],
      quartierOuCarrefour: 'Carrefour Warda',
      statut: FlashRequestStatus.active,
      vagueActuelle: 1,
      pharmaciesNotifieesIds: const ['pharma-1', 'pharma-2'],
      offresRecues: [sampleOffer],
      createdAt: fixedCreatedAt,
      expiresAt: futureExpiresAt,
    );

    final requestB = FlashRequest(
      id: 'flash-1',
      clientRequestId: 'client-req-uuid-1',
      items: const [sampleBasketItem],
      quartierOuCarrefour: 'Carrefour Warda',
      statut: FlashRequestStatus.active,
      vagueActuelle: 1,
      pharmaciesNotifieesIds: const ['pharma-1', 'pharma-2'],
      offresRecues: [sampleOffer],
      createdAt: fixedCreatedAt,
      expiresAt: futureExpiresAt,
    );

    test('supports value equality via props', () {
      expect(requestA, equals(requestB));
      expect(requestA.props, [
        'flash-1',
        'client-req-uuid-1',
        const [sampleBasketItem],
        'Carrefour Warda',
        FlashRequestStatus.active,
        1,
        const ['pharma-1', 'pharma-2'],
        [sampleOffer],
        fixedCreatedAt,
        futureExpiresAt,
      ]);
    });

    test('computed properties hasOffers and isExpired work accurately', () {
      expect(requestA.hasOffers, isTrue);
      expect(requestA.isExpired, isFalse);

      final emptyOffersRequest = requestA.copyWith(offresRecues: const []);
      expect(emptyOffersRequest.hasOffers, isFalse);

      final expiredRequest = requestA.copyWith(expiresAt: pastExpiresAt);
      expect(expiredRequest.isExpired, isTrue);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = requestA.copyWith(
        vagueActuelle: 2,
        statut: FlashRequestStatus.partiallyAnswered,
      );

      expect(updated.vagueActuelle, equals(2));
      expect(updated.statut, equals(FlashRequestStatus.partiallyAnswered));
      expect(updated.quartierOuCarrefour, equals('Carrefour Warda'));
    });
  });
}
