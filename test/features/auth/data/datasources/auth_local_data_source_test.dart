import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';

void main() {
  late AuthLocalDataSourceImpl dataSource;

  setUp(() {
    dataSource = AuthLocalDataSourceImpl();
  });

  group('AuthLocalDataSourceImpl', () {
    test('getCurrentSession creates an anonymous patient session when first called', () async {
      final session = await dataSource.getCurrentSession();

      expect(session.isActive, isTrue);
      expect(session.patientSession, isNotNull);
      expect(session.patientSession!.isAnonymous, isTrue);
      expect(session.pharmacistProfile, isNull);
    });

    test('getCurrentSession returns existing active session on successive calls', () async {
      final session1 = await dataSource.getCurrentSession();
      final session2 = await dataSource.getCurrentSession();

      expect(session1.sessionId, equals(session2.sessionId));
      expect(session1.patientSession?.sessionId, equals(session2.patientSession?.sessionId));
    });

    test('signInPharmacist succeeds with valid seeded credentials', () async {
      final session = await dataSource.signInPharmacist(
        'pharmacist@afya.cm',
        'Afya2026!',
      );

      expect(session.isPharmacist, isTrue);
      expect(session.pharmacistProfile?.licenceOnpc, equals('ONPC-2024-CMR-042'));
      expect(session.pharmacistProfile?.fullName, equals('Dr. Charles Kamga'));
      expect(session.pharmacistProfile?.role, equals(PharmacistRole.titulaire));
      expect(session.pharmacistProfile?.isVerified, isTrue);
    });

    test('signInPharmacist handles whitespace and case insensitivity on email', () async {
      final session = await dataSource.signInPharmacist(
        '  PHARMACIST@AFYA.CM  ',
        'Afya2026!',
      );

      expect(session.isPharmacist, isTrue);
      expect(session.pharmacistProfile?.email, equals('pharmacist@afya.cm'));
    });

    test('signInPharmacist succeeds with seeded adjoint credentials', () async {
      final session = await dataSource.signInPharmacist(
        'adjoint.bastos@afya.cm',
        'Afya2026!',
      );

      expect(session.isPharmacist, isTrue);
      expect(session.pharmacistProfile?.licenceOnpc, equals('ONPC-2024-CMR-043'));
      expect(session.pharmacistProfile?.role, equals(PharmacistRole.adjoint));
      expect(session.pharmacistProfile?.fullName, equals('Dr. Madeleine Ngu'));
    });

    test('signInPharmacist throws AuthException with invalid password', () async {
      expect(
        () => dataSource.signInPharmacist('pharmacist@afya.cm', 'WrongPassword123!'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signInPharmacist throws AuthException with unknown email', () async {
      expect(
        () => dataSource.signInPharmacist('unknown@pharmacie.cm', 'Afya2026!'),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut clears current session and subsequent call creates fresh session', () async {
      final sessionBefore = await dataSource.signInPharmacist(
        'pharmacist@afya.cm',
        'Afya2026!',
      );
      expect(sessionBefore.isPharmacist, isTrue);

      await dataSource.signOut();

      final sessionAfter = await dataSource.getCurrentSession();
      expect(sessionAfter.isPharmacist, isFalse);
      expect(sessionAfter.patientSession?.isAnonymous, isTrue);
      expect(sessionAfter.sessionId, isNot(equals(sessionBefore.sessionId)));
    });

    test('getOrCreatePatientSession updates phone number for existing anonymous session', () async {
      await dataSource.getCurrentSession();

      final updatedPatient = await dataSource.getOrCreatePatientSession(
        phoneNumber: '+237699112233',
      );

      expect(updatedPatient.phoneNumber, equals('+237699112233'));
      expect(updatedPatient.isAnonymous, isFalse);

      final current = await dataSource.getCurrentSession();
      expect(current.patientSession?.phoneNumber, equals('+237699112233'));
    });

    test('getOrCreatePatientSession creates new patient session if none existed', () async {
      final patient = await dataSource.getOrCreatePatientSession(
        phoneNumber: '+237677998877',
      );

      expect(patient.phoneNumber, equals('+237677998877'));
      expect(patient.isAnonymous, isFalse);
    });
  });
}
