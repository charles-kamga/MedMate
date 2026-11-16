import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/duty_pharmacy_item.dart';
import '../../domain/repositories/duty_pharmacy_repository.dart';

/// Implémentation du référentiel des pharmacies de garde officielles
class DutyPharmacyRepositoryImpl implements DutyPharmacyRepository {
  const DutyPharmacyRepositoryImpl();

  static const List<String> defaultCities = [
    'Yaoundé',
    'Douala',
    'Bertoua',
    'Bafoussam',
  ];

  static const List<DutyPharmacyItem> defaultDutyPharmacies = [
    // Zone Pilote Yaoundé (Melen / Obili / Biyem-Assi) - Données réelles MboaPHARMA
    DutyPharmacyItem(
      name: 'Pharmacie Mandela Face CHU',
      quarter: 'Melen / Face CHU',
      activity: 'Zone Pilote Afya-Health',
      hours: 'Ouverte 24h/24 · Garde active',
      distance: '0,5 km',
      phone: '+237242792985',
      city: 'Yaoundé',
      latitude: 3.853898,
      longitude: 11.487012,
      isPartner: true,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie des Acacias',
      quarter: 'Biyem-Assi Centre',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '1,4 km',
      phone: '+237671038945',
      city: 'Yaoundé',
      latitude: 3.841540,
      longitude: 11.487958,
      isPartner: true,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie Well',
      quarter: 'Rond-Point Express / Biyem-Assi',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '1,9 km',
      phone: '+237698987832',
      city: 'Yaoundé',
      latitude: 3.837638,
      longitude: 11.485219,
      isPartner: true,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie Nsimeyong',
      quarter: 'Chapelle Nsimeyong',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '2,1 km',
      phone: '+237694011246',
      city: 'Yaoundé',
      latitude: 3.836074,
      longitude: 11.494335,
      isPartner: true,
    ),
    // DÉMO — données fictives (préservé pour tests existants Bastos)
    DutyPharmacyItem(
      name: 'Pharmacie de Bastos',
      quarter: 'Bastos',
      activity: 'Garde Nocturne',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '2,8 km',
      phone: '+237677334455',
      city: 'Yaoundé',
      latitude: 3.8880,
      longitude: 11.5120,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie Isis',
      quarter: 'Emombo 2e Carrefour',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '4,5 km',
      phone: '+237222233578',
      city: 'Yaoundé',
      latitude: 3.864770,
      longitude: 11.548491,
      isPartner: false,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie Saint Martin',
      quarter: 'Poste Centrale / Katios',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '3,2 km',
      phone: '+237222231869',
      city: 'Yaoundé',
      latitude: 3.8667,
      longitude: 11.5200,
      isPartner: false,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie Hortensia',
      quarter: 'Tsinga / Polyclinique',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '3,6 km',
      phone: '+237243607984',
      city: 'Yaoundé',
      latitude: 3.8820,
      longitude: 11.5050,
      isPartner: false,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie Bleue Plus',
      quarter: 'Ngousso / Hôpital Général',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '5,1 km',
      phone: '+237656036467',
      city: 'Yaoundé',
      latitude: 3.8890,
      longitude: 11.5450,
      isPartner: false,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie Sainte Élisabeth de Nkomo',
      quarter: 'Carrefour Nkomo',
      activity: 'Garde active MboaPHARMA',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '6,2 km',
      phone: '+237243153058',
      city: 'Yaoundé',
      latitude: 3.8480,
      longitude: 11.5620,
      isPartner: false,
    ),
    // DÉMO — données fictives (Douala)
    DutyPharmacyItem(
      name: 'Pharmacie d’Akwa',
      quarter: 'Boulevard de la Liberté',
      activity: 'Garde 24h/24',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '1,2 km',
      phone: '+237690112233',
      city: 'Douala',
      latitude: 4.0511,
      longitude: 9.7679,
    ),
  ];

  @override
  List<String> getSupportedCities() => defaultCities;

  @override
  Future<Either<Failure, List<DutyPharmacyItem>>> getDutyPharmacies({
    required String city,
  }) async {
    final items = defaultDutyPharmacies.where((p) => p.city == city).toList();
    return Right(items);
  }
}
