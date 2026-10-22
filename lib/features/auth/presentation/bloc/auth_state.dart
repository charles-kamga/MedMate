import 'package:equatable/equatable.dart';
import '../../domain/entities/user_session.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// État initial non connecté
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Opération en cours (envoi SMS ou vérification)
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// SMS OTP expédié, en attente de saisie du code
final class AuthOtpSent extends AuthState {
  const AuthOtpSent(this.telephone);

  final String telephone;

  @override
  List<Object?> get props => [telephone];
}

/// Utilisateur authentifié avec numéro validé
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final UserSession session;

  @override
  List<Object?> get props => [session];
}

/// Mode invité / anonyme actif (urgence sans compte)
final class AuthGuest extends AuthState {
  const AuthGuest(this.session);

  final UserSession session;

  @override
  List<Object?> get props => [session];
}

/// Erreur d'authentification
final class AuthError extends AuthState {
  const AuthError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
