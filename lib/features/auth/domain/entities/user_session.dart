import 'package:equatable/equatable.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';

/// Session unifiée représentant soit une navigation patient, soit une session pharmacien.
class UserSession extends Equatable {
  const UserSession({
    required this.sessionId,
    required this.createdAt,
    this.patientSession,
    this.pharmacistProfile,
    this.isActive = true,
  });

  /// Identifiant unique de session globale.
  final String sessionId;

  /// Détails de session patient si l'utilisateur est un patient.
  final PatientSession? patientSession;

  /// Profil pharmacien si l'utilisateur est un professionnel authentifié.
  final PharmacistProfile? pharmacistProfile;

  /// Horodatage de création de la session.
  final DateTime createdAt;

  /// Indique si la session est actuellement active et valide.
  final bool isActive;

  /// Indique si l'utilisateur connecté est un pharmacien d'officine.
  bool get isPharmacist => pharmacistProfile != null;

  /// Indique si la session correspond à un patient.
  bool get isPatient => patientSession != null;

  /// Indique si la session est pleinement authentifiée (pharmacien ou patient identifié avec téléphone).
  bool get isAuthenticated =>
      isPharmacist || (patientSession != null && !patientSession!.isAnonymous);

  /// Crée une copie immuable de la session avec des champs modifiés.
  UserSession copyWith({
    String? sessionId,
    PatientSession? patientSession,
    PharmacistProfile? pharmacistProfile,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserSession(
      sessionId: sessionId ?? this.sessionId,
      patientSession: patientSession ?? this.patientSession,
      pharmacistProfile: pharmacistProfile ?? this.pharmacistProfile,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        patientSession,
        pharmacistProfile,
        createdAt,
        isActive,
      ];
}
