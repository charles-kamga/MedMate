/// Configuration globale et invariants métier d'Afya Santé (MedMate).
class AppConfig {
  const AppConfig._();

  /// Nom officiel du produit
  static const String appName = 'Afya Santé';

  /// Slogan officiel (Web & Mobile — Yaoundé)
  static const String appTagline =
      'Disponibilité de médicaments & Pharmacies de garde à Yaoundé';

  /// Invariant 1 — Politique Zéro Prix Affiché (Tarification au Comptoir)
  static const String pricePolicyNotice =
      'Afya Santé ne fixe et n’affiche aucun prix catalogue. '
      'Le tarif et la disponibilité finale sont confirmés exclusivement au comptoir par le pharmacien.';

  /// Numéro d'urgence secours médical Cameroun / Yaoundé
  static const String emergencyPhone = '1510';

  // ===========================================================================
  // INVARIANT 2 — SOUVERAINETÉ CARTOGRAPHIQUE OPENSTREETMAP (OSM)
  // ===========================================================================

  /// Fournisseur cartographique souverain unique (zéro dépendance propriétaire)
  static const String mapProviderName = 'OpenStreetMap';

  /// Modèle d'URL du serveur de tuiles OpenStreetMap France
  static const String osmFranceTileUrlTemplate =
      'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png';

  /// Alias de compatibilité pour le serveur de tuiles OSM France
  static const String osmFranceTileUrl = osmFranceTileUrlTemplate;

  /// Serveur de tuiles OpenStreetMap Standard (secours)
  static const String osmStandardTileUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Sous-domaines de répartition de charge OSM France
  static const List<String> osmSubdomains = ['a', 'b', 'c'];

  /// User-Agent déclaré conformément à la Tile Usage Policy d'OpenStreetMap
  static const String osmUserAgent = 'cm.afyasante.app';

  /// Coordonnées centrales de référence à Yaoundé (Rond-Point Poste Centrale)
  static const double yaoundeLatitude = 3.8667;
  static const double yaoundeLongitude = 11.5200;
  static const double defaultMapZoom = 13.8;

  /// Attribution légale obligatoire OpenStreetMap (Licence ODbL)
  static const String osmAttribution = '© Contributeurs OpenStreetMap (ODbL)';

  /// Génère une URL de recherche ou d'itinéraire externe sur OpenStreetMap
  static String buildOsmSearchUrl(String query) {
    final encoded = Uri.encodeComponent('$query Yaoundé Cameroun');
    return 'https://www.openstreetmap.org/search?query=$encoded';
  }

  /// Génère une URL pointant vers des coordonnées exactes sur OpenStreetMap
  static String buildOsmPointUrl({
    required double latitude,
    required double longitude,
    int zoom = 16,
  }) {
    return 'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=$zoom/$latitude/$longitude';
  }

  // ===========================================================================
  // GRILLE DE BREAKPOINTS RESPONSIVE (WEB & MOBILE) & RÉSILIENCE RÉSEAU
  // ===========================================================================

  /// Seuil maximal pour l'affichage Mobile Compact (< 600px)
  static const double compactBreakpoint = 600;

  /// Seuil minimal pour l'affichage Desktop Comptoir Officine (>= 1024px)
  static const double expandedBreakpoint = 1024;

  /// Timeout réseau strict adapté au contexte mobile 3G/4G à Yaoundé (10s max)
  static const Duration networkTimeout = Duration(seconds: 10);

  /// Durée de validité maximale d'une réservation au comptoir (2 heures)
  static const Duration reservationTtl = Duration(hours: 2);
}
