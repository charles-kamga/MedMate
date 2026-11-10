import 'package:medmate/features/auth/domain/entities/patient_session.dart';

/// Modèle DTO pour la session d'un patient sur Afya Santé.
class PatientSessionModel extends PatientSession {
  const PatientSessionModel({
    required super.sessionId,
    required super.createdAt,
    required super.lastActiveAt,
    super.phoneNumber,
  });

  /// Désérialise une session patient depuis un dictionnaire JSON.
  factory PatientSessionModel.fromJson(Map<String, dynamic> json) {
    return PatientSessionModel(
      sessionId: json['session_id'] as String,
      phoneNumber: json['phone_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory PatientSessionModel.fromDomain(PatientSession session) {
    return PatientSessionModel(
      sessionId: session.sessionId,
      phoneNumber: session.phoneNumber,
      createdAt: session.createdAt,
      lastActiveAt: session.lastActiveAt,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'last_active_at': lastActiveAt.toIso8601String(),
    };
  }

  @override
  PatientSessionModel copyWith({
    String? sessionId,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return PatientSessionModel(
      sessionId: sessionId ?? this.sessionId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  /// Convertit le modèle en entité du domaine.
  PatientSession toDomain() => this;
}
