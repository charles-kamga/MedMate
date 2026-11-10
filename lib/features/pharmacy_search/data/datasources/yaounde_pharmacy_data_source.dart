import 'dart:math' as math;
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/features/pharmacy_search/data/models/medication_model.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';

/// Contrat de la source de données pour la recherche de médicaments et d'officines à Yaoundé.
abstract class YaoundePharmacyDataSource {
  /// Recherche des médicaments dans le catalogue homologué par nom ou DCI.
  Future<List<MedicationModel>> searchMedications(String query);

  /// Recherche des officines à proximité par quartier, carrefour ou coordonnées WGS84.
  Future<List<PharmacyModel>> searchNearbyPharmacies({
    String? quartier,
    String? carrefourRepere,
    double? latitude,
    double? longitude,
    double? radiusMetres,
    bool? onlyOpen,
    bool? onlyDuty,
  });

  /// Récupère une officine spécifique par son identifiant unique.
  Future<PharmacyModel> getPharmacyById(String pharmacyId);
}

/// Implémentation en mémoire de la source de données avec catalogue homologué et officines de Yaoundé.
class YaoundePharmacyDataSourceImpl implements YaoundePharmacyDataSource {
  const YaoundePharmacyDataSourceImpl();

  /// Catalogue homologué des médicaments essentiels (Cameroun / Afrique Centrale).
  ///
  /// INVARIANT INVIOLABLE : STRICTEMENT AUCUN CHAMP DE PRIX OU DE TARIF.
  static const List<MedicationModel> seededMedications = [
    MedicationModel(
      id: 'med-001',
      codeNational: 'CIP-CMR-001',
      nomCommercial: 'Paracétamol Biogaran',
      dci: 'Paracétamol',
      forme: 'Comprimé',
      dosage: '500 mg',
      necessiteOrdonnance: false,
    ),
    MedicationModel(
      id: 'med-002',
      codeNational: 'CIP-CMR-002',
      nomCommercial: 'Efferalgan',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '1 g',
      necessiteOrdonnance: false,
    ),
    MedicationModel(
      id: 'med-003',
      codeNational: 'CIP-CMR-003',
      nomCommercial: 'Amoxicilline Sandoz',
      dci: 'Amoxicilline',
      forme: 'Gélule',
      dosage: '500 mg',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-004',
      codeNational: 'CIP-CMR-004',
      nomCommercial: 'Clamoxyl',
      dci: 'Amoxicilline',
      forme: 'Comprimé dispersible',
      dosage: '1 g',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-005',
      codeNational: 'CIP-CMR-005',
      nomCommercial: 'Coartem',
      dci: 'Artéméther / Luméfantrine',
      forme: 'Comprimé',
      dosage: '20 mg / 120 mg',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-006',
      codeNational: 'CIP-CMR-006',
      nomCommercial: 'Artefan',
      dci: 'Artéméther / Luméfantrine',
      forme: 'Comprimé',
      dosage: '20 mg / 120 mg',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-007',
      codeNational: 'CIP-CMR-007',
      nomCommercial: 'Ibuprofène Mylan',
      dci: 'Ibuprofène',
      forme: 'Comprimé enrobé',
      dosage: '400 mg',
      necessiteOrdonnance: false,
    ),
    MedicationModel(
      id: 'med-008',
      codeNational: 'CIP-CMR-008',
      nomCommercial: 'Advil',
      dci: 'Ibuprofène',
      forme: 'Capsule molle',
      dosage: '400 mg',
      necessiteOrdonnance: false,
    ),
    MedicationModel(
      id: 'med-009',
      codeNational: 'CIP-CMR-009',
      nomCommercial: 'Glucophage',
      dci: 'Metformine',
      forme: 'Comprimé pelliculé',
      dosage: '850 mg',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-010',
      codeNational: 'CIP-CMR-010',
      nomCommercial: 'Mopral',
      dci: 'Oméprazole',
      forme: 'Gélule gastro-résistante',
      dosage: '20 mg',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-011',
      codeNational: 'CIP-CMR-011',
      nomCommercial: 'Ciflox',
      dci: 'Ciprofloxacine',
      forme: 'Comprimé pelliculé',
      dosage: '500 mg',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-012',
      codeNational: 'CIP-CMR-012',
      nomCommercial: 'Zithromax',
      dci: 'Azithromycine',
      forme: 'Comprimé',
      dosage: '500 mg',
      necessiteOrdonnance: true,
    ),
    MedicationModel(
      id: 'med-013',
      codeNational: 'CIP-CMR-013',
      nomCommercial: 'Zyrtec',
      dci: 'Cétirizine',
      forme: 'Comprimé pelliculé sécable',
      dosage: '10 mg',
      necessiteOrdonnance: false,
    ),
    MedicationModel(
      id: 'med-014',
      codeNational: 'CIP-CMR-014',
      nomCommercial: 'Spasfon',
      dci: 'Phloroglucinol',
      forme: 'Comprimé',
      dosage: '80 mg',
      necessiteOrdonnance: false,
    ),
    MedicationModel(
      id: 'med-015',
      codeNational: 'CIP-CMR-015',
      nomCommercial: 'Voltarène',
      dci: 'Diclofénac',
      forme: 'Comprimé gastro-résistant',
      dosage: '50 mg',
      necessiteOrdonnance: true,
    ),
  ];

