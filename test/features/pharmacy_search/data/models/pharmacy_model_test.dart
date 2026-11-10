import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

void main() {
  const testModel = PharmacyModel(
    id: 'pharma-bastos-01',
    nom: 'Pharmacie de Bastos',
    licenceOnpc: 'ONPC-YDE-001',
    quartier: 'Bastos',
    carrefourRepere: 'Carrefour Warda',
    latitude: 3.8688,
    longitude: 11.5175,
    telephoneGarde: '+237222201122',
    estOuverte: true,
    estDeGarde: true,
    estPartenaire: true,
    distanceMetres: 450.5,
  );

  group('PharmacyModel', () {
    test('is a subclass of Pharmacy entity', () {
      expect(testModel, isA<Pharmacy>());
    });

    test('fromJson deserializes complete JSON correctly', () {
      final json = <String, dynamic>{
        'id': 'pharma-bastos-01',
        'nom': 'Pharmacie de Bastos',
        'licence_onpc': 'ONPC-YDE-001',
        'quartier': 'Bastos',
        'carrefour_repere': 'Carrefour Warda',
        'latitude': 3.8688,
        'longitude': 11.5175,
        'telephone_garde': '+237222201122',
        'est_ouverte': true,
        'est_de_garde': true,
        'est_partenaire': true,
        'distance_metres': 450.5,
      };

      final result = PharmacyModel.fromJson(json);

      expect(result, equals(testModel));
      expect(result.id, equals('pharma-bastos-01'));
      expect(result.quartier, equals('Bastos'));
      expect(result.carrefourRepere, equals('Carrefour Warda'));
      expect(result.latitude, equals(3.8688));
      expect(result.longitude, equals(11.5175));
      expect(result.estPartenaire, isTrue);
      expect(result.distanceMetres, equals(450.5));
    });

    test('fromJson handles null distance_metres correctly', () {
      final json = <String, dynamic>{
        'id': 'pharma-mokolo-01',
        'nom': 'Pharmacie du Marché Mokolo',
        'licence_onpc': 'ONPC-YDE-002',
        'quartier': 'Mokolo',
        'carrefour_repere': 'Marché Mokolo',
        'latitude': 3.8740,
        'longitude': 11.5020,
        'telephone_garde': '+237222214433',
        'est_ouverte': true,
        'est_de_garde': false,
        'est_partenaire': true,
        'distance_metres': null,
      };

      final result = PharmacyModel.fromJson(json);

      expect(result.distanceMetres, isNull);
      expect(result.estDeGarde, isFalse);
    });

    test('toJson serializes model correctly', () {
      final json = testModel.toJson();

      expect(json['id'], equals('pharma-bastos-01'));
      expect(json['nom'], equals('Pharmacie de Bastos'));
      expect(json['licence_onpc'], equals('ONPC-YDE-001'));
      expect(json['quartier'], equals('Bastos'));
      expect(json['carrefour_repere'], equals('Carrefour Warda'));
      expect(json['latitude'], equals(3.8688));
      expect(json['longitude'], equals(11.5175));
      expect(json['telephone_garde'], equals('+237222201122'));
      expect(json['est_ouverte'], isTrue);
      expect(json['est_de_garde'], isTrue);
      expect(json['est_partenaire'], isTrue);
      expect(json['distance_metres'], equals(450.5));
    });

    test('toDomain and fromDomain convert faithfully', () {
      final domain = testModel.toDomain();
      expect(domain, equals(testModel));

      final fromDomain = PharmacyModel.fromDomain(domain);
      expect(fromDomain, equals(testModel));
    });

    test('copyWith updates specified fields', () {
      final updated = testModel.copyWith(
        distanceMetres: 1200,
        estOuverte: false,
      );

      expect(updated.distanceMetres, equals(1200));
      expect(updated.estOuverte, isFalse);
      expect(updated.id, equals(testModel.id));
    });
  });
}
