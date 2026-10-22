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
      ];
}
