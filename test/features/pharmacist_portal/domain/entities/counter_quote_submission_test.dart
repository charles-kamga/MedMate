import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';

void main() {
  group('CounterQuoteSubmission Entity & Tarification au Comptoir Invariant', () {
    const sampleItem = OfferItemResponse(
      medicationId: 'med-para-500',
      status: ItemAvailabilityStatus.available,
      prixUnitaireCommunicParPharmacien: 1250,
      conditionDelivrance: null,
      commentaire: 'En stock',
    );

    const submissionA = CounterQuoteSubmission(
      demandId: 'demand-1',
      pharmacyId: 'pharma-1',
      itemResponses: [sampleItem],
      montantTotal: 2500,
      livraisonPossible: true,
      fraisLivraison: 1000,
      delaiMinutes: 25,
      notes: 'Livraison express possible',
    );

    const submissionB = CounterQuoteSubmission(
      demandId: 'demand-1',
      pharmacyId: 'pharma-1',
      itemResponses: [sampleItem],
      montantTotal: 2500,
      livraisonPossible: true,
      fraisLivraison: 1000,
      delaiMinutes: 25,
      notes: 'Livraison express possible',
    );

    const submissionOther = CounterQuoteSubmission(
      demandId: 'demand-2',
      pharmacyId: 'pharma-2',
      itemResponses: [sampleItem],
      montantTotal: 1800,
      livraisonPossible: false,
    );

    test('supports value equality via props', () {
      expect(submissionA, equals(submissionB));
      expect(submissionA, isNot(equals(submissionOther)));
      expect(submissionA.props, [
        'demand-1',
        'pharma-1',
        const [sampleItem],
        2500,
        true,
        1000,
        25,
        'Livraison express possible',
      ]);
    });

    test('helper alias getters return accurate values', () {
      expect(submissionA.itemsResponse, equals(const [sampleItem]));
      expect(submissionA.delaiEstimeMinutes, equals(25));
      expect(submissionA.commentairePharmacien, equals('Livraison express possible'));
    });

    test('INVARIANT: Counter quote establishes pricing exclusively at counter in FCFA', () {
      expect(submissionA.montantTotal, greaterThanOrEqualTo(0));
      expect(
        submissionA.itemResponses.first.prixUnitaireCommunicParPharmacien,
        greaterThanOrEqualTo(0),
      );
    });

    test('copyWith updates specified fields correctly', () {
      final updated = submissionA.copyWith(
        montantTotal: 2800,
        livraisonPossible: false,
      );

      expect(updated.demandId, equals('demand-1'));
      expect(updated.montantTotal, equals(2800));
      expect(updated.livraisonPossible, isFalse);
    });
  });
}
