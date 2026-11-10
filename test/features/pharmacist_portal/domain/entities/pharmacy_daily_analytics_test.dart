import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';

void main() {
  group('PharmacyDailyAnalytics Entity & Confidentialité Santé Zéro PII', () {
    final fixedDate = DateTime(2026, 11, 9);

    final analyticsA = PharmacyDailyAnalytics(
      id: 'stat-1',
      pharmacyId: 'pharma-bastos',
      date: fixedDate,
      totalDemandsReceived: 20,
      totalQuotesSubmitted: 18,
      totalReservationsConfirmed: 15,
      conversionRate: 0.833,
      tempsMoyenReponseSecondes: 145,
    );

    final analyticsB = PharmacyDailyAnalytics(
      id: 'stat-1',
      pharmacyId: 'pharma-bastos',
      date: fixedDate,
      totalDemandsReceived: 20,
      totalQuotesSubmitted: 18,
      totalReservationsConfirmed: 15,
      conversionRate: 0.833,
      tempsMoyenReponseSecondes: 145,
    );

    final analyticsOther = PharmacyDailyAnalytics(
      id: 'stat-2',
      pharmacyId: 'pharma-mokolo',
      date: fixedDate,
      totalDemandsReceived: 10,
      totalQuotesSubmitted: 8,
      totalReservationsConfirmed: 6,
      conversionRate: 0.75,
      tempsMoyenReponseSecondes: 210,
    );

    test('supports value equality via props', () {
      expect(analyticsA, equals(analyticsB));
      expect(analyticsA, isNot(equals(analyticsOther)));
      expect(analyticsA.props, [
        'stat-1',
        'pharma-bastos',
        fixedDate,
        20,
        18,
        15,
        0.833,
        145,
      ]);
    });

    test('helper alias getters return accurate metric values', () {
      expect(analyticsA.totalDemandesRecues, equals(20));
      expect(analyticsA.totalDevisEnvoyes, equals(18));
      expect(analyticsA.totalReservationsConfirmees, equals(15));
      expect(analyticsA.tauxConversion, equals(0.833));
    });

    test('INVARIANT: ZERO PII (Loi n° 2024/017) — No patient private data exposed', () {
      final stringified = analyticsA.toString().toLowerCase();

      // Vérifie l'absence absolue de données identifiantes de patients
      expect(stringified, isNot(contains('patient')));
      expect(stringified, isNot(contains('phone')));
      expect(stringified, isNot(contains('telephone')));
      expect(stringified, isNot(contains('email')));
      expect(stringified, isNot(contains('nom_patient')));
      expect(stringified, isNot(contains('ordonnance')));
      expect(stringified, isNot(contains('prescription')));

      // Seules des métriques agrégées de comptoir sont présentes
      expect(analyticsA.totalDemandsReceived, greaterThanOrEqualTo(0));
      expect(analyticsA.totalQuotesSubmitted, greaterThanOrEqualTo(0));
      expect(analyticsA.totalReservationsConfirmed, greaterThanOrEqualTo(0));
      expect(analyticsA.conversionRate, inInclusiveRange(0.0, 1.0));
    });

    test('copyWith updates specified fields correctly', () {
      final updated = analyticsA.copyWith(
        totalReservationsConfirmed: 16,
        conversionRate: 0.888,
      );

      expect(updated.id, equals('stat-1'));
      expect(updated.totalReservationsConfirmed, equals(16));
      expect(updated.conversionRate, equals(0.888));
      expect(updated.pharmacyId, equals('pharma-bastos'));
    });
  });
}
