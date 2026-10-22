import 'package:equatable/equatable.dart';

/// Entité représentant la session utilisateur (Patient ou Pharmacien)
class UserSession extends Equatable {
  const UserSession({
    required this.userId,
    required this.telephone,
    required this.estAuthentifie,
    this.estAnonyme = false,
    this.nomComplet,
  });

  factory UserSession.guest() {
    return const UserSession(
      userId: 'guest-session',
      telephone: '',
      estAuthentifie: false,
      estAnonyme: true,
      nomComplet: 'Patient Invité',
    );
  }

  final String userId;
  final String telephone;
  final bool estAuthentifie;
  final bool estAnonyme;
  final String? nomComplet;

  @override
  List<Object?> get props => [userId, telephone, estAuthentifie, estAnonyme, nomComplet];
}
