import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';

void main() {
  const tOfferItem = OfferItemResponseModel(
    medicationId: 'med-para-500',
    status: ItemAvailabilityStatus.available,
    prixUnitaireCommunicParPharmacien: 1500,
  );

  const tModel = CounterQuoteSubmissionModel(
    demandId: 'req-123',
    pharmacyId: 'pharma-bastos-01',
    itemResponses: [tOfferItem],
    montantTotal: 3000,
    livraisonPossible: true,
    fraisLivraison: 1000,
    delaiMinutes: 30,
    notes: 'Disponible immédiatement au comptoir',
  );

  final tJson = <String, dynamic>{
    'demand_id': 'req-123',
    'pharmacy_id': 'pharma-bastos-01',
    'item_responses': [
      {
        'medication_id': 'med-para-500',
        'status': 'available',
        'prix_unitaire_communic_par_pharmacien': 1500.0,
        'condition_delivrance': null,
        'commentaire': null,
      }
    ],
    'montant_total': 3000.0,
    'livraison_possible': true,
    'frais_livraison': 1000.0,
    'delai_minutes': 30,
    'notes': 'Disponible immédiatement au comptoir',
  };

  group('CounterQuoteSubmissionModel', () {
    test('is a subtype of CounterQuoteSubmission entity', () {
      expect(tModel, isA<CounterQuoteSubmission>());
    });

    test('fromJson deserializes JSON map correctly', () {
      final result = CounterQuoteSubmissionModel.fromJson(tJson);
      expect(result.demandId, equals('req-123'));
      expect(result.pharmacyId, equals('pharma-bastos-01'));
      expect(result.montantTotal, equals(3000));
      expect(result.livraisonPossible, isTrue);
      expect(result.itemResponses.length, equals(1));
      expect(result.notes, equals('Disponible immédiatement au comptoir'));
    });

    test('toJson serializes model to JSON map correctly', () {
      final result = tModel.toJson();
      expect(result['demand_id'], equals('req-123'));
      expect(result['pharmacy_id'], equals('pharma-bastos-01'));
      expect(result['montant_total'], equals(3000));
      expect(result['item_responses'], isNotEmpty);
    });

    test('fromDomain converts CounterQuoteSubmission to CounterQuoteSubmissionModel', () {
      const domain = CounterQuoteSubmission(
        demandId: 'req-dom',
        pharmacyId: 'pharma-dom',
        itemResponses: [tOfferItem],
        montantTotal: 1500,
        livraisonPossible: false,
      );
      final model = CounterQuoteSubmissionModel.fromDomain(domain);
      expect(model.demandId, equals('req-dom'));
      expect(model.montantTotal, equals(1500));
      expect(model.toDomain(), equals(model));
    });
  });
}
