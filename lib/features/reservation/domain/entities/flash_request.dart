import 'package:equatable/equatable.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';

/// Statut du cycle de vie d'une demande flash de disponibilité.
enum FlashRequestStatus {
  /// Demande créée en attente de notification des officines.
  pending,

  /// Demande active diffusée aux officines de la vague courante.
  active,

  /// Au moins une offre a été reçue d'une officine.
  partiallyAnswered,

  /// Offre acceptée par le patient et réservation confirmée.
  fulfilled,

  /// Demande expirée sans confirmation dans le délai imparti.
  expired,

  /// Demande annulée par le patient.
  cancelled,
}

/// Demande flash de disponibilité multi-officines à Yaoundé.
class FlashRequest extends Equatable {
  const FlashRequest({
    required this.id,
    required this.clientRequestId,
    required this.items,
    required this.quartierOuCarrefour,
    required this.statut,
    required this.vagueActuelle,
    required this.pharmaciesNotifieesIds,
    required this.offresRecues,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Identifiant unique de la demande côté serveur (UUID).
  final String id;

  /// Identifiant d'idempotence généré côté client (UUID v4).
  final String clientRequestId;

  /// Médicaments et quantités recherchés.
  final List<BasketItem> items;

  /// Repère urbain de localisation (quartier ou carrefour remarquable de Yaoundé).
  final String quartierOuCarrefour;

  /// Statut actuel de la demande.
  final FlashRequestStatus statut;

  /// Numéro de vague courante d'escalade Round-Robin (1-based: 1, 2, 3...).
  final int vagueActuelle;

  /// Liste des identifiants d'officines déjà notifiées.
  final List<String> pharmaciesNotifieesIds;

  /// Liste des offres de comptoir reçues en réponse.
  final List<PharmacyOffer> offresRecues;

  /// Date et heure de soumission.
  final DateTime createdAt;

  /// Date et heure d'expiration de la demande.
  final DateTime expiresAt;

  /// Indique si la demande a déjà reçu au moins une offre d'officine.
  bool get hasOffers => offresRecues.isNotEmpty;

  /// Indique si la demande a dépassé sa date limite d'expiration.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Crée une copie immuable avec les champs modifiés.
  FlashRequest copyWith({
    String? id,
    String? clientRequestId,
    List<BasketItem>? items,
    String? quartierOuCarrefour,
    FlashRequestStatus? statut,
    int? vagueActuelle,
    List<String>? pharmaciesNotifieesIds,
    List<PharmacyOffer>? offresRecues,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return FlashRequest(
      id: id ?? this.id,
      clientRequestId: clientRequestId ?? this.clientRequestId,
      items: items ?? this.items,
      quartierOuCarrefour: quartierOuCarrefour ?? this.quartierOuCarrefour,
      statut: statut ?? this.statut,
      vagueActuelle: vagueActuelle ?? this.vagueActuelle,
      pharmaciesNotifieesIds:
          pharmaciesNotifieesIds ?? this.pharmaciesNotifieesIds,
      offresRecues: offresRecues ?? this.offresRecues,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clientRequestId,
        items,
        quartierOuCarrefour,
        statut,
        vagueActuelle,
        pharmaciesNotifieesIds,
        offresRecues,
        createdAt,
        expiresAt,
      ];
}
