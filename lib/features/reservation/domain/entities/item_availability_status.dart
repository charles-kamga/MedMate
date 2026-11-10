/// Statut de disponibilité d'un médicament communiqué au comptoir par le pharmacien.
enum ItemAvailabilityStatus {
  /// Médicament disponible en stock et réservable au comptoir.
  available,

  /// Médicament totalement indisponible ou rupture de stock.
  unavailable,

  /// Disponibilité conditionnelle (ex: substitution générique, quantité partielle,
  /// ou présentation impérative d'une ordonnance originale).
  conditional,
}
