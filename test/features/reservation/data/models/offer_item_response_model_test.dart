import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';

void main() {
  const tModel = OfferItemResponseModel(
    medicationId: 'med-para-500',
    status: ItemAvailabilityStatus.available,
    prixUnitaireCommunicParPharmacien: 1500,
    conditionDelivrance: 'Ordonnance originale requise',
    commentaire: 'Boîte de 16 comprimés',
  );

  final tJson = <String, dynamic>{
    'medication_id': 'med-para-500',
    'status': 'available',
    'prix_unitaire_communic_par_pharmacien': 1500.0,
    'condition_delivrance': 'Ordonnance originale requise',
    'commentaire': 'Boîte de 16 comprimés',
  };

  group('OfferItemResponseModel', () {
    test('is a subtype of OfferItemResponse entity', () {
      expect(tModel, isA<OfferItemResponse>());
    });

    test('fromJson deserializes JSON map with snake_case correctly', () {
      final result = OfferItemResponseModel.fromJson(tJson);
      expect(result.medicationId, equals('med-para-500'));
      expect(result.status, equals(ItemAvailabilityStatus.available));
      expect(result.prixUnitaireCommunicParPharmacien, equals(1500));
      expect(result.conditionDelivrance, equals('Ordonnance originale requise'));
      expect(result.commentaire, equals('Boîte de 16 comprimés'));
    });

    test('toJson serializes model to Map correctly', () {
      final result = tModel.toJson();
      expect(result['medication_id'], equals('med-para-500'));
      expect(result['status'], equals('available'));
      expect(result['prix_unitaire_communic_par_pharmacien'], equals(1500));
    });

    test('fromDomain converts OfferItemResponse entity to OfferItemResponseModel', () {
      const entity = OfferItemResponse(
        medicationId: 'med-amox-500',
        status: ItemAvailabilityStatus.conditional,
        prixUnitaireCommunicParPharmacien: 2200,
      );
      final model = OfferItemResponseModel.fromDomain(entity);
      expect(model.medicationId, equals('med-amox-500'));
      expect(model.status, equals(ItemAvailabilityStatus.conditional));
      expect(model.prixUnitaireCommunicParPharmacien, equals(2200));
      expect(model.toDomain(), equals(model));
    });
  });
}
