/// Configuration globale et centralisée de l'application
/// Permet un renommage instantané de l'application selon les décisions du groupe
class AppConfig {
  const AppConfig._();

  /// Nom officiel de travail de l'application
  static const String appName = 'Afya-Health';

  /// Slogan officiel
  static const String appTagline = 'La santé, avec clarté.';

  /// Mention légale relative aux prix des médicaments (Principe fondamental Afya-Health)
  static const String pricePolicyNotice =
      'Afya-Health ne fixe jamais le prix des médicaments. Le montant est exclusivement renseigné et transmis par le pharmacien après examen de la demande.';

  /// Numéro d'urgence secours Yaoundé
  static const String emergencyPhone = '1510';

  /// Contacts officiels Afya-Health
  static const String clientSupportPhone = '+237 656 63 25 01';
  static const String pharmacySupportPhone = '+237 656 63 25 01 / +237 659 80 58 04';
  static const String officialEmail = 'deanstephan06.tf@gmail.com';

  /// Arbitrages V1 validés
  static const bool enableDeliveryInV1 = false;
  static const bool enableInAppPaymentInV1 = false;

  /// Construit l'URL souveraine OpenStreetMap pour localiser une officine ou repère
  static String buildOsmSearchUrl({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    return 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=16/$latitude/$longitude';
  }

  /// Construit une URL de recherche textuelle OpenStreetMap (Zéro Google Maps)
  static String buildOsmQueryUrl(String query) {
    final encoded = Uri.encodeComponent(query);
    return 'https://www.openstreetmap.org/search?query=$encoded';
  }
}
