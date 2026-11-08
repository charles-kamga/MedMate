import 'package:equatable/equatable.dart';

/// Rôle actif de l'utilisateur
enum UserRole {
  patient,
  pharmacist,
}

/// Profil professionnel d'un pharmacien connecté
class PharmacyStaffProfile extends Equatable {
  const PharmacyStaffProfile({
    required this.pharmacyId,
    required this.pharmacyName,
    required this.licenceOnpc,
    required this.responsable,
    required this.quarter,
    required this.telephone,
    this.estDeGarde = false,
  });

  final String pharmacyId;
  final String pharmacyName;
  final String licenceOnpc;
  final String responsable;
  final String quarter;
  final String telephone;
  final bool estDeGarde;

  @override
  List<Object?> get props => [
        pharmacyId,
        pharmacyName,
        licenceOnpc,
        responsable,
        quarter,
        telephone,
        estDeGarde,
      ];
}

/// Entité représentant la session utilisateur (Patient ou Pharmacien)
class UserSession extends Equatable {
  const UserSession({
    required this.userId,
    required this.telephone,
    required this.estAuthentifie,
    this.estAnonyme = false,
    this.role = UserRole.patient,
    this.nomComplet,
    this.pharmacyProfile,
  });

  factory UserSession.guest() {
    return const UserSession(
      userId: 'guest-session',
      telephone: '',
      estAuthentifie: false,
      estAnonyme: true,
      role: UserRole.patient,
      nomComplet: 'Patient Invité',
    );
  }

  factory UserSession.patient({
    required String telephone,
    String? nomComplet,
  }) {
    return UserSession(
      userId: 'patient-${DateTime.now().millisecondsSinceEpoch}',
      telephone: telephone,
      estAuthentifie: true,
      estAnonyme: false,
      role: UserRole.patient,
      nomComplet: nomComplet ?? 'Patient Afya',
    );
  }

  factory UserSession.pharmacist({
    required String telephone,
    required PharmacyStaffProfile profile,
  }) {
    return UserSession(
      userId: 'pharma-${profile.pharmacyId}',
      telephone: telephone,
      estAuthentifie: true,
      estAnonyme: false,
      role: UserRole.pharmacist,
      nomComplet: profile.responsable,
      pharmacyProfile: profile,
    );
  }

  final String userId;
  final String telephone;
  final bool estAuthentifie;
  final bool estAnonyme;
  final UserRole role;
  final String? nomComplet;
  final PharmacyStaffProfile? pharmacyProfile;

  bool get isPharmacist => role == UserRole.pharmacist;
  bool get isPatient => role == UserRole.patient;

  @override
  List<Object?> get props => [
        userId,
        telephone,
        estAuthentifie,
        estAnonyme,
        role,
        nomComplet,
        pharmacyProfile,
      ];
}
