import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Envoi du code SMS OTP au numéro camerounais (+237)
final class SendOtpTriggered extends AuthEvent {
  const SendOtpTriggered(this.telephone);

  final String telephone;

  @override
  List<Object?> get props => [telephone];
}

/// Vérification du code OTP à 6 chiffres
final class VerifyOtpTriggered extends AuthEvent {
  const VerifyOtpTriggered({
    required this.telephone,
    required this.codeOtp,
  });

  final String telephone;
  final String codeOtp;

  @override
  List<Object?> get props => [telephone, codeOtp];
}

/// Continuer en mode anonyme sans inscription (Accès urgence)
final class ContinueAsGuestTriggered extends AuthEvent {
  const ContinueAsGuestTriggered();
}

/// Déconnexion
final class SignOutTriggered extends AuthEvent {
  const SignOutTriggered();
}
