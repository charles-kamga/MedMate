import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';

void main() {
  group('BasketItem Entity', () {
    const sampleMedication = Medication(
      id: 'med-para-500',
      codeNational: 'CIP-3400936184729',
      nomCommercial: 'Paracétamol Biogaran',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '500 mg',
      necessiteOrdonnance: false,
    );

    const sampleMedication2 = Medication(
      id: 'med-amox-1000',
      codeNational: 'CIP-3400937192837',
      nomCommercial: 'Amoxicilline Arrow',
      dci: 'Amoxicilline',
      forme: 'Gélule',
      dosage: '1 g',
      necessiteOrdonnance: true,
    );

    const itemA = BasketItem(
      medication: sampleMedication,
      quantite: 2,
      precision: 'Générique accepté',
    );

    const itemB = BasketItem(
      medication: sampleMedication,
      quantite: 2,
      precision: 'Générique accepté',
    );

    const itemDifferent = BasketItem(
      medication: sampleMedication2,
      quantite: 1,
      precision: null,
    );

    test('supports value equality via props', () {
      expect(itemA, equals(itemB));
      expect(itemA, isNot(equals(itemDifferent)));
      expect(itemA.props, [
        sampleMedication,
        2,
        'Générique accepté',
      ]);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = itemA.copyWith(
        quantite: 5,
        precision: 'Boîte de 30 comprimés',
      );

      expect(updated.medication, equals(sampleMedication));
      expect(updated.quantite, equals(5));
      expect(updated.precision, equals('Boîte de 30 comprimés'));
    });
  });
}
