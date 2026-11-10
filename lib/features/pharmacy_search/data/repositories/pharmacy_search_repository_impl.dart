import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/data/datasources/yaounde_pharmacy_data_source.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_search_repository.dart';

/// Implémentation concrète du contrat PharmacySearchRepository pour Afya Santé.
class PharmacySearchRepositoryImpl implements PharmacySearchRepository {
  const PharmacySearchRepositoryImpl({required this.dataSource});

  final YaoundePharmacyDataSource dataSource;

  @override
  Future<Either<Failure, List<Medication>>> searchMedications(String query) async {
    try {
      final models = await dataSource.searchMedications(query);
      return Right(models.map((m) => m.toDomain()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Pharmacy>>> searchNearbyPharmacies({
    String? quartier,
    String? carrefourRepere,
    double? latitude,
    double? longitude,
    double? radiusMetres,
    bool? onlyOpen,
    bool? onlyDuty,
  }) async {
    try {
      final models = await dataSource.searchNearbyPharmacies(
        quartier: quartier,
        carrefourRepere: carrefourRepere,
        latitude: latitude,
        longitude: longitude,
        radiusMetres: radiusMetres,
        onlyOpen: onlyOpen,
        onlyDuty: onlyDuty,
      );
      return Right(models.map((p) => p.toDomain()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Pharmacy>> getPharmacyById(String pharmacyId) async {
    try {
      final model = await dataSource.getPharmacyById(pharmacyId);
      return Right(model.toDomain());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
