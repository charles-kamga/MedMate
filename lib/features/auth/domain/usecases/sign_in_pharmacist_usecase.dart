import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';

/// Paramètres requis pour authentifier un pharmacien d'officine.
class SignInPharmacistParams extends Equatable {
  const SignInPharmacistParams({
    required this.email,
    required this.password,
  });

  /// Adresse email professionnelle du pharmacien.
  final String email;

  /// Mot de passe du compte.
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Cas d'utilisation pour l'authentification d'un pharmacien d'officine.
class SignInPharmacistUseCase {
  const SignInPharmacistUseCase(this._repository);

  final AuthRepository _repository;

  /// Valide les paramètres et délègue l'authentification au dépôt.
  Future<Either<Failure, PharmacistProfile>> call(
    SignInPharmacistParams params,
  ) async {
    final trimmedEmail = params.email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return const Left(AuthFailure('Adresse email invalide.'));
    }

    if (params.password.length < 6) {
      return const Left(
        AuthFailure('Le mot de passe doit comporter au moins 6 caractères.'),
      );
    }

    return _repository.signInPharmacist(
      email: trimmedEmail,
      password: params.password,
    );
  }
}
