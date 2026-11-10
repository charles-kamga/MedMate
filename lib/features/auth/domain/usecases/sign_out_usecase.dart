import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/core/usecases/no_params.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';

/// Déconnecte l'utilisateur courant et révoque sa session active.
class SignOutUseCase {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  /// Exécute la déconnexion.
  Future<Either<Failure, void>> call([NoParams? params]) {
    return _repository.signOut();
  }
}
