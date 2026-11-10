import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

void main() {
  group('Reservation Entity & Invariants (OTP 6 Chiffres & TTL 2h)', () {
    final fixedCreatedAt = DateTime(2026, 11, 9, 20, 0, 0);
    final fixedExpiresAt = fixedCreatedAt.add(const Duration(hours: 2));

    final reservationA = Reservation(
      id: 'res-1',
      clientReservationId: 'client-res-uuid-1',
      demandeId: 'demand-1',
      offreId: 'offer-1',
      pharmacyId: 'pharma-1',
      codeRetraitOtp6Chiffres: '482910',
      statut: ReservationStatus.pending,
      createdAt: fixedCreatedAt,
      expiresAt: fixedExpiresAt,
    );

    final reservationB = Reservation(
      id: 'res-1',
      clientReservationId: 'client-res-uuid-1',
      demandeId: 'demand-1',
      offreId: 'offer-1',
      pharmacyId: 'pharma-1',
      codeRetraitOtp6Chiffres: '482910',
      statut: ReservationStatus.pending,
      createdAt: fixedCreatedAt,
      expiresAt: fixedExpiresAt,
    );

    final reservationOther = Reservation(
      id: 'res-2',
      clientReservationId: 'client-res-uuid-2',
      demandeId: 'demand-2',
      offreId: 'offer-2',
      pharmacyId: 'pharma-2',
      codeRetraitOtp6Chiffres: '998811',
      statut: ReservationStatus.confirmedAtCounter,
      createdAt: fixedCreatedAt,
      expiresAt: fixedExpiresAt,
    );

    test('supports value equality via props', () {
      expect(reservationA, equals(reservationB));
      expect(reservationA, isNot(equals(reservationOther)));
      expect(reservationA.props, [
        'res-1',
        'client-res-uuid-1',
        'demand-1',
        'offer-1',
        'pharma-1',
        '482910',
        ReservationStatus.pending,
        fixedCreatedAt,
        fixedExpiresAt,
      ]);
    });

    test('INVARIANT: Expiration TTL is strictly 2 hours (Duration(hours: 2))', () {
      final diff = reservationA.expiresAt.difference(reservationA.createdAt);
      expect(diff, equals(const Duration(hours: 2)));
    });

    test('INVARIANT: Code OTP is strictly 6 numeric digits', () {
      final otpRegex = RegExp(r'^\d{6}$');
      expect(otpRegex.hasMatch(reservationA.codeRetraitOtp6Chiffres), isTrue);
      expect(otpRegex.hasMatch('12345'), isFalse);
      expect(otpRegex.hasMatch('1234567'), isFalse);
      expect(otpRegex.hasMatch('12345A'), isFalse);
    });

    test('computed property isExpired and remainingTime work accurately', () {
      final pastReservation = reservationA.copyWith(
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(pastReservation.isExpired, isTrue);

      final activeReservation = reservationA.copyWith(
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );
      expect(activeReservation.isExpired, isFalse);
      expect(activeReservation.remainingTime.inMinutes, greaterThan(100));
    });

    test('copyWith updates specified fields correctly', () {
      final updated = reservationA.copyWith(
        statut: ReservationStatus.confirmedAtCounter,
      );

      expect(updated.id, equals('res-1'));
      expect(updated.statut, equals(ReservationStatus.confirmedAtCounter));
      expect(updated.codeRetraitOtp6Chiffres, equals('482910'));
    });
  });
}
