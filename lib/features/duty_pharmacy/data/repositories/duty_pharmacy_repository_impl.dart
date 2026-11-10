import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/duty_pharmacy/data/datasources/duty_pharmacy_data_source.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/duty_pharmacy/domain/repositories/duty_pharmacy_repository.dart';

/// Implémentation concrète du contrat DutyPharmacyRepository pour Afya Santé.
class DutyPharmacyRepositoryImpl implements DutyPharmacyRepository {
  const DutyPharmacyRepositoryImpl({required this.dataSource});

  final DutyPharmacyDataSource dataSource;

  @override
  Future<Either<Failure, List<DutySchedule>>> getDutyPharmaciesByQuartier({
    required String quartier,
    DateTime? targetDate,
  }) async {
    try {
      final models = await dataSource.getDutyPharmaciesByQuartier(
        quartier: quartier,
        targetDate: targetDate,
      );
      return Right(models.map((s) => s.toDomain()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DutySchedule>>> getAllActiveDutySchedules({
    DateTime? targetDate,
  }) async {
    try {
      final models = await dataSource.getAllActiveDutySchedules(
        targetDate: targetDate,
      );
      return Right(models.map((s) => s.toDomain()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
