import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/core/usecases/no_params.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';

/// Récupère la session active de l'utilisateur (patient ou pharmacien).
class GetCurrentSessionUseCase {
  const GetCurrentSessionUseCase(this._repository);

  final AuthRepository _repository;

  /// Exécute la récupération de session.
  Future<Either<Failure, UserSession>> call([NoParams? params]) {
    return _repository.getCurrentSession();
  }
}
