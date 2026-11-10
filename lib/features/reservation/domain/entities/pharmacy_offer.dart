import 'package:equatable/equatable.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';

/// Offre de prix et de disponibilité formulée par une officine de pharmacie.
class PharmacyOffer extends Equatable {
  const PharmacyOffer({
    required this.id,
    required this.demandeId,
    required this.pharmacyId,
    required this.pharmacyNom,
    required this.quartier,
    required this.items,
    required this.montantTotalPropose,
    required this.livraisonDisponible,
    required this.createdAt,
    this.distanceMetres,
    this.fraisLivraison,
    this.delaiLivraisonMinutes,
  });

  /// Identifiant unique de l'offre (UUID).
  final String id;

  /// Identifiant de la demande flash associée.
  final String demandeId;

  /// Identifiant de l'officine formulant l'offre.
  final String pharmacyId;

  /// Nom de l'officine (ex: "Pharmacie Bastos").
  final String pharmacyNom;

  /// Quartier d'implantation à Yaoundé.
  final String quartier;

  /// Distance en mètres par rapport au patient/repère urbain.
  final double? distanceMetres;

  /// Liste des réponses de disponibilité article par article.
  final List<OfferItemResponse> items;

  /// Montant total proposé en FCFA calculé au comptoir.
  final double montantTotalPropose;

  /// Indique si l'officine propose un service d'acheminement/livraison.
  final bool livraisonDisponible;

  /// Frais de livraison éventuels en FCFA.
  final double? fraisLivraison;

  /// Délai estimé de livraison en minutes.
  final int? delaiLivraisonMinutes;

  /// Horodatage de formulation de l'offre.
  final DateTime createdAt;

  /// Crée une copie immuable avec les champs modifiés.
  PharmacyOffer copyWith({
    String? id,
    String? demandeId,
    String? pharmacyId,
    String? pharmacyNom,
    String? quartier,
    double? distanceMetres,
    List<OfferItemResponse>? items,
    double? montantTotalPropose,
    bool? livraisonDisponible,
    double? fraisLivraison,
    int? delaiLivraisonMinutes,
    DateTime? createdAt,
  }) {
    return PharmacyOffer(
      id: id ?? this.id,
      demandeId: demandeId ?? this.demandeId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      pharmacyNom: pharmacyNom ?? this.pharmacyNom,
      quartier: quartier ?? this.quartier,
      items: items ?? this.items,
      montantTotalPropose: montantTotalPropose ?? this.montantTotalPropose,
      livraisonDisponible: livraisonDisponible ?? this.livraisonDisponible,
      createdAt: createdAt ?? this.createdAt,
      distanceMetres: distanceMetres ?? this.distanceMetres,
      fraisLivraison: fraisLivraison ?? this.fraisLivraison,
      delaiLivraisonMinutes: delaiLivraisonMinutes ?? this.delaiLivraisonMinutes,
    );
  }

  @override
  List<Object?> get props => [
        id,
        demandeId,
        pharmacyId,
        pharmacyNom,
        quartier,
        distanceMetres,
        items,
        montantTotalPropose,
        livraisonDisponible,
        fraisLivraison,
        delaiLivraisonMinutes,
        createdAt,
      ];
}
