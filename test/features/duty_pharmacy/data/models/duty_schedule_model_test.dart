import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/duty_pharmacy/data/models/duty_schedule_model.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';

void main() {
  final testDate = DateTime(2026, 11, 9);

  const testPharmacy = PharmacyModel(
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

  final testModel = DutyScheduleModel(
    id: 'duty-bastos-01',
    pharmacy: testPharmacy,
    dateGarde: testDate,
    heureDebut: '20:00',
    heureFin: '08:00',
    verifieParOnpc: true,
    groupeGarde: 'Groupe Centre-Nord ONPC',
  );

  group('DutyScheduleModel', () {
    test('is a subclass of DutySchedule entity', () {
      expect(testModel, isA<DutySchedule>());
    });

    test('fromJson deserializes complete JSON correctly', () {
      final json = <String, dynamic>{
        'id': 'duty-bastos-01',
        'pharmacy': testPharmacy.toJson(),
        'date_garde': testDate.toIso8601String(),
        'heure_debut': '20:00',
        'heure_fin': '08:00',
        'verifie_par_onpc': true,
        'groupe_garde': 'Groupe Centre-Nord ONPC',
      };

      final result = DutyScheduleModel.fromJson(json);

      expect(result, equals(testModel));
      expect(result.id, equals('duty-bastos-01'));
      expect(result.pharmacy.id, equals('pharma-bastos-01'));
      expect(result.dateGarde, equals(testDate));
      expect(result.heureDebut, equals('20:00'));
      expect(result.heureFin, equals('08:00'));
      expect(result.verifieParOnpc, isTrue);
      expect(result.groupeGarde, equals('Groupe Centre-Nord ONPC'));
    });

    test('toJson serializes model correctly', () {
      final json = testModel.toJson();

      expect(json['id'], equals('duty-bastos-01'));
      expect(json['date_garde'], equals(testDate.toIso8601String()));
      expect(json['heure_debut'], equals('20:00'));
      expect(json['heure_fin'], equals('08:00'));
      expect(json['verifie_par_onpc'], isTrue);
      expect(json['groupe_garde'], equals('Groupe Centre-Nord ONPC'));
      final pharmacyJson = json['pharmacy'] as Map<String, dynamic>;
      expect(pharmacyJson['id'], equals('pharma-bastos-01'));
    });

    test('toDomain and fromDomain convert faithfully', () {
      final domain = testModel.toDomain();
      expect(domain, equals(testModel));

      final fromDomain = DutyScheduleModel.fromDomain(domain);
      expect(fromDomain, equals(testModel));
    });

    test('copyWith updates specified fields', () {
      final updated = testModel.copyWith(
        heureDebut: '21:00',
        verifieParOnpc: false,
      );

      expect(updated.heureDebut, equals('21:00'));
      expect(updated.verifieParOnpc, isFalse);
      expect(updated.id, equals(testModel.id));
    });
  });
}
