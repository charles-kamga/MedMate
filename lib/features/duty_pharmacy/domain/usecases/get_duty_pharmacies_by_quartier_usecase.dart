import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/duty_pharmacy/domain/repositories/duty_pharmacy_repository.dart';

/// Paramètres pour la recherche des pharmacies de garde par quartier.
class GetDutyPharmaciesByQuartierParams extends Equatable {
  const GetDutyPharmaciesByQuartierParams({
    required this.quartier,
    this.targetDate,
  });

  /// Quartier de Yaoundé (ex: "Bastos", "Mokolo", "Biyem-Assi").
  final String quartier;

  /// Date cible facultative (par défaut: date/heure courante).
  final DateTime? targetDate;

  @override
  List<Object?> get props => [quartier, targetDate];
}

/// Cas d'utilisation: recherche des pharmacies d'officine de garde par quartier à Yaoundé.
///
/// Valide que le quartier est renseigné et interroge le référentiel homologué par l'ONPC.
class GetDutyPharmaciesByQuartierUseCase {
  const GetDutyPharmaciesByQuartierUseCase(this._repository);

  final DutyPharmacyRepository _repository;

  Future<Either<Failure, List<DutySchedule>>> call(
    GetDutyPharmaciesByQuartierParams params,
  ) async {
    final trimmedQuartier = params.quartier.trim();
    if (trimmedQuartier.isEmpty) {
      return const Left(
        LocationFailure('Le quartier doit être spécifié.'),
      );
    }

    return _repository.getDutyPharmaciesByQuartier(
      quartier: trimmedQuartier,
      targetDate: params.targetDate,
    );
  }
}
