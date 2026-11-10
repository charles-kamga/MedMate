import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/data/models/medication_model.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';

void main() {
  const testModel = MedicationModel(
    id: 'med-001',
    codeNational: 'CIP-CMR-001',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  group('MedicationModel & Zéro Prix Invariant', () {
    test('is a subclass of Medication entity', () {
      expect(testModel, isA<Medication>());
    });

    test('fromJson deserializes valid JSON correctly', () {
      final json = <String, dynamic>{
        'id': 'med-001',
        'code_national': 'CIP-CMR-001',
        'nom_commercial': 'Paracétamol Biogaran',
        'dci': 'Paracétamol',
        'forme': 'Comprimé',
        'dosage': '500 mg',
        'necessite_ordonnance': false,
      };

      final result = MedicationModel.fromJson(json);

      expect(result, equals(testModel));
      expect(result.id, equals('med-001'));
      expect(result.codeNational, equals('CIP-CMR-001'));
      expect(result.nomCommercial, equals('Paracétamol Biogaran'));
      expect(result.dci, equals('Paracétamol'));
      expect(result.forme, equals('Comprimé'));
      expect(result.dosage, equals('500 mg'));
      expect(result.necessiteOrdonnance, isFalse);
    });

    test('toJson serializes model without price fields', () {
      final json = testModel.toJson();

      expect(json['id'], equals('med-001'));
      expect(json['code_national'], equals('CIP-CMR-001'));
      expect(json['nom_commercial'], equals('Paracétamol Biogaran'));
      expect(json['dci'], equals('Paracétamol'));
      expect(json['forme'], equals('Comprimé'));
      expect(json['dosage'], equals('500 mg'));
      expect(json['necessite_ordonnance'], isFalse);
    });

    test('INVARIANT INVIOLABLE: MedicationModel strictly contains NO price or tariff field', () {
      final json = testModel.toJson();
      final forbiddenKeywords = [
        'prix',
        'price',
        'tarif',
        'cost',
        'cout',
        'montant',
        'amount',
        'taux',
      ];

      for (final key in json.keys) {
        for (final forbidden in forbiddenKeywords) {
          expect(
            key.toLowerCase().contains(forbidden),
            isFalse,
            reason: 'MedicationModel DTO JSON must NOT contain price-related key "$key".',
          );
        }
      }

      for (final prop in testModel.props) {
        if (prop is String) {
          for (final forbidden in ['prix', 'price', 'fcfa', 'xaf']) {
            expect(
              prop.toLowerCase().contains(forbidden),
              isFalse,
              reason: 'MedicationModel props must NOT contain monetary terms.',
            );
          }
        }
      }
    });

    test('toDomain and fromDomain convert faithfully', () {
      final domain = testModel.toDomain();
      expect(domain, equals(testModel));

      final fromDomain = MedicationModel.fromDomain(domain);
      expect(fromDomain, equals(testModel));
    });

    test('copyWith updates specified fields', () {
      final updated = testModel.copyWith(
        nomCommercial: 'Doliprane',
        necessiteOrdonnance: true,
      );

      expect(updated.nomCommercial, equals('Doliprane'));
      expect(updated.necessiteOrdonnance, isTrue);
      expect(updated.id, equals(testModel.id));
    });
  });
}
