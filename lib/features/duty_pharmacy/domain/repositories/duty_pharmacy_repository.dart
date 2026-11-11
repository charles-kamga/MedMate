import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/duty_pharmacy_item.dart';

/// Contrat du référentiel des pharmacies de garde (ONPC Cameroun)
abstract class DutyPharmacyRepository {
  /// Récupère la liste des pharmacies de garde pour une ville donnée
  Future<Either<Failure, List<DutyPharmacyItem>>> getDutyPharmacies({
    required String city,
  });

  /// Liste des villes couvertes par le programme de garde
  List<String> getSupportedCities();
}
