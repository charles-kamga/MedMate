import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';

/// Utilitaires de sérialisation pour l'énumération ItemAvailabilityStatus.
class ItemAvailabilityStatusModel {
  const ItemAvailabilityStatusModel._();

  /// Parse une chaîne de caractères en statut de disponibilité d'article.
  static ItemAvailabilityStatus fromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'available':
      case 'disponible':
        return ItemAvailabilityStatus.available;
      case 'unavailable':
      case 'indisponible':
        return ItemAvailabilityStatus.unavailable;
      case 'conditional':
      case 'conditionnel':
        return ItemAvailabilityStatus.conditional;
      default:
        return ItemAvailabilityStatus.unavailable;
    }
  }

  /// Convertit un statut de disponibilité en chaîne JSON.
  static String toValue(ItemAvailabilityStatus status) => status.name;
}
