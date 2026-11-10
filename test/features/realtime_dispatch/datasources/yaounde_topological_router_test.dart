import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/realtime_dispatch/data/datasources/yaounde_topological_router.dart';

void main() {
  late YaoundeTopologicalRouter router;

  setUp(() {
    router = YaoundeTopologicalRouter();
  });

  group('YaoundeTopologicalRouter Tests', () {
    test('getAllLandmarks contains all required landmarks for Yaounde', () {
      final landmarks = router.getAllLandmarks();
      final ids = landmarks.map((l) => l.id).toList();

      expect(ids, contains('carrefour-warda'));
      expect(ids, contains('poste-centrale'));
      expect(ids, contains('carrefour-obili'));
      expect(ids, contains('carrefour-nlongkak'));
      expect(ids, contains('carrefour-acacia'));
      expect(ids, contains('carrefour-emia'));
      expect(ids, contains('marche-mokolo'));
      expect(ids, contains('rond-point-bastos'));
      expect(ids, contains('rond-point-biyem-assi'));
      expect(ids, contains('carrefour-essos'));
      expect(ids, contains('rond-point-tsinga'));
    });

    test('findLandmarkById returns valid landmark or null', () {
      final warda = router.findLandmarkById('carrefour-warda');
      expect(warda, isNotNull);
      expect(warda!.nom, equals('Carrefour Warda'));
      expect(warda.quartier, equals('Poste Centrale'));

      final nonExistent = router.findLandmarkById('invalid-id');
      expect(nonExistent, isNull);
    });

    test('findNearestLandmark correctly identifies nearest landmark', () {
      // Coordonnées très proches de Carrefour Warda (3.8688, 11.5175)
      final nearest = router.findNearestLandmark(
        latitude: 3.8690,
        longitude: 11.5177,
      );

      expect(nearest.id, equals('carrefour-warda'));
    });

    test('calculateHaversineDistanceKm computes realistic distance', () {
      // Warda (3.8688, 11.5175) et Poste Centrale (3.8667, 11.5200)
      final dist = router.calculateHaversineDistanceKm(
        3.8688,
        11.5175,
        3.8667,
        11.5200,
      );

      // Distance à Yaoundé environ 0.36 km
      expect(dist, greaterThan(0.2));
      expect(dist, lessThan(1.0));
    });

    test('calculateTopologicalRoute for immediate zone classifies as Wave 1', () {
      final route = router.calculateTopologicalRoute('carrefour-warda', 'poste-centrale');

      expect(route.waveTier, equals(DispatchWaveTier.wave1Immediate));
      expect(route.estimatedMinutes, lessThanOrEqualTo(5));
      expect(route.corridorName, contains('Corridor direct'));
    });

    test('calculateTopologicalRoute for arterial corridors classifies as Wave 2', () {
      final route = router.calculateTopologicalRoute('carrefour-warda', 'marche-mokolo');

      expect(route.waveTier, equals(DispatchWaveTier.wave2Arterial));
      expect(route.estimatedMinutes, greaterThan(5));
      expect(route.estimatedMinutes, lessThanOrEqualTo(15));
    });

    test('getEligibleLandmarksForWave expands properly between Wave 1 and Wave 2', () {
      final wave1 = router.getEligibleLandmarksForWave('carrefour-warda', 1);
      final wave2 = router.getEligibleLandmarksForWave('carrefour-warda', 2);

      expect(wave1, contains('carrefour-warda'));
      expect(wave1, contains('poste-centrale'));
      expect(wave2.length, greaterThanOrEqualTo(wave1.length));
      expect(wave2, contains('marche-mokolo'));
    });
  });
}
