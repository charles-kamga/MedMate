import 'package:equatable/equatable.dart';

/// Représente la session d'un patient sur Afya Santé.
///
/// La navigation et la recherche sont anonymes et éphémères au départ.
/// Le numéro de téléphone camerounais devient obligatoire au moment de la
/// réservation flash ou confirmation au comptoir.
class PatientSession extends Equatable {
  const PatientSession({
    required this.sessionId,
    required this.createdAt,
    required this.lastActiveAt,
    this.phoneNumber,
  });

  /// Identifiant unique de session (ex. UUID v4 ou token sécurisé).
  final String sessionId;

  /// Numéro de téléphone du patient (+237...), null en navigation anonyme.
  final String? phoneNumber;

  /// Date et heure de création de la session.
  final DateTime createdAt;

  /// Horodatage de la dernière activité patient.
  final DateTime lastActiveAt;

  /// Indique si la session est anonyme (aucun numéro de téléphone renseigné).
  bool get isAnonymous => phoneNumber == null || phoneNumber!.isEmpty;

  /// Crée une copie immuable de l'instance avec des champs modifiés.
  PatientSession copyWith({
    String? sessionId,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return PatientSession(
      sessionId: sessionId ?? this.sessionId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  List<Object?> get props => [sessionId, phoneNumber, createdAt, lastActiveAt];
}
