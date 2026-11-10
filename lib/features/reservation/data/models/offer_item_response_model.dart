import 'package:medmate/features/reservation/data/models/item_availability_status_model.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';

/// Modèle DTO pour la réponse de disponibilité d'un médicament au comptoir.
///
/// Le prix unitaire est exclusivement déterminé et renseigné au comptoir
/// par le pharmacien lors de la formulation de son devis.
class OfferItemResponseModel extends OfferItemResponse {
  const OfferItemResponseModel({
    required super.medicationId,
    required super.status,
    required super.prixUnitaireCommunicParPharmacien,
    super.conditionDelivrance,
    super.commentaire,
  });

  /// Désérialise une réponse d'article depuis un dictionnaire JSON.
  factory OfferItemResponseModel.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'unavailable';
    final rawPrice = json['prix_unitaire_communic_par_pharmacien'] ??
        json['prixUnitaireCommunicParPharmacien'] ??
        0;

    return OfferItemResponseModel(
      medicationId: (json['medication_id'] ?? json['medicationId']) as String,
      status: ItemAvailabilityStatusModel.fromString(statusStr),
      prixUnitaireCommunicParPharmacien: (rawPrice as num).toDouble(),
      conditionDelivrance: (json['condition_delivrance'] ??
          json['conditionDelivrance']) as String?,
      commentaire: json['commentaire'] as String?,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory OfferItemResponseModel.fromDomain(OfferItemResponse domain) {
    return OfferItemResponseModel(
      medicationId: domain.medicationId,
      status: domain.status,
      prixUnitaireCommunicParPharmacien:
          domain.prixUnitaireCommunicParPharmacien,
      conditionDelivrance: domain.conditionDelivrance,
      commentaire: domain.commentaire,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'medication_id': medicationId,
      'status': status.name,
      'prix_unitaire_communic_par_pharmacien':
          prixUnitaireCommunicParPharmacien,
      'condition_delivrance': conditionDelivrance,
      'commentaire': commentaire,
    };
  }

  /// Convertit le modèle en entité de domaine.
  OfferItemResponse toDomain() => this;
}
