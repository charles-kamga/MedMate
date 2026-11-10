import 'package:equatable/equatable.dart';

/// Entité immuable représentant une officine de pharmacie à Yaoundé.
///
/// Modélise les repères urbains locaux (quartier et carrefour remarquable)
/// ainsi que les coordonnées WGS84 et la permanence de garde.
class Pharmacy extends Equatable {
  const Pharmacy({
    required this.id,
    required this.nom,
    required this.licenceOnpc,
    required this.quartier,
    required this.carrefourRepere,
    required this.latitude,
    required this.longitude,
    required this.telephoneGarde,
    required this.estOuverte,
    required this.estDeGarde,
    required this.estPartenaire,
    this.distanceMetres,
  });

  /// Identifiant unique de l'officine (UUID).
  final String id;

  /// Nom de l'officine (ex: "Pharmacie Bastos", "Pharmacie du Soleil").
  final String nom;

  /// Numéro officiel d'agrément auprès de l'ONPC.
  final String licenceOnpc;

  /// Quartier d'implantation à Yaoundé (ex: "Bastos", "Mokolo", "Biyem-Assi").
  final String quartier;

  /// Carrefour ou repère remarquable (ex: "Carrefour Warda", "Carrefour Obili").
  final String carrefourRepere;

  /// Latitude WGS84 (Yaoundé ~3.80 à 3.95).
  final double latitude;

  /// Longitude WGS84 (Yaoundé ~11.45 à 11.58).
  final double longitude;

  /// Ligne téléphonique de permanence/garde (+237...).
  final String telephoneGarde;

  /// Indique si l'officine est actuellement ouverte.
  final bool estOuverte;

  /// Indique si l'officine assure la garde officielle.
  final bool estDeGarde;

  /// Indique si l'officine est partenaire digital (accepte les demandes flash).
  final bool estPartenaire;

  /// Distance calculée en mètres par rapport au point de référence de la requête.
  final double? distanceMetres;

  /// Crée une copie immuable de l'entité avec des champs modifiés.
  Pharmacy copyWith({
    String? id,
    String? nom,
    String? licenceOnpc,
    String? quartier,
    String? carrefourRepere,
    double? latitude,
    double? longitude,
    String? telephoneGarde,
    bool? estOuverte,
    bool? estDeGarde,
    bool? estPartenaire,
    double? distanceMetres,
  }) {
    return Pharmacy(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      licenceOnpc: licenceOnpc ?? this.licenceOnpc,
      quartier: quartier ?? this.quartier,
      carrefourRepere: carrefourRepere ?? this.carrefourRepere,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      telephoneGarde: telephoneGarde ?? this.telephoneGarde,
      estOuverte: estOuverte ?? this.estOuverte,
      estDeGarde: estDeGarde ?? this.estDeGarde,
      estPartenaire: estPartenaire ?? this.estPartenaire,
      distanceMetres: distanceMetres ?? this.distanceMetres,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nom,
        licenceOnpc,
        quartier,
        carrefourRepere,
        latitude,
        longitude,
        telephoneGarde,
        estOuverte,
        estDeGarde,
        estPartenaire,
        distanceMetres,
      ];
}
