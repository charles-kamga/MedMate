import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';

void main() {
  group('PharmacyOffer Entity', () {
    final fixedCreatedAt = DateTime(2026, 11, 9, 20, 0, 0);

    const sampleItem = OfferItemResponse(
      medicationId: 'med-para-500',
      status: ItemAvailabilityStatus.available,
      prixUnitaireCommunicParPharmacien: 1250,
      conditionDelivrance: null,
      commentaire: 'Disponible',
    );

    final offerA = PharmacyOffer(
      id: 'offer-1',
      demandeId: 'demand-1',
      pharmacyId: 'pharma-bastos',
      pharmacyNom: 'Pharmacie Bastos',
      quartier: 'Bastos',
      items: const [sampleItem],
      montantTotalPropose: 2500,
      livraisonDisponible: true,
      createdAt: fixedCreatedAt,
      distanceMetres: 450,
      fraisLivraison: 1000,
      delaiLivraisonMinutes: 30,
    );

    final offerB = PharmacyOffer(
      id: 'offer-1',
      demandeId: 'demand-1',
      pharmacyId: 'pharma-bastos',
      pharmacyNom: 'Pharmacie Bastos',
      quartier: 'Bastos',
      items: const [sampleItem],
      montantTotalPropose: 2500,
      livraisonDisponible: true,
      createdAt: fixedCreatedAt,
      distanceMetres: 450,
      fraisLivraison: 1000,
      delaiLivraisonMinutes: 30,
    );

    final offerOther = PharmacyOffer(
      id: 'offer-2',
      demandeId: 'demand-1',
      pharmacyId: 'pharma-mokolo',
      pharmacyNom: 'Pharmacie Mokolo',
      quartier: 'Mokolo',
      items: const [sampleItem],
      montantTotalPropose: 2200,
      livraisonDisponible: false,
      createdAt: fixedCreatedAt,
      distanceMetres: 1200,
    );

    test('supports value equality via props', () {
      expect(offerA, equals(offerB));
      expect(offerA, isNot(equals(offerOther)));
      expect(offerA.props, [
        'offer-1',
        'demand-1',
        'pharma-bastos',
        'Pharmacie Bastos',
        'Bastos',
        450,
        [sampleItem],
        2500,
        true,
        1000,
        30,
        fixedCreatedAt,
      ]);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = offerA.copyWith(
        montantTotalPropose: 3000,
        livraisonDisponible: false,
      );

      expect(updated.id, equals('offer-1'));
      expect(updated.montantTotalPropose, equals(3000.0));
      expect(updated.livraisonDisponible, isFalse);
      expect(updated.pharmacyNom, equals('Pharmacie Bastos'));
    });
  });
}
