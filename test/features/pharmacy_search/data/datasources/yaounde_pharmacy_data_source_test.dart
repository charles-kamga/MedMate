import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/features/pharmacy_search/data/datasources/yaounde_pharmacy_data_source.dart';

void main() {
  late YaoundePharmacyDataSourceImpl dataSource;

  setUp(() {
    dataSource = const YaoundePharmacyDataSourceImpl();
  });

  group('YaoundePharmacyDataSourceImpl', () {
    group('searchMedications', () {
      test('returns empty list when query is shorter than 2 characters', () async {
        final result1 = await dataSource.searchMedications('');
        final result2 = await dataSource.searchMedications('p');
        final result3 = await dataSource.searchMedications('   ');

        expect(result1, isEmpty);
        expect(result2, isEmpty);
        expect(result3, isEmpty);
      });

      test('finds medication by exact or partial nomCommercial (case-insensitive)', () async {
        final results = await dataSource.searchMedications('paracétamol');

        expect(results, isNotEmpty);
        expect(results.any((m) => m.nomCommercial.contains('Paracétamol')), isTrue);
      });

      test('finds medication with accent-insensitive search', () async {
        final withAccent = await dataSource.searchMedications('paracétamol');
        final withoutAccent = await dataSource.searchMedications('paracetamol');

        expect(withAccent, isNotEmpty);
        expect(withoutAccent, isNotEmpty);
        expect(withAccent.length, equals(withoutAccent.length));
      });

      test('finds medication by DCI (e.g. artemether / amoxicilline)', () async {
        final results = await dataSource.searchMedications('artemether');

        expect(results, isNotEmpty);
        expect(results.any((m) => m.nomCommercial == 'Coartem'), isTrue);
      });

      test('returns empty list when no medication matches query', () async {
        final results = await dataSource.searchMedications('inexistant-medicament-xyz');
        expect(results, isEmpty);
      });
    });

    group('searchNearbyPharmacies', () {
      test('filters pharmacies by quartier (case-insensitive & accent-insensitive)', () async {
        final resultsBastos = await dataSource.searchNearbyPharmacies(quartier: 'bastos');
        expect(resultsBastos, isNotEmpty);
        expect(resultsBastos.every((p) => p.quartier == 'Bastos'), isTrue);

        final resultsBiyem = await dataSource.searchNearbyPharmacies(quartier: 'Biyem-Assi');
        expect(resultsBiyem, isNotEmpty);
        expect(resultsBiyem.any((p) => p.nom.contains('Acacia')), isTrue);
      });

      test('filters pharmacies by carrefourRepere', () async {
        final results = await dataSource.searchNearbyPharmacies(carrefourRepere: 'Warda');
        expect(results, isNotEmpty);
        expect(results.every((p) => p.carrefourRepere.contains('Warda')), isTrue);
      });

      test('filters pharmacies by onlyOpen flag', () async {
        final results = await dataSource.searchNearbyPharmacies(onlyOpen: true);
        expect(results, isNotEmpty);
        expect(results.every((p) => p.estOuverte), isTrue);
      });

      test('filters pharmacies by onlyDuty flag', () async {
        final results = await dataSource.searchNearbyPharmacies(onlyDuty: true);
        expect(results, isNotEmpty);
        expect(results.every((p) => p.estDeGarde), isTrue);
      });

      test('calculates Haversine distance and sorts ascending when coordinates provided', () async {
        // Point: Carrefour Warda (Bastos: 3.8688, 11.5175)
        final results = await dataSource.searchNearbyPharmacies(
          latitude: 3.8688,
          longitude: 11.5175,
        );

        expect(results, isNotEmpty);
        expect(results.first.distanceMetres, isNotNull);
        expect(results.first.id, equals('pharma-bastos-01'));
        expect(results.first.distanceMetres, lessThan(50));

        // Confirm ascending order of distance
        for (var i = 0; i < results.length - 1; i++) {
          final distCurrent = results[i].distanceMetres ?? 0;
          final distNext = results[i + 1].distanceMetres ?? 0;
          expect(distCurrent, lessThanOrEqualTo(distNext));
        }
      });

      test('filters by radiusMetres when specified with coordinates', () async {
        // Bastos coordinates with 1000m radius
        final results = await dataSource.searchNearbyPharmacies(
          latitude: 3.8688,
          longitude: 11.5175,
          radiusMetres: 1000,
        );

        expect(results, isNotEmpty);
        expect(results.every((p) => (p.distanceMetres ?? 0) <= 1000), isTrue);
      });
    });

    group('getPharmacyById', () {
      test('returns matching pharmacy when valid ID provided', () async {
        final pharmacy = await dataSource.getPharmacyById('pharma-bastos-01');

        expect(pharmacy.id, equals('pharma-bastos-01'));
        expect(pharmacy.nom, equals('Pharmacie de Bastos'));
      });

      test('throws NotFoundException when pharmacy ID does not exist', () async {
        expect(
          () => dataSource.getPharmacyById('pharma-inconnue-999'),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('calculateHaversineDistance', () {
      test('calculates correct distance between Carrefour Warda and Poste Centrale', () {
        // Warda: 3.8688, 11.5175; Poste Centrale: 3.8667, 11.5200
        final distance = YaoundePharmacyDataSourceImpl.calculateHaversineDistance(
          lat1: 3.8688,
          lon1: 11.5175,
          lat2: 3.8667,
          lon2: 11.5200,
        );

        // Geodesic distance in Yaoundé between these points is approx 350-400 meters
        expect(distance, greaterThan(300.0));
        expect(distance, lessThan(450.0));
      });
    });
  });
}
