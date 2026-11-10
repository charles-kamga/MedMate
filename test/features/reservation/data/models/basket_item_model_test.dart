import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';

void main() {
  const tMedication = Medication(
    id: 'med-para-500',
    codeNational: 'CIP-3400936184729',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  const tBasketItemModel = BasketItemModel(
    medication: tMedication,
    quantite: 2,
    precision: 'Générique accepté si disponible',
  );

  final tJson = <String, dynamic>{
    'medication': {
      'id': 'med-para-500',
      'code_national': 'CIP-3400936184729',
      'nom_commercial': 'Paracétamol Biogaran',
      'dci': 'Paracétamol',
      'forme': 'Comprimé effervescent',
      'dosage': '500 mg',
      'necessite_ordonnance': false,
    },
    'quantite': 2,
    'precision': 'Générique accepté si disponible',
  };

  group('BasketItemModel', () {
    test('is a subtype of BasketItem entity', () {
      expect(tBasketItemModel, isA<BasketItem>());
    });

    test('fromJson deserializes a valid JSON Map', () {
      final result = BasketItemModel.fromJson(tJson);
      expect(result, equals(tBasketItemModel));
      expect(result.medication.id, equals('med-para-500'));
      expect(result.quantite, equals(2));
      expect(result.precision, equals('Générique accepté si disponible'));
    });

    test('toJson serializes model to Map correctly with zero price field', () {
      final jsonResult = tBasketItemModel.toJson();
      expect(jsonResult, equals(tJson));
      final medMap = jsonResult['medication'] as Map<String, dynamic>;
      expect(medMap.containsKey('prix'), isFalse);
      expect(medMap.containsKey('price'), isFalse);
      expect(medMap.containsKey('tarif'), isFalse);
    });

    test('fromDomain converts BasketItem entity to BasketItemModel', () {
      const entity = BasketItem(
        medication: tMedication,
        quantite: 3,
        precision: 'Boîte de 16',
      );
      final model = BasketItemModel.fromDomain(entity);
      expect(model.quantite, equals(3));
      expect(model.precision, equals('Boîte de 16'));
      expect(model.toDomain(), equals(model));
    });
  });
}
