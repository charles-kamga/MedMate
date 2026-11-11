import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/duty_pharmacy_item.dart';
import '../repositories/duty_pharmacy_repository.dart';

/// Cas d'utilisation : Récupérer les officines de garde par ville
class GetDutyPharmaciesUseCase {
  const GetDutyPharmaciesUseCase(this._repository);

  final DutyPharmacyRepository _repository;

  Future<Either<Failure, List<DutyPharmacyItem>>> call(String city) {
    return _repository.getDutyPharmacies(city: city);
  }
}
