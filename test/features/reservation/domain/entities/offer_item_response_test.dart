import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';

void main() {
  group('OfferItemResponse Entity & Tarification au Comptoir Invariant', () {
    const responseA = OfferItemResponse(
      medicationId: 'med-para-500',
      status: ItemAvailabilityStatus.available,
      prixUnitaireCommunicParPharmacien: 1250,
      conditionDelivrance: null,
      commentaire: 'Disponible immédiatement',
    );

    const responseB = OfferItemResponse(
      medicationId: 'med-para-500',
      status: ItemAvailabilityStatus.available,
      prixUnitaireCommunicParPharmacien: 1250,
      conditionDelivrance: null,
      commentaire: 'Disponible immédiatement',
    );

    const responseUnavailable = OfferItemResponse(
      medicationId: 'med-para-500',
      status: ItemAvailabilityStatus.unavailable,
      prixUnitaireCommunicParPharmacien: 0,
      conditionDelivrance: null,
      commentaire: 'Rupture de stock nationale',
    );

    test('supports value equality via props', () {
      expect(responseA, equals(responseB));
      expect(responseA, isNot(equals(responseUnavailable)));
      expect(responseA.props, [
        'med-para-500',
        ItemAvailabilityStatus.available,
        1250,
        null,
        'Disponible immédiatement',
      ]);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = responseA.copyWith(
        status: ItemAvailabilityStatus.conditional,
        conditionDelivrance: 'Ordonnance originale requise',
      );

      expect(updated.medicationId, equals('med-para-500'));
      expect(updated.status, equals(ItemAvailabilityStatus.conditional));
      expect(updated.prixUnitaireCommunicParPharmacien, equals(1250));
      expect(
        updated.conditionDelivrance,
        equals('Ordonnance originale requise'),
      );
    });

    test('INVARIANT: Price exists strictly at counter quote level in FCFA', () {
      expect(responseA.prixUnitaireCommunicParPharmacien, greaterThanOrEqualTo(0));
      expect(responseUnavailable.prixUnitaireCommunicParPharmacien, equals(0));
    });
  });
}
