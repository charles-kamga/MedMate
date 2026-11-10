import 'package:equatable/equatable.dart';

/// Rôle officiel du pharmacien au sein de l'officine selon la nomenclature ONPC.
enum PharmacistRole {
  /// Pharmacien titulaire responsable de l'officine.
  titulaire,

  /// Pharmacien adjoint inscrit à l'ordre.
  adjoint,

  /// Gérant délégué de la pharmacie.
  gerant,

  /// Personnel qualifié au comptoir sous supervision du titulaire.
  comptoir,
}

/// Profil professionnel d'un pharmacien d'officine vérifié par l'ONPC.
class PharmacistProfile extends Equatable {
  const PharmacistProfile({
    required this.userId,
    required this.pharmacyId,
    required this.licenceOnpc,
    required this.role,
    required this.fullName,
    required this.email,
    required this.telephone,
    required this.isVerified,
  });

  /// Identifiant unique d'authentification utilisateur (UUID Supabase Auth).
  final String userId;

  /// Identifiant de l'officine rattachée (UUID).
  final String pharmacyId;

  /// Numéro de licence / inscription à l'Ordre National des Pharmaciens (ONPC).
  final String licenceOnpc;

  /// Rôle professionnel au sein de l'officine.
  final PharmacistRole role;

  /// Nom complet avec titre (ex: "Dr. Amadou Bello").
  final String fullName;

  /// Adresse email professionnelle du pharmacien.
  final String email;

  /// Numéro de contact direct ou ligne comptoir (+237...).
  final String telephone;

  /// Statut de vérification auprès du registre déontologique de l'ONPC.
  final bool isVerified;

  /// Crée une copie immuable de l'instance avec des champs modifiés.
  PharmacistProfile copyWith({
    String? userId,
    String? pharmacyId,
    String? licenceOnpc,
    PharmacistRole? role,
    String? fullName,
    String? email,
    String? telephone,
    bool? isVerified,
  }) {
    return PharmacistProfile(
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

  @override
  List<Object?> get props => [
        userId,
        pharmacyId,
        licenceOnpc,
        role,
        fullName,
        email,
        telephone,
        isVerified,
      ];
}
