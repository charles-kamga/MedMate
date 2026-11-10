import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/duty_pharmacy/data/datasources/duty_pharmacy_data_source.dart';
import 'package:medmate/features/duty_pharmacy/data/models/duty_schedule_model.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';

void main() {
  late DutyPharmacyDataSourceImpl dataSource;

  final testDate = DateTime(2026, 11, 9);
  final otherDate = DateTime(2026, 11, 15);

  const bastosPharma = PharmacyModel(
    id: 'pharma-bastos-01',
    nom: 'Pharmacie de Bastos',
    licenceOnpc: 'ONPC-YDE-001',
    quartier: 'Bastos',
    carrefourRepere: 'Carrefour Warda',
    latitude: 3.8688,
    longitude: 11.5175,
    telephoneGarde: '+237222201122',
    estOuverte: true,
    estDeGarde: true,
    estPartenaire: true,
  );

  const mokoloPharma = PharmacyModel(
    id: 'pharma-mokolo-01',
    nom: 'Pharmacie du Marché Mokolo',
    licenceOnpc: 'ONPC-YDE-002',
    quartier: 'Mokolo',
    carrefourRepere: 'Marché Mokolo',
    latitude: 3.8740,
    longitude: 11.5020,
    telephoneGarde: '+237222214433',
    estOuverte: true,
    estDeGarde: true,
    estPartenaire: true,
  );

  final customSchedules = [
    DutyScheduleModel(
      id: 'duty-bastos-1',
      pharmacy: bastosPharma,
      dateGarde: testDate,
      heureDebut: '20:00',
      heureFin: '08:00',
      verifieParOnpc: true,
      groupeGarde: 'Groupe Bastos',
    ),
    DutyScheduleModel(
      id: 'duty-mokolo-1',
      pharmacy: mokoloPharma,
      dateGarde: testDate,
      heureDebut: '18:00',
      heureFin: '08:00',
      verifieParOnpc: true,
      groupeGarde: 'Groupe Mokolo',
    ),
    DutyScheduleModel(
      id: 'duty-bastos-2',
      pharmacy: bastosPharma,
      dateGarde: otherDate,
      heureDebut: '20:00',
      heureFin: '08:00',
      verifieParOnpc: true,
      groupeGarde: 'Groupe Bastos',
    ),
  ];

  setUp(() {
    dataSource = DutyPharmacyDataSourceImpl(customSchedules: customSchedules);
  });

  group('DutyPharmacyDataSourceImpl', () {
    group('defaultSeededSchedules', () {
      test('default instance contains realistic seeded schedules for Yaoundé', () async {
        const defaultSource = DutyPharmacyDataSourceImpl();
        final schedules = await defaultSource.getAllActiveDutySchedules();

        expect(schedules, isNotEmpty);
        expect(schedules.any((s) => s.pharmacy.quartier == 'Bastos'), isTrue);
        expect(schedules.every((s) => s.verifieParOnpc), isTrue);
      });
    });

    group('getDutyPharmaciesByQuartier', () {
      test('filters duty schedules by quartier case-insensitively', () async {
        final results = await dataSource.getDutyPharmaciesByQuartier(
          quartier: 'bastos',
        );

        expect(results.length, equals(2));
        expect(results.every((s) => s.pharmacy.quartier == 'Bastos'), isTrue);
      });

      test('filters by targetDate when specified', () async {
        final results = await dataSource.getDutyPharmaciesByQuartier(
          quartier: 'Bastos',
          targetDate: testDate,
        );

        expect(results.length, equals(1));
        expect(results.first.id, equals('duty-bastos-1'));
      });

      test('returns empty list when no schedule matches quartier', () async {
        final results = await dataSource.getDutyPharmaciesByQuartier(
          quartier: 'QuartierInconnu',
        );

        expect(results, isEmpty);
      });
    });

    group('getAllActiveDutySchedules', () {
      test('returns all schedules when targetDate is null', () async {
        final results = await dataSource.getAllActiveDutySchedules();
        expect(results.length, equals(3));
      });

      test('returns schedules matching targetDate', () async {
        final results = await dataSource.getAllActiveDutySchedules(
          targetDate: testDate,
        );

        expect(results.length, equals(2));
        expect(results.map((s) => s.id), containsAll(['duty-bastos-1', 'duty-mokolo-1']));
      });

      test('returns empty list when no schedules on given targetDate', () async {
        final results = await dataSource.getAllActiveDutySchedules(
          targetDate: DateTime(2030, 1, 1),
        );

        expect(results, isEmpty);
      });
    });
  });
}
