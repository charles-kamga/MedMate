import 'package:equatable/equatable.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';

/// Soumission d'un devis/offre formulé exclusivement par le pharmacien au comptoir.
///
/// INVARIANT METIER NON NEGOCIABLE (Afya Santé / Déontologie ONPC):
/// La tarification et la disponibilité physique sont obligatoirement établies
/// au comptoir par le pharmacien. L'application ne contient aucun prix catalogue prédéfini.
class CounterQuoteSubmission extends Equatable {
  const CounterQuoteSubmission({
    required this.demandId,
    required this.pharmacyId,
    required this.itemResponses,
    required this.montantTotal,
    required this.livraisonPossible,
    this.fraisLivraison,
    this.delaiMinutes,
    this.notes,
  });

  /// Identifiant de la demande flash du patient.
  final String demandId;

  /// Identifiant de l'officine de pharmacie qui soumet le devis.
  final String pharmacyId;

  /// Réponses détaillées produit par produit avec disponibilité et prix unitaire.
  final List<OfferItemResponse> itemResponses;

  /// Montant total en FCFA fixé au comptoir par le pharmacien.
  final double montantTotal;

  /// Indique si l'officine propose la livraison ou uniquement le retrait au comptoir.
  final bool livraisonPossible;

  /// Frais de livraison éventuels en FCFA.
  final double? fraisLivraison;

  /// Délai estimé de mise à disposition ou de livraison en minutes.
  final int? delaiMinutes;

  /// Notes ou recommandations déontologiques du pharmacien.
  final String? notes;

  /// Alias de compatibilité pour les réponses détaillées.
  List<OfferItemResponse> get itemsResponse => itemResponses;

  /// Alias de délai estimé en minutes.
  int? get delaiEstimeMinutes => delaiMinutes;

  /// Alias pour les notes ou commentaires du pharmacien.
  String? get commentairePharmacien => notes;

  /// Crée une copie immuable avec les champs modifiés.
  CounterQuoteSubmission copyWith({
    String? demandId,
    String? pharmacyId,
    List<OfferItemResponse>? itemResponses,
    double? montantTotal,
    bool? livraisonPossible,
    double? fraisLivraison,
    int? delaiMinutes,
    String? notes,
  }) {
    return CounterQuoteSubmission(
      demandId: demandId ?? this.demandId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      itemResponses: itemResponses ?? this.itemResponses,
      montantTotal: montantTotal ?? this.montantTotal,
      livraisonPossible: livraisonPossible ?? this.livraisonPossible,
      fraisLivraison: fraisLivraison ?? this.fraisLivraison,
      delaiMinutes: delaiMinutes ?? this.delaiMinutes,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
        demandId,
        pharmacyId,
        itemResponses,
        montantTotal,
        livraisonPossible,
        fraisLivraison,
        delaiMinutes,
        notes,
      ];
}
