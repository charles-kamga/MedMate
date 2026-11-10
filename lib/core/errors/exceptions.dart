/// Exceptions techniques lancées au sein de la couche Data
library;

class ServerException implements Exception {
  const ServerException([this.message = 'Erreur serveur Supabase', this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ServerException: $message (code: $statusCode)';
}

class CacheException implements Exception {
  const CacheException([this.message = 'Erreur cache SQLite']);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

class NetworkException implements Exception {
  const NetworkException([this.message = 'Erreur réseau']);
  final String message;

  @override
  String toString() => 'NetworkException: $message';
}

class LocationException implements Exception {
  const LocationException([this.message = 'Erreur capteur GPS']);
  final String message;

  @override
  String toString() => 'LocationException: $message';
}

class AuthException implements Exception {
  const AuthException([this.message = "Erreur d'authentification"]);
  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Ressource introuvable']);
  final String message;

  @override
  String toString() => 'NotFoundException: $message';
}
