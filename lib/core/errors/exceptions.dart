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

class OrderAlreadyClaimedException implements Exception {
  const OrderAlreadyClaimedException([this.message = 'Cette commande a déjà été attribuée à une autre officine.']);
  final String message;

  @override
  String toString() => 'OrderAlreadyClaimedException: $message';
}

class WaveExpiredException implements Exception {
  const WaveExpiredException([this.message = 'La fenêtre de réponse pour cette vague est expirée (2 min).']);
  final String message;

  @override
  String toString() => 'WaveExpiredException: $message';
}

class InvalidOtpException implements Exception {
  const InvalidOtpException([this.message = 'Code OTP invalide.']);
  final String message;

  @override
  String toString() => 'InvalidOtpException: $message';
}

class ExpiredOtpException implements Exception {
  const ExpiredOtpException([this.message = 'Code OTP expiré (délai de validité de 2 heures dépassé).']);
  final String message;

  @override
  String toString() => 'ExpiredOtpException: $message';
}

class ConsumedOtpException implements Exception {
  const ConsumedOtpException([this.message = 'Ce code OTP a déjà été consommé.']);
  final String message;

  @override
  String toString() => 'ConsumedOtpException: $message';
}
