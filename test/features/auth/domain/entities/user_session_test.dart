import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);

  final anonymousPatient = PatientSession(
    sessionId: 'sess-patient-anon',
    createdAt: now,
    lastActiveAt: now,
  );

  final identifiedPatient = PatientSession(
    sessionId: 'sess-patient-id',
    createdAt: now,
    lastActiveAt: now,
    phoneNumber: '+237699112233',
  );

  const pharmacistProfile = PharmacistProfile(
    userId: 'user-pharma-1',
    pharmacyId: 'pharma-bastos-1',
    licenceOnpc: 'ONPC-CMR-8472',
    role: PharmacistRole.titulaire,
    fullName: 'Dr. Amadou Bello',
    email: 'amadou.bello@afyasante.cm',
    telephone: '+237699001122',
    isVerified: true,
  );

  group('UserSession Entity', () {
    test('supports value equality via props', () {
      final sessionA = UserSession(
        sessionId: 'user-sess-1',
        createdAt: now,
        patientSession: anonymousPatient,
      );
      final sessionB = UserSession(
        sessionId: 'user-sess-1',
        createdAt: now,
        patientSession: anonymousPatient,
      );

      expect(sessionA, equals(sessionB));
      expect(sessionA.props, [
        'user-sess-1',
        anonymousPatient,
        null,
        now,
        true,
      ]);
    });

    test('computed properties for anonymous patient session', () {
      final session = UserSession(
        sessionId: 'user-sess-anon',
        createdAt: now,
        patientSession: anonymousPatient,
      );

      expect(session.isPatient, isTrue);
      expect(session.isPharmacist, isFalse);
      expect(session.isAuthenticated, isFalse);
    });

    test('computed properties for identified patient session', () {
      final session = UserSession(
        sessionId: 'user-sess-ident',
        createdAt: now,
        patientSession: identifiedPatient,
      );

      expect(session.isPatient, isTrue);
      expect(session.isPharmacist, isFalse);
      expect(session.isAuthenticated, isTrue);
    });

    test('computed properties for authenticated pharmacist session', () {
      final session = UserSession(
        sessionId: 'user-sess-pharma',
        createdAt: now,
        pharmacistProfile: pharmacistProfile,
      );

      expect(session.isPatient, isFalse);
      expect(session.isPharmacist, isTrue);
      expect(session.isAuthenticated, isTrue);
    });

    test('copyWith updates specified fields correctly', () {
      final session = UserSession(
        sessionId: 'user-sess-init',
        createdAt: now,
        patientSession: anonymousPatient,
      );

      final updated = session.copyWith(
        pharmacistProfile: pharmacistProfile,
        isActive: false,
      );

      expect(updated.sessionId, equals('user-sess-init'));
      expect(updated.patientSession, equals(anonymousPatient));
      expect(updated.pharmacistProfile, equals(pharmacistProfile));
      expect(updated.isActive, isFalse);
      expect(updated.isPharmacist, isTrue);
    });
  });
}
