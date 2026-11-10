import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

void main() {
  group('DutySchedule Entity & ONPC Certification Flag', () {
    const samplePharmacy = Pharmacy(
      id: 'pharma-bastos',
      nom: 'Pharmacie Bastos',
      licenceOnpc: 'ONPC-CMR-1029',
      quartier: 'Bastos',
      carrefourRepere: 'Carrefour Warda',
      latitude: 3.8821,
      longitude: 11.5165,
      telephoneGarde: '+237699112233',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: true,
    );

    const samplePharmacy2 = Pharmacy(
      id: 'pharma-mokolo',
      nom: 'Pharmacie Mokolo',
      licenceOnpc: 'ONPC-CMR-8472',
      quartier: 'Mokolo',
      carrefourRepere: 'Marché Mokolo',
      latitude: 3.8710,
      longitude: 11.5020,
      telephoneGarde: '+237677445566',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: false,
    );

    final fixedDate = DateTime(2026, 11, 9);

    final scheduleA = DutySchedule(
      id: 'duty-1',
      pharmacy: samplePharmacy,
      dateGarde: fixedDate,
      heureDebut: '20:00',
      heureFin: '08:00',
      verifieParOnpc: true,
      groupeGarde: 'Groupe Centre 1',
    );

    final scheduleB = DutySchedule(
      id: 'duty-1',
      pharmacy: samplePharmacy,
      dateGarde: fixedDate,
      heureDebut: '20:00',
      heureFin: '08:00',
      verifieParOnpc: true,
      groupeGarde: 'Groupe Centre 1',
    );

    final scheduleOther = DutySchedule(
      id: 'duty-2',
      pharmacy: samplePharmacy2,
      dateGarde: fixedDate,
      heureDebut: '19:00',
      heureFin: '07:00',
      verifieParOnpc: false,
    );

    test('supports value equality via props', () {
      expect(scheduleA, equals(scheduleB));
      expect(scheduleA, isNot(equals(scheduleOther)));
      expect(scheduleA.props, [
        'duty-1',
        samplePharmacy,
        fixedDate,
        '20:00',
        '08:00',
        true,
        'Groupe Centre 1',
      ]);
    });

    test('verifieParOnpc flag correctly reflects official ONPC certification', () {
      expect(scheduleA.verifieParOnpc, isTrue);
      expect(scheduleOther.verifieParOnpc, isFalse);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = scheduleA.copyWith(
        verifieParOnpc: false,
        heureDebut: '21:00',
      );

      expect(updated.id, equals('duty-1'));
      expect(updated.verifieParOnpc, isFalse);
      expect(updated.heureDebut, equals('21:00'));
      expect(updated.heureFin, equals('08:00'));
      expect(updated.pharmacy, equals(samplePharmacy));
    });
  });
}
