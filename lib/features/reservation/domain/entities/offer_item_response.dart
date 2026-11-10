import 'package:equatable/equatable.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';

/// Réponse détaillée du pharmacien au comptoir pour un article d'une demande.
///
/// INVARIANT METIER (Afya Santé / Déontologie ONPC):
/// Le prix unitaire est exclusivement déterminé et renseigné au comptoir
/// par le pharmacien lors de la formulation de son devis/offre.
class OfferItemResponse extends Equatable {
  const OfferItemResponse({
    required this.medicationId,
    required this.status,
    required this.prixUnitaireCommunicParPharmacien,
    this.conditionDelivrance,
    this.commentaire,
  });

  /// Identifiant du médicament concerné.
  final String medicationId;

  /// Disponibilité physique du produit dans l'officine.
  final ItemAvailabilityStatus status;

  /// Prix unitaire communiqué en FCFA par le pharmacien au comptoir (0.0 si indisponible).
  final double prixUnitaireCommunicParPharmacien;

  /// Condition éventuelle de délivrance (ex: "Ordonnance originale requise").
  final String? conditionDelivrance;

  /// Commentaire ou précision du pharmacien (ex: "Remplacement par générique Biogaran").
  final String? commentaire;

  /// Crée une copie immuable avec les champs modifiés.
  OfferItemResponse copyWith({
    String? medicationId,
    ItemAvailabilityStatus? status,
    double? prixUnitaireCommunicParPharmacien,
    String? conditionDelivrance,
    String? commentaire,
  }) {
    return OfferItemResponse(
      medicationId: medicationId ?? this.medicationId,
      status: status ?? this.status,
      prixUnitaireCommunicParPharmacien:
          prixUnitaireCommunicParPharmacien ?? this.prixUnitaireCommunicParPharmacien,
      conditionDelivrance: conditionDelivrance ?? this.conditionDelivrance,
      commentaire: commentaire ?? this.commentaire,
    );
  }

  @override
  List<Object?> get props => [
        medicationId,
        status,
        prixUnitaireCommunicParPharmacien,
        conditionDelivrance,
        commentaire,
      ];
}
