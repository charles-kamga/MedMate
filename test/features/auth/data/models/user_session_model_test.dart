import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/auth/data/models/patient_session_model.dart';
import 'package:medmate/features/auth/data/models/pharmacist_profile_model.dart';
import 'package:medmate/features/auth/data/models/user_session_model.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';

void main() {
  final testDate = DateTime(2026, 11, 9, 14, 0, 0);

  final testPatient = PatientSessionModel(
    sessionId: 'sess-pat-01',
    phoneNumber: '+237699112233',
    createdAt: testDate,
    lastActiveAt: testDate,
  );

  const testPharmacist = PharmacistProfileModel(
    userId: 'usr-pharma-042',
    pharmacyId: 'pharma-bastos-01',
    licenceOnpc: 'ONPC-2024-CMR-042',
    role: PharmacistRole.titulaire,
    fullName: 'Dr. Charles Kamga',
    email: 'pharmacist@afya.cm',
    telephone: '+237699001122',
    isVerified: true,
  );

  final patientUserSession = UserSessionModel(
    sessionId: 'user-sess-pat',
    createdAt: testDate,
    patientSession: testPatient,
    isActive: true,
  );

  final pharmacistUserSession = UserSessionModel(
    sessionId: 'user-sess-pharm',
    createdAt: testDate,
    pharmacistProfile: testPharmacist,
    isActive: true,
  );

  group('UserSessionModel', () {
    test('is a subclass of UserSession entity', () {
      expect(patientUserSession, isA<UserSession>());
      expect(pharmacistUserSession, isA<UserSession>());
    });

    test('correctly identifies role and auth status', () {
      expect(patientUserSession.isPatient, isTrue);
      expect(patientUserSession.isPharmacist, isFalse);
      expect(patientUserSession.isAuthenticated, isTrue);

      expect(pharmacistUserSession.isPharmacist, isTrue);
      expect(pharmacistUserSession.isPatient, isFalse);
      expect(pharmacistUserSession.isAuthenticated, isTrue);
    });

    test('fromJson and toJson round-trip for patient user session', () {
      final json = patientUserSession.toJson();
      final reconstructed = UserSessionModel.fromJson(json);

      expect(reconstructed.sessionId, equals(patientUserSession.sessionId));
      expect(reconstructed.patientSession, equals(testPatient));
      expect(reconstructed.pharmacistProfile, isNull);
      expect(reconstructed.isActive, isTrue);
    });

    test('fromJson and toJson round-trip for pharmacist user session', () {
      final json = pharmacistUserSession.toJson();
      final reconstructed = UserSessionModel.fromJson(json);

      expect(reconstructed.sessionId, equals(pharmacistUserSession.sessionId));
      expect(reconstructed.pharmacistProfile, equals(testPharmacist));
      expect(reconstructed.patientSession, isNull);
      expect(reconstructed.isActive, isTrue);
    });

    test('toDomain and fromDomain convert faithfully', () {
      final domain = pharmacistUserSession.toDomain();
      expect(domain, equals(pharmacistUserSession));

      final fromDomain = UserSessionModel.fromDomain(domain);
      expect(fromDomain, equals(pharmacistUserSession));
    });

    test('copyWith updates specified fields', () {
      final updated = pharmacistUserSession.copyWith(isActive: false);
      expect(updated.isActive, isFalse);
      expect(updated.sessionId, equals(pharmacistUserSession.sessionId));
    });
  });
}
