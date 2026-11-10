import 'package:medmate/features/duty_pharmacy/data/models/duty_schedule_model.dart';
import 'package:medmate/features/pharmacy_search/data/datasources/yaounde_pharmacy_data_source.dart';

/// Contrat de la source de données pour les plannings de pharmacie de garde à Yaoundé.
abstract class DutyPharmacyDataSource {
  /// Récupère la liste des officines de garde pour un quartier de Yaoundé.
  Future<List<DutyScheduleModel>> getDutyPharmaciesByQuartier({
    required String quartier,
    DateTime? targetDate,
  });

  /// Récupère l'ensemble des plannings de garde actifs pour Yaoundé.
  Future<List<DutyScheduleModel>> getAllActiveDutySchedules({
    DateTime? targetDate,
  });
}

/// Implémentation en mémoire des tours de garde homologués par l'ONPC à Yaoundé.
class DutyPharmacyDataSourceImpl implements DutyPharmacyDataSource {
  const DutyPharmacyDataSourceImpl({
    List<DutyScheduleModel>? customSchedules,
  }) : _customSchedules = customSchedules;

  final List<DutyScheduleModel>? _customSchedules;

  /// Génère le tableau de garde officiel homologué par l'ONPC.
  static List<DutyScheduleModel> get defaultSeededSchedules {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    final bastosPharma = YaoundePharmacyDataSourceImpl.seededPharmacies
        .firstWhere((p) => p.id == 'pharma-bastos-01');
    final biyemPharma = YaoundePharmacyDataSourceImpl.seededPharmacies
        .firstWhere((p) => p.id == 'pharma-biyem-01');
    final tsingaPharma = YaoundePharmacyDataSourceImpl.seededPharmacies
        .firstWhere((p) => p.id == 'pharma-tsinga-01');
    final nsamPharma = YaoundePharmacyDataSourceImpl.seededPharmacies
        .firstWhere((p) => p.id == 'pharma-nsam-01');
    final centrePharma = YaoundePharmacyDataSourceImpl.seededPharmacies
        .firstWhere((p) => p.id == 'pharma-centre-01');

    return [
      DutyScheduleModel(
        id: 'duty-bastos-today',
        pharmacy: bastosPharma,
        dateGarde: today,
        heureDebut: '20:00',
        heureFin: '08:00',
        verifieParOnpc: true,
        groupeGarde: 'Groupe Centre-Nord ONPC',
      ),
      DutyScheduleModel(
        id: 'duty-biyem-today',
        pharmacy: biyemPharma,
        dateGarde: today,
        heureDebut: '20:00',
        heureFin: '08:00',
        verifieParOnpc: true,
        groupeGarde: 'Groupe Sud-Ouest ONPC',
      ),
      DutyScheduleModel(
        id: 'duty-tsinga-today',
        pharmacy: tsingaPharma,
        dateGarde: today,
        heureDebut: '18:00',
        heureFin: '08:00',
        verifieParOnpc: true,
        groupeGarde: 'Groupe Ouest ONPC',
      ),
      DutyScheduleModel(
        id: 'duty-nsam-today',
        pharmacy: nsamPharma,
        dateGarde: today,
        heureDebut: '20:00',
        heureFin: '08:00',
        verifieParOnpc: true,
        groupeGarde: 'Groupe Sud ONPC',
      ),
      DutyScheduleModel(
        id: 'duty-centre-today',
        pharmacy: centrePharma,
        dateGarde: today,
        heureDebut: '00:00',
        heureFin: '23:59',
        verifieParOnpc: true,
        groupeGarde: 'Permanence Centrale 24/7 ONPC',
      ),
      DutyScheduleModel(
        id: 'duty-bastos-tomorrow',
        pharmacy: bastosPharma,
        dateGarde: tomorrow,
        heureDebut: '20:00',
        heureFin: '08:00',
        verifieParOnpc: true,
        groupeGarde: 'Groupe Centre-Nord ONPC',
      ),
    ];
  }

  List<DutyScheduleModel> get _schedules =>
      _customSchedules ?? defaultSeededSchedules;

  @override
  Future<List<DutyScheduleModel>> getDutyPharmaciesByQuartier({
    required String quartier,
    DateTime? targetDate,
  }) async {
    final cleanQuartier = _normalize(quartier.trim());

    var matches = _schedules.where((schedule) {
      final scheduleQuartier = _normalize(schedule.pharmacy.quartier);
      return scheduleQuartier.contains(cleanQuartier);
    }).toList();

    if (targetDate != null) {
      matches = matches.where((schedule) {
        return _isSameDay(schedule.dateGarde, targetDate);
      }).toList();
    }

    return matches;
  }

  @override
  Future<List<DutyScheduleModel>> getAllActiveDutySchedules({
    DateTime? targetDate,
  }) async {
    if (targetDate == null) {
      return List<DutyScheduleModel>.from(_schedules);
    }

    return _schedules
        .where((schedule) => _isSameDay(schedule.dateGarde, targetDate))
        .toList();
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp('[ûüù]'), 'u')
        .replaceAll(RegExp('[ç]'), 'c');
  }
}
