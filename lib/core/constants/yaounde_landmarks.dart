import 'package:equatable/equatable.dart';

/// Modélisation immuable d'un carrefour ou point de repère urbain de Yaoundé.
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
  List<Object?> get props => [
        id,
        nom,
        quartier,
        arrondissement,
        latitude,
        longitude,
      ];
}

/// Référentiel hors-ligne des quartiers et carrefours majeurs de Yaoundé.
class YaoundeLandmarks {
  const YaoundeLandmarks._();

  static const List<YaoundeLandmark> list = [
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
      id: 'carrefour-warda',
      nom: 'Carrefour Warda',
      quartier: 'Bastos',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8688,
      longitude: 11.5175,
      description: 'Face au Bois Sainte-Anastasie, jonction Centre et Bastos',
    ),
    YaoundeLandmark(
      id: 'carrefour-nlongkak',
      nom: 'Carrefour Nlongkak',
      quartier: 'Nlongkak',
      arrondissement: 'Yaoundé 1er',
      latitude: 3.8833,
      longitude: 11.5250,
      description: 'Rond-point Nlongkak vers Dragages, Bastos et Etoa-Meki',
    ),
    YaoundeLandmark(
      id: 'marche-mokolo',
      nom: 'Marché Mokolo',
      quartier: 'Mokolo',
      arrondissement: 'Yaoundé 2e',
      latitude: 3.8740,
      longitude: 11.5020,
      description: 'Entrée principale du marché Mokolo vers Tsinga',
    ),
    YaoundeLandmark(
      id: 'carrefour-meec',
      nom: 'Carrefour MEEC',
      quartier: 'Tsinga',
      arrondissement: 'Yaoundé 2e',
      latitude: 3.8810,
      longitude: 11.4960,
      description: 'Axe Palais des Congrès et quartier Tsinga',
    ),
    YaoundeLandmark(
      id: 'carrefour-obili',
      nom: 'Carrefour Obili',
      quartier: 'Obili',
      arrondissement: 'Yaoundé 3e',
      latitude: 3.8540,
      longitude: 11.4920,
      description: 'Chapelle Obili, axe universitaire Ngoa-Ekellé et ENSPY',
    ),
    YaoundeLandmark(
      id: 'carrefour-emia',
      nom: 'Carrefour EMIA',
      quartier: 'Ngoa-Ekellé',
      arrondissement: 'Yaoundé 3e',
      latitude: 3.8610,
      longitude: 11.5050,
      description: 'Proximité CHU de Yaoundé, ENSPY et École Militaire',
    ),
    YaoundeLandmark(
      id: 'carrefour-nsam',
      nom: 'Carrefour Nsam',
      quartier: 'Nsam',
      arrondissement: 'Yaoundé 3e',
      latitude: 3.8310,
      longitude: 11.5180,
      description: 'Axe Sud sortie Mbalmayo et Efoulan',
    ),
    YaoundeLandmark(
      id: 'carrefour-essos',
      nom: 'Carrefour Essos (Hôpital de la Caisse)',
      quartier: 'Essos',
      arrondissement: 'Yaoundé 5e',
      latitude: 3.8720,
      longitude: 11.5410,
      description: 'Proximité Centre Hospitalier d’Essos (CNPS)',
    ),
    YaoundeLandmark(
      id: 'stade-omnisports',
      nom: 'Rond-Point Omnisports',
      quartier: 'Omnisports',
      arrondissement: 'Yaoundé 5e',
      latitude: 3.8860,
      longitude: 11.5400,
      description: 'Esplanade Stade Ahmadou Ahidjo vers Mfandena',
    ),
    YaoundeLandmark(
      id: 'carrefour-acacia',
      nom: 'Carrefour Biyem-Assi (Acacia)',
      quartier: 'Biyem-Assi',
      arrondissement: 'Yaoundé 6e',
      latitude: 3.8375,
      longitude: 11.4880,
      description: 'Carrefour Acacia, axe commerçant dense de Biyem-Assi',
    ),
    YaoundeLandmark(
      id: 'carrefour-mendong',
      nom: 'Entrée Simbock / Mendong',
      quartier: 'Mendong',
      arrondissement: 'Yaoundé 6e',
      latitude: 3.8290,
      longitude: 11.4710,
      description: 'Pôle résidentiel Mendong et Camp SIC',
    ),
  ];
}
