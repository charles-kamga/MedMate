import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';

/// Contrat du dépôt d'authentification et de gestion de session Afya Santé.
abstract class AuthRepository {
  /// Récupère la session active courante (patient ou pharmacien).
  Future<Either<Failure, UserSession>> getCurrentSession();

  /// Authentifie un pharmacien d'officine avec email et mot de passe.
  Future<Either<Failure, PharmacistProfile>> signInPharmacist({
    required String email,
    required String password,
  });

  /// Déconnecte l'utilisateur actuel et nettoie les tokens locaux.
  Future<Either<Failure, void>> signOut();

  /// Initialise ou récupère une session patient éphémère/anonyme.
  Future<Either<Failure, PatientSession>> getOrCreatePatientSession({
    String? phoneNumber,
  });
}
