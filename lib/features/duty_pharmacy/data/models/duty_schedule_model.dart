import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

/// Modèle DTO pour un créneau de garde officielle homologué par l'ONPC.
class DutyScheduleModel extends DutySchedule {
  const DutyScheduleModel({
    required super.id,
    required super.pharmacy,
    required super.dateGarde,
    required super.heureDebut,
    required super.heureFin,
    required super.verifieParOnpc,
    super.groupeGarde,
  });

  /// Désérialise un créneau de garde depuis un dictionnaire JSON.
  factory DutyScheduleModel.fromJson(Map<String, dynamic> json) {
    return DutyScheduleModel(
      id: json['id'] as String,
      pharmacy: PharmacyModel.fromJson(
        json['pharmacy'] as Map<String, dynamic>,
      ),
      dateGarde: DateTime.parse(json['date_garde'] as String),
      heureDebut: json['heure_debut'] as String,
      heureFin: json['heure_fin'] as String,
      verifieParOnpc: json['verifie_par_onpc'] as bool? ?? true,
      groupeGarde: json['groupe_garde'] as String?,
    );
  }

  /// Convertit une entité de domaine en modèle de données.
  factory DutyScheduleModel.fromDomain(DutySchedule schedule) {
    return DutyScheduleModel(
      id: schedule.id,
      pharmacy: schedule.pharmacy,
      dateGarde: schedule.dateGarde,
      heureDebut: schedule.heureDebut,
      heureFin: schedule.heureFin,
      verifieParOnpc: schedule.verifieParOnpc,
      groupeGarde: schedule.groupeGarde,
    );
  }

  /// Sérialise le modèle en dictionnaire JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pharmacy': PharmacyModel.fromDomain(pharmacy).toJson(),
      'date_garde': dateGarde.toIso8601String(),
      'heure_debut': heureDebut,
      'heure_fin': heureFin,
      'verifie_par_onpc': verifieParOnpc,
      'groupe_garde': groupeGarde,
    };
  }

  @override
  DutyScheduleModel copyWith({
    String? id,
    Pharmacy? pharmacy,
    DateTime? dateGarde,
    String? heureDebut,
    String? heureFin,
    bool? verifieParOnpc,
    String? groupeGarde,
  }) {
    return DutyScheduleModel(
      id: id ?? this.id,
      pharmacy: pharmacy ?? this.pharmacy,
      dateGarde: dateGarde ?? this.dateGarde,
      heureDebut: heureDebut ?? this.heureDebut,
      heureFin: heureFin ?? this.heureFin,
      verifieParOnpc: verifieParOnpc ?? this.verifieParOnpc,
      groupeGarde: groupeGarde ?? this.groupeGarde,
    );
  }

  /// Convertit le modèle en entité du domaine.
  DutySchedule toDomain() => this;
}
