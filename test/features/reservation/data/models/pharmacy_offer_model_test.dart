import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/data/models/pharmacy_offer_model.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';

void main() {
  final tCreatedAt = DateTime(2026, 11, 9, 14, 30);

  const tOfferItem = OfferItemResponseModel(
    medicationId: 'med-para-500',
    status: ItemAvailabilityStatus.available,
    prixUnitaireCommunicParPharmacien: 1500,
  );

  final tModel = PharmacyOfferModel(
    id: 'offer-123',
    demandeId: 'demande-456',
    pharmacyId: 'pharma-bastos-01',
    pharmacyNom: 'Pharmacie Bastos',
    quartier: 'Bastos',
    items: const [tOfferItem],
    montantTotalPropose: 3000,
    livraisonDisponible: true,
    distanceMetres: 350,
    fraisLivraison: 1000,
    delaiLivraisonMinutes: 30,
    createdAt: tCreatedAt,
  );

  final tJson = <String, dynamic>{
    'id': 'offer-123',
    'demande_id': 'demande-456',
    'pharmacy_id': 'pharma-bastos-01',
    'pharmacy_nom': 'Pharmacie Bastos',
    'quartier': 'Bastos',
    'items': [
      {
        'medication_id': 'med-para-500',
        'status': 'available',
        'prix_unitaire_communic_par_pharmacien': 1500.0,
        'condition_delivrance': null,
        'commentaire': null,
      }
    ],
    'montant_total_propose': 3000.0,
    'livraison_disponible': true,
    'created_at': tCreatedAt.toIso8601String(),
    'distance_metres': 350.0,
    'frais_livraison': 1000.0,
    'delai_livraison_minutes': 30,
  };

  group('PharmacyOfferModel', () {
    test('is a subtype of PharmacyOffer entity', () {
      expect(tModel, isA<PharmacyOffer>());
    });

    test('fromJson deserializes JSON map correctly', () {
      final result = PharmacyOfferModel.fromJson(tJson);
      expect(result.id, equals('offer-123'));
      expect(result.demandeId, equals('demande-456'));
      expect(result.pharmacyId, equals('pharma-bastos-01'));
      expect(result.pharmacyNom, equals('Pharmacie Bastos'));
      expect(result.montantTotalPropose, equals(3000));
      expect(result.livraisonDisponible, isTrue);
      expect(result.items.length, equals(1));
    });

    test('toJson serializes model to JSON map correctly', () {
      final result = tModel.toJson();
      expect(result['id'], equals('offer-123'));
      expect(result['demande_id'], equals('demande-456'));
      expect(result['montant_total_propose'], equals(3000));
      expect(result['items'], isNotEmpty);
    });

    test('fromDomain converts PharmacyOffer entity to PharmacyOfferModel', () {
      final domain = PharmacyOffer(
        id: 'offer-dom',
        demandeId: 'demande-dom',
        pharmacyId: 'pharma-nlongkak-01',
        pharmacyNom: 'Pharmacie de Nlongkak',
        quartier: 'Nlongkak',
        items: const [tOfferItem],
        montantTotalPropose: 2500,
        livraisonDisponible: false,
        createdAt: tCreatedAt,
      );
      final model = PharmacyOfferModel.fromDomain(domain);
      expect(model.id, equals('offer-dom'));
      expect(model.pharmacyNom, equals('Pharmacie de Nlongkak'));
      expect(model.toDomain(), equals(model));
    });
  });
}
