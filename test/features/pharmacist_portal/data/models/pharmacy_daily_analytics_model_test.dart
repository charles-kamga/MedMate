import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacist_portal/data/models/pharmacy_daily_analytics_model.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';

void main() {
  final tDate = DateTime(2026, 11, 9);

  final tModel = PharmacyDailyAnalyticsModel(
    id: 'analytics-123',
    pharmacyId: 'pharma-bastos-01',
    date: tDate,
    totalDemandsReceived: 10,
    totalQuotesSubmitted: 8,
    totalReservationsConfirmed: 6,
    conversionRate: 0.75,
    tempsMoyenReponseSecondes: 120,
  );

  final tJson = <String, dynamic>{
    'id': 'analytics-123',
    'pharmacy_id': 'pharma-bastos-01',
    'date': tDate.toIso8601String(),
    'total_demands_received': 10,
    'total_quotes_submitted': 8,
    'total_reservations_confirmed': 6,
    'conversion_rate': 0.75,
    'temps_moyen_reponse_secondes': 120,
  };

  group('PharmacyDailyAnalyticsModel', () {
    test('is a subtype of PharmacyDailyAnalytics entity', () {
      expect(tModel, isA<PharmacyDailyAnalytics>());
    });

    test('fromJson deserializes JSON map correctly', () {
      final result = PharmacyDailyAnalyticsModel.fromJson(tJson);
      expect(result.id, equals('analytics-123'));
      expect(result.pharmacyId, equals('pharma-bastos-01'));
      expect(result.totalDemandsReceived, equals(10));
      expect(result.totalQuotesSubmitted, equals(8));
      expect(result.totalReservationsConfirmed, equals(6));
      expect(result.conversionRate, equals(0.75));
      expect(result.tempsMoyenReponseSecondes, equals(120));
    });

    test('toJson serializes model to JSON map correctly', () {
      final result = tModel.toJson();
      expect(result['id'], equals('analytics-123'));
      expect(result['total_demands_received'], equals(10));
      expect(result['conversion_rate'], equals(0.75));
    });

    test('Zero-PII invariant: Model does not contain any patient identifiable data', () {
      final jsonResult = tModel.toJson();
      expect(jsonResult.containsKey('patient_id'), isFalse);
      expect(jsonResult.containsKey('patient_phone'), isFalse);
      expect(jsonResult.containsKey('patient_name'), isFalse);
      expect(jsonResult.containsKey('prescription_url'), isFalse);
    });

    test('fromDomain converts PharmacyDailyAnalytics to PharmacyDailyAnalyticsModel', () {
      final domain = PharmacyDailyAnalytics(
        id: 'analytics-dom',
        pharmacyId: 'pharma-dom',
        date: tDate,
        totalDemandsReceived: 5,
        totalQuotesSubmitted: 4,
        totalReservationsConfirmed: 2,
        conversionRate: 0.5,
      );
      final model = PharmacyDailyAnalyticsModel.fromDomain(domain);
      expect(model.id, equals('analytics-dom'));
      expect(model.totalQuotesSubmitted, equals(4));
      expect(model.toDomain(), equals(model));
    });
  });
}
