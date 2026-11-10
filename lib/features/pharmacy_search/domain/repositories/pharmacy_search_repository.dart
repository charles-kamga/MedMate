import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

/// Contrat du dépôt pour la recherche de médicaments et d'officines à Yaoundé.
abstract class PharmacySearchRepository {
  /// Recherche des médicaments par nom ou DCI (tolérance aux fautes / trigrammes).
  Future<Either<Failure, List<Medication>>> searchMedications(String query);

  /// Recherche des officines à proximité par quartier, carrefour ou coordonnées WGS84.
  Future<Either<Failure, List<Pharmacy>>> searchNearbyPharmacies({
    String? quartier,
    String? carrefourRepere,
    double? latitude,
    double? longitude,
    double? radiusMetres,
    bool? onlyOpen,
    bool? onlyDuty,
  });

  /// Récupère les détails d'une officine spécifique par son identifiant.
  Future<Either<Failure, Pharmacy>> getPharmacyById(String pharmacyId);
}
