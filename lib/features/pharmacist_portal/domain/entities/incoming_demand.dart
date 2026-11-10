import 'package:equatable/equatable.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';

/// Demande flash entrante reçue par une officine de pharmacie sur son portail comptoir.
class IncomingDemand extends Equatable {
  const IncomingDemand({
    required this.id,
    required this.flashRequest,
    required this.receivedAt,
    required this.isResponded,
    this.distanceMetres,
  });

  /// Identifiant unique de la notification de demande entrante (UUID).
  final String id;

  /// Demande flash soumise par le patient.
  final FlashRequest flashRequest;

  /// Horodatage de réception de la demande par l'officine.
  final DateTime receivedAt;

  /// Indique si le pharmacien a déjà formulé un devis/réponse.
  final bool isResponded;

  /// Distance estimée en mètres entre l'officine et le repère urbain du patient.
  final double? distanceMetres;

  /// Identifiant de la demande flash associée.
  String get demandeId => flashRequest.id;

  /// Liste des médicaments et quantités demandés.
  List<BasketItem> get items => flashRequest.items;

  /// Quartier ou carrefour de localisation du patient.
  String get quartierPatient => flashRequest.quartierOuCarrefour;

  /// Indique si la fenêtre de réponse à la demande est dépassée.
  bool get isExpired => flashRequest.isExpired;

  /// Crée une copie immuable avec les champs modifiés.
  IncomingDemand copyWith({
    String? id,
    FlashRequest? flashRequest,
    DateTime? receivedAt,
    bool? isResponded,
    double? distanceMetres,
  }) {
    return IncomingDemand(
      id: id ?? this.id,
      flashRequest: flashRequest ?? this.flashRequest,
      receivedAt: receivedAt ?? this.receivedAt,
      isResponded: isResponded ?? this.isResponded,
      distanceMetres: distanceMetres ?? this.distanceMetres,
    );
  }

  @override
  List<Object?> get props => [
        id,
        flashRequest,
        receivedAt,
        isResponded,
        distanceMetres,
      ];
}
