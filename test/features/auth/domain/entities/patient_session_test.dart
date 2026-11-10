import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';

void main() {
  final now = DateTime(2026, 11, 9, 12);
  final later = now.add(const Duration(minutes: 15));

  group('PatientSession Entity', () {
    test('supports value equality via props', () {
      final sessionA = PatientSession(
        sessionId: 'session-123',
        createdAt: now,
        lastActiveAt: now,
        phoneNumber: '+237699001122',
      );
      final sessionB = PatientSession(
        sessionId: 'session-123',
        createdAt: now,
        lastActiveAt: now,
        phoneNumber: '+237699001122',
      );
      final sessionDifferent = PatientSession(
        sessionId: 'session-999',
        createdAt: now,
        lastActiveAt: now,
      );

      expect(sessionA, equals(sessionB));
      expect(sessionA, isNot(equals(sessionDifferent)));
      expect(sessionA.props, [
        'session-123',
        '+237699001122',
        now,
        now,
      ]);
    });

    test('isAnonymous returns true when phoneNumber is null or empty', () {
      final anonymousSessionNull = PatientSession(
        sessionId: 'session-anon-1',
        createdAt: now,
        lastActiveAt: now,
      );
      final anonymousSessionEmpty = PatientSession(
        sessionId: 'session-anon-2',
        createdAt: now,
        lastActiveAt: now,
        phoneNumber: '',
      );
      final identifiedSession = PatientSession(
        sessionId: 'session-identified',
        createdAt: now,
        lastActiveAt: now,
        phoneNumber: '+237677112233',
      );

      expect(anonymousSessionNull.isAnonymous, isTrue);
      expect(anonymousSessionEmpty.isAnonymous, isTrue);
      expect(identifiedSession.isAnonymous, isFalse);
    });

    test('copyWith updates specified fields and preserves unmodified ones', () {
      final session = PatientSession(
        sessionId: 'session-orig',
        createdAt: now,
        lastActiveAt: now,
      );

      final updated = session.copyWith(
        phoneNumber: '+237699112233',
        lastActiveAt: later,
      );

      expect(updated.sessionId, equals('session-orig'));
      expect(updated.createdAt, equals(now));
      expect(updated.phoneNumber, equals('+237699112233'));
      expect(updated.lastActiveAt, equals(later));
      expect(updated.isAnonymous, isFalse);
    });
  });
}
