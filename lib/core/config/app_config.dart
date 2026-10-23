/// Configuration globale et centralisée de l'application
/// Permet un renommage instantané de l'application selon les décisions du groupe
class AppConfig {
  const AppConfig._();

  /// Nom officiel de l'application (modifiable en 1 seconde)
  static const String appName = 'MedMate';

  /// Slogan officiel
  static const String appTagline = 'Santé & Pharmacies de garde';

  /// Mention légale relative aux prix des médicaments
  static const String pricePolicyNotice =
      'Prix fixé directement en officine selon la réglementation pharmaceutique en vigueur. Aucun paiement direct requis dans cette version.';

  /// Numéro d'urgence secours Yaoundé
  static const String emergencyPhone = '1510';
}
