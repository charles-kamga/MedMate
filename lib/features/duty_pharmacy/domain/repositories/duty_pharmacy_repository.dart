import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';

/// Contrat abstrait du référentiel des officines de garde à Yaoundé.
abstract class DutyPharmacyRepository {
  /// Récupère la liste des officines de garde pour un quartier de Yaoundé à une date donnée.
  Future<Either<Failure, List<DutySchedule>>> getDutyPharmaciesByQuartier({
    required String quartier,
    DateTime? targetDate,
  });

  /// Récupère l'ensemble des plannings de garde actifs pour l'ensemble de la ville de Yaoundé.
  Future<Either<Failure, List<DutySchedule>>> getAllActiveDutySchedules({
    DateTime? targetDate,
  });
}