  /// Référentiel des officines de pharmacie à Yaoundé géoréférencées en WGS84.
  static const List<PharmacyModel> seededPharmacies = [
    PharmacyModel(
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
    ),
    PharmacyModel(
      id: 'pharma-mokolo-01',
      nom: 'Pharmacie du Marché Mokolo',
      licenceOnpc: 'ONPC-YDE-002',
      quartier: 'Mokolo',
      carrefourRepere: 'Marché Mokolo',
      latitude: 3.8740,
      longitude: 11.5020,
      telephoneGarde: '+237222214433',
      estOuverte: true,
      estDeGarde: false,
      estPartenaire: true,
    ),
    PharmacyModel(
      id: 'pharma-biyem-01',
      nom: 'Pharmacie Acacia Biyem-Assi',
      licenceOnpc: 'ONPC-YDE-003',
      quartier: 'Biyem-Assi',
      carrefourRepere: 'Carrefour Biyem-Assi (Acacia)',
      latitude: 3.8375,
      longitude: 11.4880,
      telephoneGarde: '+237222312211',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: true,
    ),
    PharmacyModel(
      id: 'pharma-omnisports-01',
      nom: 'Pharmacie du Stade',
      licenceOnpc: 'ONPC-YDE-004',
      quartier: 'Omnisports',
      carrefourRepere: 'Rond-Point Omnisports',
      latitude: 3.8860,
      longitude: 11.5400,
      telephoneGarde: '+237222225566',
      estOuverte: true,
      estDeGarde: false,
      estPartenaire: true,
    ),
    PharmacyModel(
      id: 'pharma-tsinga-01',
      nom: 'Pharmacie de Tsinga',
      licenceOnpc: 'ONPC-YDE-005',
      quartier: 'Tsinga',
      carrefourRepere: 'Carrefour MEEC',
      latitude: 3.8810,
      longitude: 11.4960,
      telephoneGarde: '+237222238899',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: true,
    ),
    PharmacyModel(
      id: 'pharma-essos-01',
      nom: 'Pharmacie de la Caisse Essos',
      licenceOnpc: 'ONPC-YDE-006',
      quartier: 'Essos',
      carrefourRepere: 'Carrefour Essos (Hôpital de la Caisse)',
      latitude: 3.8720,
      longitude: 11.5410,
      telephoneGarde: '+237222229988',
      estOuverte: true,
      estDeGarde: false,
      estPartenaire: false,
    ),
    PharmacyModel(
      id: 'pharma-mendong-01',
      nom: 'Pharmacie Mendong Soleil',
      licenceOnpc: 'ONPC-YDE-007',
      quartier: 'Mendong',
      carrefourRepere: 'Entrée Simbock / Mendong',
      latitude: 3.8290,
      longitude: 11.4710,
      telephoneGarde: '+237222315544',
      estOuverte: true,
      estDeGarde: false,
      estPartenaire: true,
    ),
    PharmacyModel(
      id: 'pharma-nsam-01',
      nom: 'Pharmacie Sud Nsam',
      licenceOnpc: 'ONPC-YDE-008',
      quartier: 'Nsam',
      carrefourRepere: 'Carrefour Nsam',
      latitude: 3.8310,
      longitude: 11.5180,
      telephoneGarde: '+237222306677',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: false,
    ),
    PharmacyModel(
      id: 'pharma-centre-01',
      nom: 'Grande Pharmacie du Centre',
      licenceOnpc: 'ONPC-YDE-009',
      quartier: 'Poste Centrale',
      carrefourRepere: 'Rond-Point Poste Centrale',
      latitude: 3.8667,
      longitude: 11.5200,
      telephoneGarde: '+237222220011',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: true,
    ),
    PharmacyModel(
      id: 'pharma-obili-01',
      nom: 'Pharmacie Universitaire Obili',
      licenceOnpc: 'ONPC-YDE-010',
      quartier: 'Obili',
      carrefourRepere: 'Carrefour Obili',
      latitude: 3.8540,
      longitude: 11.4920,
      telephoneGarde: '+237222231144',
      estOuverte: false,
      estDeGarde: false,
      estPartenaire: false,
    ),
  ];

