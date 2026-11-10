import 'package:equatable/equatable.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

/// Planning ou tranche horaire de garde officielle d'une officine de pharmacie.
///
/// Modélise les gardes de nuit, de week-end et de jours fériés homologuées par l'ONPC à Yaoundé.
class DutySchedule extends Equatable {
  const DutySchedule({
    required this.id,
    required this.pharmacy,
    required this.dateGarde,
    required this.heureDebut,
    required this.heureFin,
    required this.verifieParOnpc,
    this.groupeGarde,
  });

  /// Identifiant unique du créneau de garde (UUID).
  final String id;

  /// Officine assurant la permanence de garde.
  final Pharmacy pharmacy;

  /// Date de la garde (jour civil).
  final DateTime dateGarde;

  /// Heure de début de garde (format "HH:mm", ex: "20:00").
  final String heureDebut;

  /// Heure de fin de garde (format "HH:mm", ex: "08:00").
  final String heureFin;

  /// Indique si ce tour de garde a été certifié par l'Ordre National des Pharmaciens (ONPC).
  final bool verifieParOnpc;

  /// Libellé du groupe ou secteur de garde (ex: "Groupe Centre 1", "Secteur Ouest").
  final String? groupeGarde;

  /// Crée une copie immuable avec les champs modifiés.
  DutySchedule copyWith({
    String? id,
    Pharmacy? pharmacy,
    DateTime? dateGarde,
    String? heureDebut,
    String? heureFin,
    bool? verifieParOnpc,
    String? groupeGarde,
  }) {
    return DutySchedule(
      id: id ?? this.id,
      pharmacy: pharmacy ?? this.pharmacy,
      dateGarde: dateGarde ?? this.dateGarde,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      verifieParOnpc: verifieParOnpc ?? this.verifieParOnpc,
      groupeGarde: groupeGarde ?? this.groupeGarde,
    );
  }

  @override
  List<Object?> get props => [
        id,
        pharmacy,
        dateGarde,
        heureDebut,
        heureFin,
        verifieParOnpc,
        groupeGarde,
      ];
}
