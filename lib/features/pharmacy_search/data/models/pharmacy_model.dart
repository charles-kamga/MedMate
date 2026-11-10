import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

/// Modèle DTO pour une officine de pharmacie à Yaoundé.
class PharmacyModel extends Pharmacy {
  const PharmacyModel({
    required super.id,
    required super.nom,
    required super.licenceOnpc,
    required super.quartier,
    required super.carrefourRepere,
    required super.latitude,
    required super.longitude,
    required super.telephoneGarde,
    required super.estOuverte,
    required super.estDeGarde,
    required super.estPartenaire,
    super.distanceMetres,
  });

  /// Désérialise une officine depuis un dictionnaire JSON.
  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String,
      nom: json['nom'] as String,
      licenceOnpc: json['licence_onpc'] as String,
      quartier: json['quartier'] as String,
      carrefourRepere: json['carrefour_repere'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      telephoneGarde: json['telephone_garde'] as String,
      estOuverte: json['est_ouverte'] as bool? ?? true,
      estDeGarde: json['est_de_garde'] as bool? ?? false,
      estPartenaire: json['est_partenaire'] as bool? ?? false,
      distanceMetres: json['distance_metres'] != null
          ? (json['distance_metres'] as num).toDouble()
          : null,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory PharmacyModel.fromDomain(Pharmacy pharmacy) {
    return PharmacyModel(
      id: pharmacy.id,
      nom: pharmacy.nom,
      licenceOnpc: pharmacy.licenceOnpc,
      quartier: pharmacy.quartier,
      carrefourRepere: pharmacy.carrefourRepere,
      latitude: pharmacy.latitude,
      longitude: pharmacy.longitude,
      telephoneGarde: pharmacy.telephoneGarde,
      estOuverte: pharmacy.estOuverte,
      estDeGarde: pharmacy.estDeGarde,
      estPartenaire: pharmacy.estPartenaire,
      distanceMetres: pharmacy.distanceMetres,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'licence_onpc': licenceOnpc,
      'quartier': quartier,
      'carrefour_repere': carrefourRepere,
      'latitude': latitude,
      'longitude': longitude,
      'telephone_garde': telephoneGarde,
      'est_ouverte': estOuverte,
      'est_de_garde': estDeGarde,
      'est_partenaire': estPartenaire,
      'distance_metres': distanceMetres,
    };
  }

  @override
  PharmacyModel copyWith({
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
    return PharmacyModel(
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

  /// Convertit le modèle en entité du domaine.
  Pharmacy toDomain() => this;
}
