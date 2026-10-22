import 'package:equatable/equatable.dart';

/// Modélisation d'un point de repère urbain à Yaoundé
class YaoundeLandmark extends Equatable {
  const YaoundeLandmark({
    required this.id,
    required this.nom,
    required this.quartier,
    required this.arrondissement,
    required this.latitude,
    required this.longitude,
    required this.description,
  });

  final String id;
  final String nom;
  final String quartier;
  final String arrondissement;
  final double latitude;
  final double longitude;
  final String description;

  @override
  List<Object?> get props => [id, nom, quartier, latitude, longitude];
}

/// Référentiel des repères et carrefours incontournables de Yaoundé (Offline Ready)
class YaoundeLandmarks {
  const YaoundeLandmarks._();

  static const List<YaoundeLandmark> list = [
    YaoundeLandmark(
      id: 'carrefour-warda',
      nom: 'Carrefour Warda',
      quartier: 'Poste Centrale',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8688,
      longitude: 11.5175,
      description: 'Face au Bois Sainte-Anastasie, jonction Centre et Bastos',
    ),
    YaoundeLandmark(
      id: 'poste-centrale',
      nom: 'Rond-Point Poste Centrale',
      quartier: 'Poste Centrale',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8667,
      longitude: 11.5200,
      description: 'Cœur administratif et commercial de Yaoundé',
    ),
    YaoundeLandmark(
      id: 'carrefour-obili',
      nom: 'Carrefour Obili',
      quartier: 'Obili',
      arrondissement: 'Yaoundé 3e',
      latitude: 3.8540,
      longitude: 11.4920,
      description: 'Chapelle Obili, zone universitaire Ngoa-Ekellé',
    ),
    YaoundeLandmark(
      id: 'carrefour-nlongkak',
      nom: 'Carrefour Nlongkak',
      quartier: 'Nlongkak',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8833,
      longitude: 11.5250,
      description: 'Rond-point Nlongkak vers Dragages et Bastos',
    ),
    YaoundeLandmark(
      id: 'carrefour-acacia',
      nom: 'Carrefour Biyem-Assi (Acacia)',
      quartier: 'Biyem-Assi',
      arrondissement: 'Yaoundé 6e',
      latitude: 3.8375,
      longitude: 11.4880,
      description: 'Carrefour Acacia, axe commerçant dense',
    ),
    YaoundeLandmark(
      id: 'carrefour-emia',
      nom: 'Carrefour EMIA',
      quartier: 'Ngoa-Ekellé',
      arrondissement: 'Yaoundé 3e',
      latitude: 3.8610,
      longitude: 11.5050,
      description: 'Proximité CHU de Yaoundé et École Militaire',
    ),
    YaoundeLandmark(
      id: 'marche-mokolo',
      nom: 'Marché Mokolo',
      quartier: 'Mokolo',
      arrondissement: 'Yaoundé 2e',
      latitude: 3.8740,
      longitude: 11.5020,
      description: 'Entrée principale marché Mokolo vers Madagascar',
    ),
  ];
}
