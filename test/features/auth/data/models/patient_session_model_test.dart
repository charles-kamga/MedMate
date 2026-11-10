import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/auth/data/models/patient_session_model.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';

void main() {
  final testDate = DateTime(2026, 11, 9, 12, 0, 0);

  final testModel = PatientSessionModel(
    sessionId: 'session-patient-123',
    phoneNumber: '+237699112233',
    createdAt: testDate,
    lastActiveAt: testDate,
  );

  group('PatientSessionModel', () {
    test('is a subclass of PatientSession entity', () {
      expect(testModel, isA<PatientSession>());
    });

    test('fromJson deserializes valid JSON correctly', () {
      final json = <String, dynamic>{
        'session_id': 'session-patient-123',
        'phone_number': '+237699112233',
        'created_at': testDate.toIso8601String(),
        'last_active_at': testDate.toIso8601String(),
      };

      final result = PatientSessionModel.fromJson(json);

      expect(result, equals(testModel));
      expect(result.sessionId, equals('session-patient-123'));
      expect(result.phoneNumber, equals('+237699112233'));
      expect(result.createdAt, equals(testDate));
      expect(result.lastActiveAt, equals(testDate));
      expect(result.isAnonymous, isFalse);
    });

    test('fromJson handles anonymous session with null phoneNumber', () {
      final json = <String, dynamic>{
        'session_id': 'session-anon-456',
        'phone_number': null,
        'created_at': testDate.toIso8601String(),
        'last_active_at': testDate.toIso8601String(),
      };

      final result = PatientSessionModel.fromJson(json);

      expect(result.sessionId, equals('session-anon-456'));
      expect(result.phoneNumber, isNull);
      expect(result.isAnonymous, isTrue);
    });

    test('toJson serializes model correctly', () {
      final result = testModel.toJson();

      expect(result['session_id'], equals('session-patient-123'));
      expect(result['phone_number'], equals('+237699112233'));
      expect(result['created_at'], equals(testDate.toIso8601String()));
      expect(result['last_active_at'], equals(testDate.toIso8601String()));
    });

    test('toDomain and fromDomain convert faithfully', () {
      final domain = testModel.toDomain();
      expect(domain, equals(testModel));

      final fromDomain = PatientSessionModel.fromDomain(domain);
      expect(fromDomain, equals(testModel));
    });

    test('copyWith produces updated instance with modified fields', () {
      final updated = testModel.copyWith(
        phoneNumber: '+237677445566',
      );

      expect(updated.phoneNumber, equals('+237677445566'));
      expect(updated.sessionId, equals(testModel.sessionId));
    });
  });
}
