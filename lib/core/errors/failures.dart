import 'package:equatable/equatable.dart';

/// Hiérarchie scellée des échecs métier d'Afya Santé (Pattern Either<Failure, T>).
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Échec de connectivité ou timeout réseau (contexte 3G/4G à Yaoundé)
final class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Connexion réseau instable ou indisponible.',
  ]) : super(code: 'NETWORK_ERROR');
}

/// Erreur émanant de la base de données ou de l'API Supabase
final class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Erreur lors de la communication avec le serveur.',
  ]) : super(code: 'SERVER_ERROR');
}

/// Erreur d'accès au stockage local sécurisé ou cache hors-ligne
final class StorageFailure extends Failure {
  const StorageFailure([
    super.message = "Impossible d'accéder au stockage local.",
  ]) : super(code: 'STORAGE_ERROR');
}

/// Alias de compatibilité pour les erreurs de cache
final class CacheFailure extends Failure {
  const CacheFailure([
    super.message = "Impossible d'accéder au cache local.",
  ]) : super(code: 'CACHE_ERROR');
}

/// Échec lié au capteur GPS ou au refus de permission navigateur/OS
final class LocationFailure extends Failure {
  const LocationFailure([
    super.message =
        'Géolocalisation indisponible. Veuillez sélectionner votre quartier ou carrefour à Yaoundé.',
  ]) : super(code: 'LOCATION_ERROR');
}

/// Échec d'authentification ou d'autorisation RLS
final class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Identifiants invalides ou session expirée.',
  ]) : super(code: 'AUTH_ERROR');
}

/// Ressource introuvable (médicament ou officine)
final class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'La ressource demandée est introuvable.',
  ]) : super(code: 'NOT_FOUND');
}

/// Stock insuffisant ou indisponible au comptoir de l'officine
final class InsufficientStockFailure extends Failure {
  const InsufficientStockFailure([
    super.message = 'Produit indisponible dans cette officine.',
  ]) : super(code: 'INSUFFICIENT_STOCK');
}

/// Échec de réservation (délai TTL de 2h dépassé ou conflit d'idempotence)
final class ReservationFailure extends Failure {
  const ReservationFailure([
    super.message = "La réservation n'a pas pu être enregistrée.",
  ]) : super(code: 'RESERVATION_ERROR');
}

/// Échec de validation des paramètres ou des invariants métier
final class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Données de requête invalides ou incomplètes.',
  ]) : super(code: 'VALIDATION_ERROR');
}
