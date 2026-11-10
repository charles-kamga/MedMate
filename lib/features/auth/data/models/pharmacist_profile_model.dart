import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';

/// Modèle DTO pour le profil d'un pharmacien d'officine vérifié par l'ONPC.
class PharmacistProfileModel extends PharmacistProfile {
  const PharmacistProfileModel({
    required super.userId,
    required super.pharmacyId,
    required super.licenceOnpc,
    required super.role,
    required super.fullName,
    required super.email,
    required super.telephone,
    required super.isVerified,
  });

  /// Désérialise un profil pharmacien depuis un dictionnaire JSON.
  factory PharmacistProfileModel.fromJson(Map<String, dynamic> json) {
    final roleStr = json['role'] as String;
    final role = PharmacistRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => PharmacistRole.comptoir,
    );

    return PharmacistProfileModel(
      userId: json['user_id'] as String,
      pharmacyId: json['pharmacy_id'] as String,
      licenceOnpc: json['licence_onpc'] as String,
      role: role,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      telephone: json['telephone'] as String,
      isVerified: json['is_verified'] as bool? ?? false,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory PharmacistProfileModel.fromDomain(PharmacistProfile profile) {
    return PharmacistProfileModel(
      userId: profile.userId,
      pharmacyId: profile.pharmacyId,
      licenceOnpc: profile.licenceOnpc,
      role: profile.role,
      fullName: profile.fullName,
      email: profile.email,
      telephone: profile.telephone,
      isVerified: profile.isVerified,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'pharmacy_id': pharmacyId,
      'licence_onpc': licenceOnpc,
      'role': role.name,
      'full_name': fullName,
      'email': email,
      'telephone': telephone,
      'is_verified': isVerified,
    };
  }

  @override
  PharmacistProfileModel copyWith({
    String? userId,
    String? pharmacyId,
    String? licenceOnpc,
    PharmacistRole? role,
    String? fullName,
    String? email,
    String? telephone,
    bool? isVerified,
  }) {
    return PharmacistProfileModel(
      userId: userId ?? this.userId,
      pharmacyId: pharmacyId ?? this.pharmacyId,
      licenceOnpc: licenceOnpc ?? this.licenceOnpc,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      telephone: telephone ?? this.telephone,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  /// Convertit le modèle en entité du domaine.
  PharmacistProfile toDomain() => this;
}
