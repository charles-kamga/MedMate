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
    DutyPharmacyItem(
      name: 'Grande Pharmacie du Centre',
      quarter: 'Poste Centrale',
      activity: 'Service d’Urgence',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '0,6 km',
      phone: '+237677112233',
      city: 'Yaoundé',
      latitude: 3.8665,
      longitude: 11.5205,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie du Soleil',
      quarter: 'Warda',
      activity: 'Officine Centrale',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '1,1 km',
      phone: '+237699223344',
      city: 'Yaoundé',
      latitude: 3.8692,
      longitude: 11.5170,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de Bastos',
      quarter: 'Bastos',
      activity: 'Garde Nocturne',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '2,3 km',
      phone: '+237677334455',
      city: 'Yaoundé',
      latitude: 3.8880,
      longitude: 11.5120,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de Melen',
      quarter: 'Melen / CHU',
      activity: 'Proximité Hôpital',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '2,8 km',
      phone: '+237655445566',
      city: 'Yaoundé',
      latitude: 3.8620,
      longitude: 11.4950,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie d’Obili',
      quarter: 'Obili',
      activity: 'Garde de Nuit',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '3,4 km',
      phone: '+237699556677',
      city: 'Yaoundé',
      latitude: 3.8542,
      longitude: 11.4925,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de Biyem-Assi',
      quarter: 'Rond-Point Express',
      activity: 'Zone Résidentielle',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '4,2 km',
      phone: '+237677667788',
      city: 'Yaoundé',
      latitude: 3.8372,
      longitude: 11.4885,
      isPartner: false,
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de l’Émergence',
      quarter: 'Omnisports',
      activity: 'Garde Principale',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '4,7 km',
      phone: '+237699778899',
      city: 'Yaoundé',
      latitude: 3.8825,
      longitude: 11.5410,
      isPartner: false,
    ),
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
    final items =
        defaultDutyPharmacies.where((p) => p.city == city).toList();
    return Right(items);
  }
}
