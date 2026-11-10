import 'package:equatable/equatable.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';

/// États d'authentification pour Afya Santé.
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial avant vérification de la session active.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// État de chargement lors d'une opération d'authentification ou de session.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Session patient active (anonyme ou identifiée par numéro de téléphone).
class AuthenticatedPatient extends AuthState {
  const AuthenticatedPatient(this.patientSession);

  final PatientSession patientSession;

  @override
  List<Object?> get props => [patientSession];
}

/// Profil pharmacien d'officine vérifié par l'ONPC et authentifié.
class AuthenticatedPharmacist extends AuthState {
  const AuthenticatedPharmacist(this.pharmacist);

  final PharmacistProfile pharmacist;

  @override
  List<Object?> get props => [pharmacist];
}

/// Aucune session active (utilisateur déconnecté).
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Échec lors d'une opération d'authentification ou de gestion de session.
class AuthError extends AuthState {
  const AuthError(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
