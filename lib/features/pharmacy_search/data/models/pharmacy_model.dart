import '../../domain/entities/pharmacy.dart';

/// DTO pour la désérialisation typée des pharmacies
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
    super.distanceMetres,
    super.isPartner = true,
    super.horaires,
    super.proposeLivraison = false,
    super.responsable,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) {
    return PharmacyModel(
      id: json['id'] as String? ?? (json['pharmacy_id'] as String? ?? ''),
      nom: json['nom'] as String? ?? (json['pharmacy_name'] as String? ?? ''),
      licenceOnpc: json['licence_onpc'] as String? ?? '',
      quartier: json['quartier'] as String? ?? (json['quartier_name'] as String? ?? 'Yaoundé'),
      carrefourRepere: json['carrefour_repere'] as String? ?? (json['carrefour_name'] as String? ?? 'Centre'),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 3.8667,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 11.5200,
      telephoneGarde: json['telephone_garde'] as String? ?? '',
      estOuverte: json['est_ouverte'] as bool? ?? true,
      estDeGarde: json['est_de_garde'] as bool? ?? false,
      distanceMetres: (json['distance_meters'] as num?)?.toDouble() ??
          (json['distance_metres'] as num?)?.toDouble(),
      isPartner: json['is_partner'] as bool? ?? true,
      horaires: json['horaires'] as String?,
      proposeLivraison: json['propose_livraison'] as bool? ?? false,
      responsable: json['responsable'] as String?,
    );
  }

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
      'distance_metres': distanceMetres,
      'is_partner': isPartner,
      'horaires': horaires,
      'propose_livraison': proposeLivraison,
      'responsable': responsable,
    };
  }
}
