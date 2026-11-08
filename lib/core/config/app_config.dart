/// Configuration globale et centralisée de l'application
/// Permet un renommage instantané de l'application selon les décisions du groupe
class AppConfig {
  const AppConfig._();

  /// Nom officiel de travail de l'application (modifiable en 1 seconde)
  static const String appName = 'Afya Santé';

  /// Slogan officiel
  static const String appTagline = 'Recherche & Réservation de médicaments';

  /// Mention légale relative aux prix des médicaments (Principe fondamental Afya Santé)
  static const String pricePolicyNotice =
      'Afya Santé ne fixe jamais le prix des médicaments. Le montant est exclusivement renseigné et transmis par le pharmacien après examen de la demande.';

  /// Numéro d'urgence secours Yaoundé
  static const String emergencyPhone = '1510';
}
