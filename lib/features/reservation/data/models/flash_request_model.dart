import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/pharmacy_offer_model.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';

/// Modèle DTO pour une demande flash de disponibilité multi-officines.
class FlashRequestModel extends FlashRequest {
  const FlashRequestModel({
    required super.id,
    required super.clientRequestId,
    required super.items,
    required super.quartierOuCarrefour,
    required super.statut,
    required super.vagueActuelle,
    required super.pharmaciesNotifieesIds,
    required super.offresRecues,
    required super.createdAt,
    required super.expiresAt,
  });

  /// Désérialise une demande flash depuis un dictionnaire JSON.
  factory FlashRequestModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <BasketItem>[];
    if (rawItems is List) {
      for (final dynamic item in rawItems) {
        if (item is Map<String, dynamic>) {
          items.add(BasketItemModel.fromJson(item));
        }
      }
    }

    final rawOffres = json['offres_recues'] ?? json['offresRecues'];
    final offres = <PharmacyOffer>[];
    if (rawOffres is List) {
      for (final dynamic offre in rawOffres) {
        if (offre is Map<String, dynamic>) {
          offres.add(PharmacyOfferModel.fromJson(offre));
        }
      }
    }

    final rawPharma =
        json['pharmacies_notifiees_ids'] ?? json['pharmaciesNotifieesIds'];
    final pharmaciesNotifieesIds = <String>[];
    if (rawPharma is List) {
      for (final dynamic id in rawPharma) {
        if (id is String) {
          pharmaciesNotifieesIds.add(id);
        }
      }
    }

    final statutStr = json['statut'] as String? ?? 'pending';
    final statut = FlashRequestStatus.values.firstWhere(
      (e) => e.name == statutStr,
      orElse: () => FlashRequestStatus.pending,
    );

    final rawVague = json['vague_actuelle'] ?? json['vagueActuelle'] ?? 1;
    final vagueActuelle = (rawVague is num) ? rawVague.toInt() : 1;

    return FlashRequestModel(
      id: json['id'] as String,
      clientRequestId: (json['client_request_id'] ??
          json['clientRequestId']) as String,
      items: items,
      quartierOuCarrefour: (json['quartier_ou_carrefour'] ??
          json['quartierOuCarrefour']) as String,
      statut: statut,
      vagueActuelle: vagueActuelle,
      pharmaciesNotifieesIds: pharmaciesNotifieesIds,
      offresRecues: offres,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory FlashRequestModel.fromDomain(FlashRequest domain) {
    return FlashRequestModel(
      id: domain.id,
      clientRequestId: domain.clientRequestId,
      items: domain.items,
      quartierOuCarrefour: domain.quartierOuCarrefour,
      statut: domain.statut,
      vagueActuelle: domain.vagueActuelle,
      pharmaciesNotifieesIds: domain.pharmaciesNotifieesIds,
      offresRecues: domain.offresRecues,
      createdAt: domain.createdAt,
      expiresAt: domain.expiresAt,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_request_id': clientRequestId,
      'items': items
          .map((e) => BasketItemModel.fromDomain(e).toJson())
          .toList(),
      'quartier_ou_carrefour': quartierOuCarrefour,
      'statut': statut.name,
      'vague_actuelle': vagueActuelle,
      'pharmacies_notifiees_ids': pharmaciesNotifieesIds,
      'offres_recues': offresRecues
          .map((e) => PharmacyOfferModel.fromDomain(e).toJson())
          .toList(),
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  /// Convertit le modèle en entité de domaine.
  FlashRequest toDomain() => this;
}
