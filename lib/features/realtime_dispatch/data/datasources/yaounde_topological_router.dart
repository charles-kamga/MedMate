import 'dart:math' as math;
import '../../../../core/constants/yaounde_landmarks.dart';

/// Vague de dispatching géospatial selon l'isochrone urbain de Yaoundé
enum DispatchWaveTier {
  /// Vague 1 : Zone immédiate (< 5 minutes en mototaxi / circulation fluide)
  wave1Immediate,

  /// Vague 2 : Corridors artériels connectés (5 à 15 minutes)
  wave2Arterial,

  /// Vague 3 : Périmètre élargi (> 15 minutes)
  wave3Extended,
}

/// Résultat du calcul d'itinéraire topologique
class TopologicalRouteResult {
  const TopologicalRouteResult({
    required this.originLandmarkId,
    required this.destinationLandmarkId,
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.waveTier,
    required this.corridorName,
  });

  final String originLandmarkId;
  final String destinationLandmarkId;
  final double distanceKm;
  final int estimatedMinutes;
  final DispatchWaveTier waveTier;
  final String corridorName;
}

/// Routeur topologique urbain pour Yaoundé (PostGIS compatible)
/// Modélise les grands axes routiers et les carrefours névralgiques de Yaoundé
/// pour un dispatching en vagues réaliste (topologie vs simple vol d'oiseau).
class YaoundeTopologicalRouter {
  YaoundeTopologicalRouter();

  /// Référentiel enrichi des repères majeurs de Yaoundé
  static const List<YaoundeLandmark> yaoundeLandmarks = [
    YaoundeLandmark(
      id: 'carrefour-warda',
      nom: 'Carrefour Warda',
      quartier: 'Poste Centrale',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8688,
      longitude: 11.5175,
      description: 'Face au Bois Sainte-Anastasie, jonction Centre et Bastos',
    ),
    YaoundeLandmark(
      id: 'poste-centrale',
      nom: 'Rond-Point Poste Centrale',
      quartier: 'Poste Centrale',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8667,
      longitude: 11.5200,
      description: 'Cœur administratif et commercial de Yaoundé',
    ),
    YaoundeLandmark(
      id: 'carrefour-obili',
      nom: 'Carrefour Obili',
      quartier: 'Obili',
      arrondissement: 'Yaoundé 3e',
      latitude: 3.8540,
      longitude: 11.4920,
      description: 'Chapelle Obili, zone universitaire Ngoa-Ekellé',
    ),
    YaoundeLandmark(
      id: 'carrefour-nlongkak',
      nom: 'Carrefour Nlongkak',
      quartier: 'Nlongkak',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8833,
      longitude: 11.5250,
      description: 'Rond-point Nlongkak vers Dragages et Bastos',
    ),
    YaoundeLandmark(
      id: 'carrefour-acacia',
      nom: 'Carrefour Biyem-Assi (Acacia)',
      quartier: 'Biyem-Assi',
      arrondissement: 'Yaoundé 6e',
      latitude: 3.8375,
      longitude: 11.4880,
      description: 'Carrefour Acacia, axe commerçant dense',
    ),
    YaoundeLandmark(
      id: 'carrefour-emia',
      nom: 'Carrefour EMIA',
      quartier: 'Ngoa-Ekellé',
      arrondissement: 'Yaoundé 3e',
      latitude: 3.8610,
      longitude: 11.5050,
      description: 'Proximité CHU de Yaoundé et École Militaire',
    ),
    YaoundeLandmark(
      id: 'marche-mokolo',
      nom: 'Marché Mokolo',
      quartier: 'Mokolo',
      arrondissement: 'Yaoundé 2e',
      latitude: 3.8740,
      longitude: 11.5020,
      description: 'Entrée principale marché Mokolo vers Madagascar',
    ),
    YaoundeLandmark(
      id: 'rond-point-bastos',
      nom: 'Rond-Point Bastos',
      quartier: 'Bastos',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8930,
      longitude: 11.5120,
      description: 'Zone des ambassades et restaurants Bastos',
    ),
    YaoundeLandmark(
      id: 'rond-point-biyem-assi',
      nom: 'Rond-Point Express Biyem-Assi',
      quartier: 'Biyem-Assi',
      arrondissement: 'Yaoundé 6e',
      latitude: 3.8320,
      longitude: 11.4810,
      description: 'Jonction Biyem-Assi - Mendong - Rond-Point Express',
    ),
    YaoundeLandmark(
      id: 'carrefour-essos',
      nom: 'Carrefour Essos',
      quartier: 'Essos',
      arrondissement: 'Yaoundé 5e',
      latitude: 3.8690,
      longitude: 11.5420,
      description: 'Axe Essos - Coron - Hôpital Général',
    ),
    YaoundeLandmark(
      id: 'rond-point-tsinga',
      nom: 'Rond-Point Tsinga',
      quartier: 'Tsinga',
      arrondissement: 'Yaoundé 2e',
      latitude: 3.8820,
      longitude: 11.5040,
      description: 'Sous-préfecture Tsinga, proche Foire et Bastos',
    ),
  ];