  @override
  Future<List<MedicationModel>> searchMedications(String query) async {
    final cleanQuery = _normalize(query.trim());
    if (cleanQuery.length < 2) {
      return const [];
    }

    return seededMedications.where((med) {
      final nomCommercialNorm = _normalize(med.nomCommercial);
      final dciNorm = _normalize(med.dci);
      return nomCommercialNorm.contains(cleanQuery) ||
          dciNorm.contains(cleanQuery);
    }).toList();
  }

  @override
  Future<List<PharmacyModel>> searchNearbyPharmacies({
    String? quartier,
    String? carrefourRepere,
    double? latitude,
    double? longitude,
    double? radiusMetres,
    bool? onlyOpen,
    bool? onlyDuty,
  }) async {
    var result = List<PharmacyModel>.from(seededPharmacies);

    if (onlyOpen ?? false) {
      result = result.where((p) => p.estOuverte).toList();
    }

    if (onlyDuty ?? false) {
      result = result.where((p) => p.estDeGarde).toList();
    }

    if (quartier != null && quartier.trim().isNotEmpty) {
      final cleanQuartier = _normalize(quartier.trim());
      result = result
          .where((p) => _normalize(p.quartier).contains(cleanQuartier))
          .toList();
    }

    if (carrefourRepere != null && carrefourRepere.trim().isNotEmpty) {
      final cleanCarrefour = _normalize(carrefourRepere.trim());
      result = result
          .where((p) => _normalize(p.carrefourRepere).contains(cleanCarrefour))
          .toList();
    }

    if (latitude != null && longitude != null) {
      final withDistance = result.map((p) {
        final distance = calculateHaversineDistance(
          lat1: latitude,
          lon1: longitude,
          lat2: p.latitude,
          lon2: p.longitude,
        );
        return p.copyWith(distanceMetres: distance);
      }).toList();

      if (radiusMetres != null && radiusMetres > 0) {
        result = withDistance
            .where((p) => p.distanceMetres! <= radiusMetres)
            .toList();
      } else {
        result = withDistance;
      }

      result.sort((a, b) {
        final distA = a.distanceMetres ?? double.infinity;
        final distB = b.distanceMetres ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    return result;
  }

  @override
  Future<PharmacyModel> getPharmacyById(String pharmacyId) async {
    final match = seededPharmacies.where((p) => p.id == pharmacyId);
    if (match.isEmpty) {
      throw NotFoundException("L'officine '$pharmacyId' est introuvable.");
    }
    return match.first;
  }

  /// Calcule la distance grand-cercle (Haversine) en mètres entre deux points WGS84.
  static double calculateHaversineDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp('[ûüù]'), 'u')
        .replaceAll(RegExp('[ç]'), 'c');
  }
}
