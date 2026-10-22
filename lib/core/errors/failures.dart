import 'package:equatable/equatable.dart';

/// Hiérarchie scellée pour les échecs métier de MedMate
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Échec de connectivité ou timeout (réseau 3G/EDGE instable)
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Connexion réseau instable ou indisponible à Yaoundé.',
    super.code = 'NETWORK_ERROR',
  ]);
}

/// Erreur émanant de la base de données ou de l'API Supabase
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Une erreur est survenue lors de la communication serveur.',
    super.code = 'SERVER_ERROR',
  ]);
}

/// Erreur de lecture/écriture dans le cache local SQLite chiffré
final class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Impossible d''accéder au stockage local sécurisé.',
    super.code = 'CACHE_ERROR',
  ]);
}

/// Échec lié au capteur GPS ou à la permission de géolocalisation
final class LocationFailure extends Failure {
  const LocationFailure([
    super.message = 'Impossible de déterminer votre position géographique.',
    super.code = 'LOCATION_ERROR',
  ]);
}

/// Échec d'authentification ou session expirée
final class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Session expirée ou code de vérification SMS incorrect.',
    super.code = 'AUTH_ERROR',
  ]);
}

/// Ressource introuvable (médicament non homologué, officine introuvable)
final class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'La ressource demandée n''a pas été trouvée.',
    super.code = 'NOT_FOUND',
  ]);
}

/// Échec de réservation (délai dépassé ou quota atteint)
final class ReservationFailure extends Failure {
  const ReservationFailure([
    super.message = 'La réservation n''a pas pu être confirmée.',
    super.code = 'RESERVATION_ERROR',
  ]);
}
