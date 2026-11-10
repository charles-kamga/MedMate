import 'package:medmate/features/auth/data/models/patient_session_model.dart';
import 'package:medmate/features/auth/data/models/pharmacist_profile_model.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';

/// Modèle DTO pour la session unifiée d'un utilisateur (patient ou pharmacien).
class UserSessionModel extends UserSession {
  const UserSessionModel({
    required super.sessionId,
    required super.createdAt,
    super.patientSession,
    super.pharmacistProfile,
    super.isActive = true,
  });

  /// Désérialise une session unifiée depuis un dictionnaire JSON.
  factory UserSessionModel.fromJson(Map<String, dynamic> json) {
    return UserSessionModel(
      sessionId: json['session_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      patientSession: json['patient_session'] != null
          ? PatientSessionModel.fromJson(
              json['patient_session'] as Map<String, dynamic>,
            )
          : null,
      pharmacistProfile: json['pharmacist_profile'] != null
          ? PharmacistProfileModel.fromJson(
              json['pharmacist_profile'] as Map<String, dynamic>,
            )
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory UserSessionModel.fromDomain(UserSession session) {
    return UserSessionModel(
      sessionId: session.sessionId,
      createdAt: session.createdAt,
      patientSession: session.patientSession != null
          ? PatientSessionModel.fromDomain(session.patientSession!)
          : null,
      pharmacistProfile: session.pharmacistProfile != null
          ? PharmacistProfileModel.fromDomain(session.pharmacistProfile!)
          : null,
      isActive: session.isActive,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
      'patient_session': patientSession != null
          ? PatientSessionModel.fromDomain(patientSession!).toJson()
          : null,
      'pharmacist_profile': pharmacistProfile != null
          ? PharmacistProfileModel.fromDomain(pharmacistProfile!).toJson()
          : null,
    };
  }

  @override
  UserSessionModel copyWith({
    String? sessionId,
    PatientSession? patientSession,
    PharmacistProfile? pharmacistProfile,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return UserSessionModel(
      sessionId: sessionId ?? this.sessionId,
      patientSession: patientSession ?? this.patientSession,
      pharmacistProfile: pharmacistProfile ?? this.pharmacistProfile,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Convertit le modèle en entité du domaine.
  UserSession toDomain() => this;
}
