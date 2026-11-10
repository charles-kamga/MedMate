import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';

void main() {
  group('Adversarial Stress Test: Value Equality & Immutability', () {
    final t0 = DateTime(2026, 11, 9, 10, 0, 0);
    final t1 = DateTime(2026, 11, 9, 10, 0, 0, 1); // 1 ms difference

    group('PatientSession Stress Tests', () {
      final base = PatientSession(
        sessionId: 'sess-base-001',
        createdAt: t0,
        lastActiveAt: t0,
        phoneNumber: '+237699112233',
      );

      test('reflexivity, symmetry, and identical copyWith()', () {
        expect(base == base, isTrue);
        final copyNoArgs = base.copyWith();
        expect(base == copyNoArgs, isTrue);
        expect(copyNoArgs == base, isTrue);
        expect(base.hashCode, equals(copyNoArgs.hashCode));
      });

      test('props count strictly matches field count (4)', () {
        expect(base.props.length, equals(4));
      });

      test('individual field mutation sensitivity: sessionId', () {
        final mutated = base.copyWith(sessionId: 'sess-base-MUTATED');
        expect(mutated, isNot(equals(base)));
        expect(mutated.sessionId, equals('sess-base-MUTATED'));
        expect(mutated.createdAt, equals(base.createdAt));
        expect(mutated.lastActiveAt, equals(base.lastActiveAt));
        expect(mutated.phoneNumber, equals(base.phoneNumber));
      });

      test('individual field mutation sensitivity: createdAt', () {
        final mutated = base.copyWith(createdAt: t1);
        expect(mutated, isNot(equals(base)));
        expect(mutated.createdAt, equals(t1));
        expect(mutated.sessionId, equals(base.sessionId));
      });

      test('individual field mutation sensitivity: lastActiveAt', () {
        final mutated = base.copyWith(lastActiveAt: t1);
        expect(mutated, isNot(equals(base)));
        expect(mutated.lastActiveAt, equals(t1));
        expect(mutated.createdAt, equals(base.createdAt));
      });

      test('individual field mutation sensitivity: phoneNumber', () {
        final mutated = base.copyWith(phoneNumber: '+237677889900');
        expect(mutated, isNot(equals(base)));
        expect(mutated.phoneNumber, equals('+237677889900'));
      });

      test('anonymity logic stress: null, empty, non-empty', () {
        expect(base.isAnonymous, isFalse);
        final anonNull = PatientSession(
          sessionId: 's1',
          createdAt: t0,
          lastActiveAt: t0,
          phoneNumber: null,
        );
        expect(anonNull.isAnonymous, isTrue);
        final anonEmpty = PatientSession(
          sessionId: 's2',
          createdAt: t0,
          lastActiveAt: t0,
          phoneNumber: '',
        );
        expect(anonEmpty.isAnonymous, isTrue);
      });
    });

    group('PharmacistProfile Stress Tests', () {
      const base = PharmacistProfile(
        userId: 'usr-001',
        pharmacyId: 'pharma-001',
        licenceOnpc: 'ONPC-CMR-1234',
        role: PharmacistRole.titulaire,
        fullName: 'Dr. Jean Dupont',
        email: 'jean.dupont@afyasante.cm',
        telephone: '+237699112233',
        isVerified: true,
      );

      test('props count strictly matches field count (8)', () {
        expect(base.props.length, equals(8));
      });

      test('reflexivity and copyWith() zero-args equality', () {
        expect(base == base, isTrue);
        final copyNoArgs = base.copyWith();
        expect(base == copyNoArgs, isTrue);
        expect(base.hashCode, equals(copyNoArgs.hashCode));
      });

      test('individual field mutation sensitivity: all 8 fields', () {
        // 1. userId
        expect(base.copyWith(userId: 'usr-MUTATED'), isNot(equals(base)));
        // 2. pharmacyId
        expect(base.copyWith(pharmacyId: 'pharma-MUTATED'), isNot(equals(base)));
        // 3. licenceOnpc
        expect(base.copyWith(licenceOnpc: 'ONPC-MUTATED'), isNot(equals(base)));
        // 4. role
        for (final r in PharmacistRole.values) {
          if (r != base.role) {
            expect(base.copyWith(role: r), isNot(equals(base)));
          }
        }
        // 5. fullName
        expect(base.copyWith(fullName: 'Dr. Autre'), isNot(equals(base)));
        // 6. email
        expect(base.copyWith(email: 'other@afyasante.cm'), isNot(equals(base)));
        // 7. telephone
        expect(base.copyWith(telephone: '+237600000000'), isNot(equals(base)));
        // 8. isVerified
        expect(base.copyWith(isVerified: false), isNot(equals(base)));
      });

      test('copyWith preserves all other 7 fields when 1 is modified', () {
        final modified = base.copyWith(fullName: 'Dr. Modifié');
        expect(modified.fullName, equals('Dr. Modifié'));
        expect(modified.userId, equals(base.userId));
        expect(modified.pharmacyId, equals(base.pharmacyId));
        expect(modified.licenceOnpc, equals(base.licenceOnpc));
        expect(modified.role, equals(base.role));
        expect(modified.email, equals(base.email));
        expect(modified.telephone, equals(base.telephone));
        expect(modified.isVerified, equals(base.isVerified));
      });
    });

    group('UserSession Stress Tests', () {
      final patSession = PatientSession(
        sessionId: 'pat-001',
        createdAt: t0,
        lastActiveAt: t0,
        phoneNumber: '+237699112233',
      );

      const pharmaProfile = PharmacistProfile(
        userId: 'usr-001',
        pharmacyId: 'pharma-001',
        licenceOnpc: 'ONPC-CMR-1234',
        role: PharmacistRole.titulaire,
        fullName: 'Dr. Jean Dupont',
        email: 'jean.dupont@afyasante.cm',
        telephone: '+237699112233',
        isVerified: true,
      );

      final base = UserSession(
        sessionId: 'user-sess-base',
        createdAt: t0,
        patientSession: patSession,
        pharmacistProfile: pharmaProfile,
        isActive: true,
      );

      test('props count strictly matches field count (5)', () {
        expect(base.props.length, equals(5));
      });

      test('reflexivity and copyWith() zero-args equality', () {
        expect(base == base, isTrue);
        final copyNoArgs = base.copyWith();
        expect(base == copyNoArgs, isTrue);
        expect(base.hashCode, equals(copyNoArgs.hashCode));
      });

      test('individual field mutation sensitivity: all 5 fields', () {
        // 1. sessionId
        expect(base.copyWith(sessionId: 'new-id'), isNot(equals(base)));
        // 2. patientSession
        expect(
          base.copyWith(
            patientSession: patSession.copyWith(sessionId: 'pat-other'),
          ),
          isNot(equals(base)),
        );
        // 3. pharmacistProfile
        expect(
          base.copyWith(
            pharmacistProfile: pharmaProfile.copyWith(userId: 'usr-other'),
          ),
          isNot(equals(base)),
        );
        // 4. createdAt
        expect(base.copyWith(createdAt: t1), isNot(equals(base)));
        // 5. isActive
        expect(base.copyWith(isActive: false), isNot(equals(base)));
      });

      test('authentication matrix exhaustive stress', () {
        // Neither profile nor patient session
        final emptySession = UserSession(sessionId: 's', createdAt: t0);
        expect(emptySession.isPatient, isFalse);
        expect(emptySession.isPharmacist, isFalse);
        expect(emptySession.isAuthenticated, isFalse);

        // Anonymous patient session
        final anonPatient = PatientSession(
          sessionId: 'p-anon',
          createdAt: t0,
          lastActiveAt: t0,
        );
        final anonSession = UserSession(
          sessionId: 's',
          createdAt: t0,
          patientSession: anonPatient,
        );
        expect(anonSession.isPatient, isTrue);
        expect(anonSession.isPharmacist, isFalse);
        expect(anonSession.isAuthenticated, isFalse);

        // Identified patient session (with phone)
        final identifiedPatient = PatientSession(
          sessionId: 'p-id',
          createdAt: t0,
          lastActiveAt: t0,
          phoneNumber: '+237677112233',
        );
        final identifiedSession = UserSession(
          sessionId: 's',
          createdAt: t0,
          patientSession: identifiedPatient,
        );
        expect(identifiedSession.isPatient, isTrue);
        expect(identifiedSession.isPharmacist, isFalse);
        expect(identifiedSession.isAuthenticated, isTrue);

        // Pharmacist session
        final pharmacistSession = UserSession(
          sessionId: 's',
          createdAt: t0,
          pharmacistProfile: pharmaProfile,
        );
        expect(pharmacistSession.isPatient, isFalse);
        expect(pharmacistSession.isPharmacist, isTrue);
        expect(pharmacistSession.isAuthenticated, isTrue);
      });
    });

    group('Medication Stress Tests & Zéro Prix Invariant', () {
      const base = Medication(
        id: 'med-001',
        codeNational: 'CIP-1234567890123',
        nomCommercial: 'Doliprane 1000mg',
        dci: 'Paracétamol',
        forme: 'Comprimé',
        dosage: '1000 mg',
        necessiteOrdonnance: false,
      );

      test('props count strictly matches field count (7)', () {
        expect(base.props.length, equals(7));
      });

      test('reflexivity and copyWith() zero-args equality', () {
        expect(base == base, isTrue);
        final copyNoArgs = base.copyWith();
        expect(base == copyNoArgs, isTrue);
        expect(base.hashCode, equals(copyNoArgs.hashCode));
      });

      test('individual field mutation sensitivity: all 7 fields', () {
        // 1. id
        expect(base.copyWith(id: 'med-MUTATED'), isNot(equals(base)));
        // 2. codeNational
        expect(base.copyWith(codeNational: 'CIP-MUTATED'), isNot(equals(base)));
        // 3. nomCommercial
        expect(base.copyWith(nomCommercial: 'Efferalgan'), isNot(equals(base)));
        // 4. dci
        expect(base.copyWith(dci: 'Ibuprofène'), isNot(equals(base)));
        // 5. forme
        expect(base.copyWith(forme: 'Sirop'), isNot(equals(base)));
        // 6. dosage
        expect(base.copyWith(dosage: '500 mg'), isNot(equals(base)));
        // 7. necessiteOrdonnance
        expect(base.copyWith(necessiteOrdonnance: true), isNot(equals(base)));
      });

      test('INVIOLABLE: Medication contains zero price/currency data', () {
        // 1. All props are either String or bool
        for (final prop in base.props) {
          expect(prop is String || prop is bool, isTrue);
          expect(prop is num, isFalse);
        }

        // 2. copyWith preserves all other 6 fields
        final mutated = base.copyWith(nomCommercial: 'Nouveau Nom');
        expect(mutated.nomCommercial, equals('Nouveau Nom'));
        expect(mutated.id, equals(base.id));
        expect(mutated.codeNational, equals(base.codeNational));
        expect(mutated.dci, equals(base.dci));
        expect(mutated.forme, equals(base.forme));
        expect(mutated.dosage, equals(base.dosage));
        expect(mutated.necessiteOrdonnance, equals(base.necessiteOrdonnance));
      });
    });

    group('Pharmacy Stress Tests', () {
      const base = Pharmacy(
        id: 'pharma-001',
        nom: 'Pharmacie Bastos',
        licenceOnpc: 'ONPC-CMR-5678',
        quartier: 'Bastos',
        carrefourRepere: 'Carrefour Warda',
        latitude: 3.8812,
        longitude: 11.5173,
        telephoneGarde: '+237699112233',
        estOuverte: true,
        estDeGarde: true,
        estPartenaire: true,
        distanceMetres: 250,
      );

      test('props count strictly matches field count (12)', () {
        expect(base.props.length, equals(12));
      });

      test('reflexivity and copyWith() zero-args equality', () {
        expect(base == base, isTrue);
        final copyNoArgs = base.copyWith();
        expect(base == copyNoArgs, isTrue);
        expect(base.hashCode, equals(copyNoArgs.hashCode));
      });

      test('individual field mutation sensitivity: all 12 fields', () {
        // 1. id
        expect(base.copyWith(id: 'ph-MUT'), isNot(equals(base)));
        // 2. nom
        expect(base.copyWith(nom: 'Pharmacie Nouvelle'), isNot(equals(base)));
        // 3. licenceOnpc
        expect(base.copyWith(licenceOnpc: 'ONPC-MUT'), isNot(equals(base)));
        // 4. quartier
        expect(base.copyWith(quartier: 'Mokolo'), isNot(equals(base)));
        // 5. carrefourRepere
        expect(base.copyWith(carrefourRepere: 'Carrefour Obili'), isNot(equals(base)));
        // 6. latitude
        expect(base.copyWith(latitude: 3.8813), isNot(equals(base)));
        // 7. longitude
        expect(base.copyWith(longitude: 11.5174), isNot(equals(base)));
        // 8. telephoneGarde
        expect(base.copyWith(telephoneGarde: '+237600000000'), isNot(equals(base)));
        // 9. estOuverte
        expect(base.copyWith(estOuverte: false), isNot(equals(base)));
        // 10. estDeGarde
        expect(base.copyWith(estDeGarde: false), isNot(equals(base)));
        // 11. estPartenaire
        expect(base.copyWith(estPartenaire: false), isNot(equals(base)));
        // 12. distanceMetres
        expect(base.copyWith(distanceMetres: 350), isNot(equals(base)));
      });

      test('nullable distanceMetres equality and mutation', () {
        const withoutDistance = Pharmacy(
          id: 'pharma-001',
          nom: 'Pharmacie Bastos',
          licenceOnpc: 'ONPC-CMR-5678',
          quartier: 'Bastos',
          carrefourRepere: 'Carrefour Warda',
          latitude: 3.8812,
          longitude: 11.5173,
          telephoneGarde: '+237699112233',
          estOuverte: true,
          estDeGarde: true,
          estPartenaire: true,
        );

        expect(withoutDistance.distanceMetres, isNull);
        expect(withoutDistance, isNot(equals(base)));
        expect(withoutDistance.props.length, equals(12));
        expect(withoutDistance.props.last, isNull);

        // Mutating from null to value
        final withDistance = withoutDistance.copyWith(distanceMetres: 120);
        expect(withDistance.distanceMetres, equals(120));
        expect(withDistance, isNot(equals(withoutDistance)));
      });

      test('copyWith preserves all other 11 fields when 1 is modified', () {
        final modified = base.copyWith(nom: "Pharmacie de l'Aurore");
        expect(modified.nom, equals("Pharmacie de l'Aurore"));
        expect(modified.id, equals(base.id));
        expect(modified.licenceOnpc, equals(base.licenceOnpc));
        expect(modified.quartier, equals(base.quartier));
        expect(modified.carrefourRepere, equals(base.carrefourRepere));
        expect(modified.latitude, equals(base.latitude));
        expect(modified.longitude, equals(base.longitude));
        expect(modified.telephoneGarde, equals(base.telephoneGarde));
        expect(modified.estOuverte, equals(base.estOuverte));
        expect(modified.estDeGarde, equals(base.estDeGarde));
        expect(modified.estPartenaire, equals(base.estPartenaire));
        expect(modified.distanceMetres, equals(base.distanceMetres));
      });
    });
  });
}
