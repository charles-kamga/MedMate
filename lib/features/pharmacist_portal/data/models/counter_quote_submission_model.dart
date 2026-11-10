import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';

/// Modèle DTO pour la soumission d'un devis au comptoir par le pharmacien.
///
/// INVARIANT METIER NON NEGOCIABLE (Afya Santé / Déontologie ONPC):
/// La tarification et la disponibilité physique sont obligatoirement établies
/// au comptoir par le pharmacien.
class CounterQuoteSubmissionModel extends CounterQuoteSubmission {
  const CounterQuoteSubmissionModel({
    required super.demandId,
    required super.pharmacyId,
    required super.itemResponses,
    required super.montantTotal,
    required super.livraisonPossible,
    super.fraisLivraison,
    super.delaiMinutes,
    super.notes,
  });

  /// Désérialise une soumission de devis depuis un dictionnaire JSON.
  factory CounterQuoteSubmissionModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['item_responses'] ?? json['itemResponses'];
    final itemResponses = <OfferItemResponse>[];
    if (rawItems is List) {
      for (final dynamic item in rawItems) {
        if (item is Map<String, dynamic>) {
          itemResponses.add(OfferItemResponseModel.fromJson(item));
        }
      }
    }
    final rawTotal = json['montant_total'] ?? json['montantTotal'] ?? 0;
    final rawFrais = json['frais_livraison'] ?? json['fraisLivraison'];
    final rawDelai = json['delai_minutes'] ?? json['delaiMinutes'];

    return CounterQuoteSubmissionModel(
      demandId: (json['demand_id'] ?? json['demandId']) as String,
      pharmacyId: (json['pharmacy_id'] ?? json['pharmacyId']) as String,
      itemResponses: itemResponses,
      montantTotal: (rawTotal as num).toDouble(),
      livraisonPossible: (json['livraison_possible'] ??
              json['livraisonPossible'] ??
              false)
          as bool,
      fraisLivraison:
          rawFrais != null ? (rawFrais as num).toDouble() : null,
      delaiMinutes: rawDelai != null ? (rawDelai as num).toInt() : null,
      notes: (json['notes'] ?? json['commentaire_pharmacien']) as String?,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory CounterQuoteSubmissionModel.fromDomain(
    CounterQuoteSubmission domain,
  ) {
    return CounterQuoteSubmissionModel(
      demandId: domain.demandId,
      pharmacyId: domain.pharmacyId,
      itemResponses: domain.itemResponses,
      montantTotal: domain.montantTotal,
      livraisonPossible: domain.livraisonPossible,
      fraisLivraison: domain.fraisLivraison,
      delaiMinutes: domain.delaiMinutes,
      notes: domain.notes,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'demand_id': demandId,
      'pharmacy_id': pharmacyId,
      'item_responses': itemResponses
          .map((e) => OfferItemResponseModel.fromDomain(e).toJson())
          .toList(),
      'montant_total': montantTotal,
      'livraison_possible': livraisonPossible,
      'frais_livraison': fraisLivraison,
      'delai_minutes': delaiMinutes,
      'notes': notes,
    };
  }

  /// Convertit le modèle en entité de domaine.
  CounterQuoteSubmission toDomain() => this;
}
