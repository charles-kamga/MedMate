import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';

/// Modèle DTO pour une offre de prix et de disponibilité émise par une officine.
class PharmacyOfferModel extends PharmacyOffer {
  const PharmacyOfferModel({
    required super.id,
    required super.demandeId,
    required super.pharmacyId,
    required super.pharmacyNom,
    required super.quartier,
    required super.items,
    required super.montantTotalPropose,
    required super.livraisonDisponible,
    required super.createdAt,
    super.distanceMetres,
    super.fraisLivraison,
    super.delaiLivraisonMinutes,
  });

  /// Désérialise une offre d'officine depuis un dictionnaire JSON.
  factory PharmacyOfferModel.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List<dynamic>?) ?? [];
    final items = itemsList
        .map((e) => OfferItemResponseModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final rawTotal =
        json['montant_total_propose'] ?? json['montantTotalPropose'] ?? 0;
    final rawDistance = json['distance_metres'] ?? json['distanceMetres'];
    final rawFrais = json['frais_livraison'] ?? json['fraisLivraison'];
    final rawDelai =
        json['delai_livraison_minutes'] ?? json['delaiLivraisonMinutes'];

    return PharmacyOfferModel(
      id: json['id'] as String,
      demandeId: (json['demande_id'] ?? json['demandeId']) as String,
      pharmacyId: (json['pharmacy_id'] ?? json['pharmacyId']) as String,
      pharmacyNom: (json['pharmacy_nom'] ?? json['pharmacyNom']) as String,
      quartier: json['quartier'] as String,
      items: items,
      montantTotalPropose: (rawTotal as num).toDouble(),
      livraisonDisponible: (json['livraison_disponible'] ??
              json['livraisonDisponible'] ??
              false)
          as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      distanceMetres:
          rawDistance != null ? (rawDistance as num).toDouble() : null,
      fraisLivraison: rawFrais != null ? (rawFrais as num).toDouble() : null,
      delaiLivraisonMinutes:
          rawDelai != null ? (rawDelai as num).toInt() : null,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory PharmacyOfferModel.fromDomain(PharmacyOffer domain) {
    return PharmacyOfferModel(
      id: domain.id,
      demandeId: domain.demandeId,
      pharmacyId: domain.pharmacyId,
      pharmacyNom: domain.pharmacyNom,
      quartier: domain.quartier,
      items: domain.items,
      montantTotalPropose: domain.montantTotalPropose,
      livraisonDisponible: domain.livraisonDisponible,
      createdAt: domain.createdAt,
      distanceMetres: domain.distanceMetres,
      fraisLivraison: domain.fraisLivraison,
      delaiLivraisonMinutes: domain.delaiLivraisonMinutes,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'demande_id': demandeId,
      'pharmacy_id': pharmacyId,
      'pharmacy_nom': pharmacyNom,
      'quartier': quartier,
      'items': items
          .map((e) => OfferItemResponseModel.fromDomain(e).toJson())
          .toList(),
      'montant_total_propose': montantTotalPropose,
      'livraison_disponible': livraisonDisponible,
      'created_at': createdAt.toIso8601String(),
      'distance_metres': distanceMetres,
      'frais_livraison': fraisLivraison,
      'delai_livraison_minutes': delaiLivraisonMinutes,
    };
  }

  /// Convertit le modèle en entité de domaine.
  PharmacyOffer toDomain() => this;
}