  /// Matrice d'adjacence des corridors routiers directs (minutes typiques en heure normale)
  static final Map<String, Map<String, int>> _arterialCorridorDurations = {
    'carrefour-warda': {
      'poste-centrale': 3,
      'carrefour-emia': 4,
      'rond-point-bastos': 5,
      'carrefour-nlongkak': 5,
      'marche-mokolo': 6,
    },
    'poste-centrale': {
      'carrefour-warda': 3,
      'carrefour-emia': 5,
      'carrefour-essos': 7,
      'carrefour-nlongkak': 6,
    },
    'carrefour-obili': {
      'carrefour-emia': 3,
      'carrefour-acacia': 5,
      'rond-point-biyem-assi': 6,
      'marche-mokolo': 8,
    },
    'carrefour-emia': {
      'carrefour-obili': 3,
      'carrefour-warda': 4,
      'poste-centrale': 5,
      'carrefour-acacia': 6,
    },
    'carrefour-nlongkak': {
      'carrefour-warda': 5,
      'poste-centrale': 6,
      'rond-point-bastos': 4,
      'rond-point-tsinga': 5,
      'carrefour-essos': 8,
    },
    'carrefour-acacia': {
      'carrefour-obili': 5,
      'rond-point-biyem-assi': 3,
      'carrefour-emia': 6,
    },
    'rond-point-biyem-assi': {
      'carrefour-acacia': 3,
      'carrefour-obili': 6,
    },
    'marche-mokolo': {
      'rond-point-tsinga': 4,
      'carrefour-warda': 6,
      'carrefour-obili': 8,
      'rond-point-bastos': 7,
    },
    'rond-point-tsinga': {
      'marche-mokolo': 4,
      'carrefour-nlongkak': 5,
      'rond-point-bastos': 5,
    },
    'rond-point-bastos': {
      'carrefour-warda': 5,
      'carrefour-nlongkak': 4,
      'rond-point-tsinga': 5,
    },
    'carrefour-essos': {
      'poste-centrale': 7,
      'carrefour-nlongkak': 8,
    },
  };

  /// Retourne tous les repères connus
  List<YaoundeLandmark> getAllLandmarks() => yaoundeLandmarks;

  /// Trouve un repère par son identifiant
  YaoundeLandmark? findLandmarkById(String id) {
    try {
      return yaoundeLandmarks.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Trouve le repère le plus proche des coordonnées GPS données (Haversine)
  YaoundeLandmark findNearestLandmark({
    required double latitude,
    required double longitude,
  }) {
    var nearest = yaoundeLandmarks.first;
    var minDistance = double.infinity;

    for (final landmark in yaoundeLandmarks) {
      final dist = calculateHaversineDistanceKm(
        latitude,
        longitude,
        landmark.latitude,
        landmark.longitude,
      );
      if (dist < minDistance) {
        minDistance = dist;
        nearest = landmark;
      }
    }
    return nearest;
  }

  /// Calcule la distance orthodromique de Haversine en kilomètres
  double calculateHaversineDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return double.parse((earthRadiusKm * c).toStringAsFixed(2));
  }

  /// Calcule l'itinéraire topologique et la vague correspondante
  TopologicalRouteResult calculateTopologicalRoute(
    String originId,
    String destinationId,
  ) {
    if (originId == destinationId) {
      return TopologicalRouteResult(
        originLandmarkId: originId,
        destinationLandmarkId: destinationId,
        distanceKm: 0.1,
        estimatedMinutes: 2,
        waveTier: DispatchWaveTier.wave1Immediate,
        corridorName: 'Zone immédiate',
      );
    }

    final originLandmark = findLandmarkById(originId);
    final destLandmark = findLandmarkById(destinationId);

    final haversineDist = (originLandmark != null && destLandmark != null)
        ? calculateHaversineDistanceKm(
            originLandmark.latitude,
            originLandmark.longitude,
            destLandmark.latitude,
            destLandmark.longitude,
          )
        : 2.5;

    // Vérifier la présence d'un corridor artériel direct
    final directCorridors = _arterialCorridorDurations[originId];
    if (directCorridors != null && directCorridors.containsKey(destinationId)) {
      final minutes = directCorridors[destinationId]!;
      final tier = minutes <= 5
          ? DispatchWaveTier.wave1Immediate
          : (minutes <= 15 ? DispatchWaveTier.wave2Arterial : DispatchWaveTier.wave3Extended);
      return TopologicalRouteResult(
        originLandmarkId: originId,
        destinationLandmarkId: destinationId,
        distanceKm: haversineDist,
        estimatedMinutes: minutes,
        waveTier: tier,
        corridorName: 'Corridor direct $originId -> $destinationId',
      );
    }

    // Calcul par défaut basé sur la distance topologique urbaine (vitesse urbaine moyenne 20 km/h)
    final estimatedMinutes = math.max(3, (haversineDist * 3.5).round());
    final tier = estimatedMinutes <= 5
        ? DispatchWaveTier.wave1Immediate
        : (estimatedMinutes <= 15
            ? DispatchWaveTier.wave2Arterial
            : DispatchWaveTier.wave3Extended);

    return TopologicalRouteResult(
      originLandmarkId: originId,
      destinationLandmarkId: destinationId,
      distanceKm: haversineDist,
      estimatedMinutes: estimatedMinutes,
      waveTier: tier,
      corridorName: 'Axe urbain Yaoundé',
    );
  }

  /// Retourne la liste des identifiants de repères éligibles pour une vague donnée
  List<String> getEligibleLandmarksForWave(String originId, int waveNumber) {
    final eligible = <String>[];
    for (final landmark in yaoundeLandmarks) {
      final route = calculateTopologicalRoute(originId, landmark.id);
      if (waveNumber == 1 && route.waveTier == DispatchWaveTier.wave1Immediate) {
        eligible.add(landmark.id);
      } else if (waveNumber == 2 &&
          (route.waveTier == DispatchWaveTier.wave1Immediate ||
              route.waveTier == DispatchWaveTier.wave2Arterial)) {
        eligible.add(landmark.id);
      } else if (waveNumber >= 3) {
        eligible.add(landmark.id);
      }
    }
    return eligible;
  }

  static double _degreesToRadians(double degrees) => degrees * math.pi / 180.0;
}
