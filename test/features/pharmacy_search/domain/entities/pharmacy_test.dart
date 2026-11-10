import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

void main() {
  group('Pharmacy Entity', () {
    const pharmacyA = Pharmacy(
      id: 'pharma-bastos-01',
      nom: 'Grande Pharmacie de Bastos',
      licenceOnpc: 'ONPC-CMR-1029',
      quartier: 'Bastos',
      carrefourRepere: 'Carrefour Warda',
      latitude: 3.8792,
      longitude: 11.5167,
      telephoneGarde: '+237699112233',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: true,
      distanceMetres: 450.5,
    );

    const pharmacyB = Pharmacy(
      id: 'pharma-bastos-01',
      nom: 'Grande Pharmacie de Bastos',
      licenceOnpc: 'ONPC-CMR-1029',
      quartier: 'Bastos',
      carrefourRepere: 'Carrefour Warda',
      latitude: 3.8792,
      longitude: 11.5167,
      telephoneGarde: '+237699112233',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: true,
      distanceMetres: 450.5,
    );

    const pharmacyOther = Pharmacy(
      id: 'pharma-obili-02',
      nom: 'Pharmacie du Soleil Obili',
      licenceOnpc: 'ONPC-CMR-2045',
      quartier: 'Obili',
      carrefourRepere: 'Carrefour Obili',
      latitude: 3.8541,
      longitude: 11.4982,
      telephoneGarde: '+237677223344',
      estOuverte: false,
      estDeGarde: false,
      estPartenaire: false,
    );

    test('supports value equality via props', () {
      expect(pharmacyA, equals(pharmacyB));
      expect(pharmacyA, isNot(equals(pharmacyOther)));
      expect(pharmacyA.props, [
        'pharma-bastos-01',
        'Grande Pharmacie de Bastos',
        'ONPC-CMR-1029',
        'Bastos',
        'Carrefour Warda',
        3.8792,
        11.5167,
        '+237699112233',
        true,
        true,
        true,
        450.5,
      ]);
    });

    test('supports nullable distanceMetres', () {
      expect(pharmacyOther.distanceMetres, isNull);
      expect(pharmacyOther.props.last, isNull);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = pharmacyA.copyWith(
        estOuverte: false,
        distanceMetres: 800,
      );

      expect(updated.id, equals('pharma-bastos-01'));
      expect(updated.estOuverte, isFalse);
      expect(updated.estDeGarde, isTrue);
      expect(updated.distanceMetres, equals(800));
      expect(updated.nom, equals('Grande Pharmacie de Bastos'));
    });
  });
}
