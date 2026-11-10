import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';

void main() {
  group('Medication Entity & Zéro Prix Invariant', () {
    const medicationA = Medication(
      id: 'med-para-500',
      codeNational: 'CIP-3400936184729',
      nomCommercial: 'Paracétamol Biogaran',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '500 mg',
      necessiteOrdonnance: false,
    );

    const medicationB = Medication(
      id: 'med-para-500',
      codeNational: 'CIP-3400936184729',
      nomCommercial: 'Paracétamol Biogaran',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '500 mg',
      necessiteOrdonnance: false,
    );

    const medicationOther = Medication(
      id: 'med-amox-1000',
      codeNational: 'CIP-3400937192837',
      nomCommercial: 'Amoxicilline Arrow',
      dci: 'Amoxicilline',
      forme: 'Gélule',
      dosage: '1 g',
      necessiteOrdonnance: true,
    );

    test('supports value equality via props', () {
      expect(medicationA, equals(medicationB));
      expect(medicationA, isNot(equals(medicationOther)));
      expect(medicationA.props, [
        'med-para-500',
        'CIP-3400936184729',
        'Paracétamol Biogaran',
        'Paracétamol',
        'Comprimé effervescent',
        '500 mg',
        false,
      ]);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = medicationA.copyWith(
        nomCommercial: 'Efferalgan 500mg',
        forme: 'Comprimé orodispersible',
        necessiteOrdonnance: true,
      );

      expect(updated.id, equals('med-para-500'));
      expect(updated.codeNational, equals('CIP-3400936184729'));
      expect(updated.nomCommercial, equals('Efferalgan 500mg'));
      expect(updated.forme, equals('Comprimé orodispersible'));
      expect(updated.dosage, equals('500 mg'));
      expect(updated.necessiteOrdonnance, isTrue);
    });

    test('INVARIANT: Medication strictly contains NO price or monetary field', () {
      // 1. props contains exactly the 7 expected medical fields
      expect(medicationA.props.length, equals(7));

      // 2. props contains no numeric price values (num, double, int for prices)
      expect(medicationA.props.whereType<num>(), isEmpty);

      // 3. String representation contains no price-related vocabulary
      final stringified = medicationA.toString().toLowerCase();
      expect(stringified, isNot(contains('prix')));
      expect(stringified, isNot(contains('price')));
      expect(stringified, isNot(contains('cout')));
      expect(stringified, isNot(contains('tarif')));
      expect(stringified, isNot(contains('montant')));
      expect(stringified, isNot(contains('fcfa')));
    });
  });
}
