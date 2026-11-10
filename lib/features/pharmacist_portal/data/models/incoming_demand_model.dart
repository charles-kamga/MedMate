import 'package:medmate/features/pharmacist_portal/domain/entities/incoming_demand.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';

/// Modèle DTO pour une demande entrante reçue sur le portail comptoir officinal.
class IncomingDemandModel extends IncomingDemand {
  const IncomingDemandModel({
    required super.id,
    required super.flashRequest,
    required super.receivedAt,
    required super.isResponded,
    super.distanceMetres,
  });

  /// Désérialise une demande entrante depuis un dictionnaire JSON.
  factory IncomingDemandModel.fromJson(Map<String, dynamic> json) {
    final flashReqJson = json['flash_request'] as Map<String, dynamic>;
    final flashRequest = FlashRequestModel.fromJson(flashReqJson);
    final rawDistance = json['distance_metres'] ?? json['distanceMetres'];

    return IncomingDemandModel(
      id: json['id'] as String,
      flashRequest: flashRequest,
      receivedAt: DateTime.parse(json['received_at'] as String),
      isResponded:
          (json['is_responded'] ?? json['isResponded'] ?? false) as bool,
      distanceMetres:
          rawDistance != null ? (rawDistance as num).toDouble() : null,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory IncomingDemandModel.fromDomain(IncomingDemand domain) {
    return IncomingDemandModel(
      id: domain.id,
      flashRequest: domain.flashRequest,
      receivedAt: domain.receivedAt,
      isResponded: domain.isResponded,
      distanceMetres: domain.distanceMetres,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'flash_request': FlashRequestModel.fromDomain(flashRequest).toJson(),
      'received_at': receivedAt.toIso8601String(),
      'is_responded': isResponded,
      'distance_metres': distanceMetres,
    };
  }

  /// Convertit le modèle en entité de domaine.
  IncomingDemand toDomain() => this;
}
