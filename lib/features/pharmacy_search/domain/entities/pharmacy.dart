import 'package:equatable/equatable.dart';

/// Entité métier représentant une officine pharmaceutique à Yaoundé
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
    this.distanceMetres,
    this.isPartner = true,
    this.horaires,
    this.proposeLivraison = false,
    this.responsable,
  });

  final String id;
  final String nom;
  final String licenceOnpc;
  final String quartier;
  final String carrefourRepere;
  final double latitude;
  final double longitude;
  final String telephoneGarde;
  final bool estOuverte;
  final bool estDeGarde;
  final double? distanceMetres;
  final bool isPartner;
  final String? horaires;
  final bool proposeLivraison;
  final String? responsable;

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
        distanceMetres,
        isPartner,
        horaires,
        proposeLivraison,
        responsable,
      ];
}
