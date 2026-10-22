import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/medication.dart';
import '../repositories/pharmacy_repository.dart';

class SearchMedicationsUseCase {
  const SearchMedicationsUseCase(this._repository);

  final PharmacyRepository _repository;

  Future<Either<Failure, List<Medication>>> call(String query) {
    final sanitized = query.trim();
    if (sanitized.isEmpty) {
      return Future.value(const Right([]));
    }
    return _repository.searchMedications(sanitized);
  }
}
