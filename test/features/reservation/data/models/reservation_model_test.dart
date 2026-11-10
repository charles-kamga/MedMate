import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

void main() {
  final tCreatedAt = DateTime(2026, 11, 9, 14, 0);
  final tExpiresAt = DateTime(2026, 11, 9, 16, 0);

  final tModel = ReservationModel(
    id: 'res-123',
    clientReservationId: 'client-res-456',
    demandeId: 'req-789',
    offreId: 'offer-101',
    pharmacyId: 'pharma-bastos-01',
    codeRetraitOtp6Chiffres: '482910',
    statut: ReservationStatus.pending,
    createdAt: tCreatedAt,
    expiresAt: tExpiresAt,
  );

  final tJson = <String, dynamic>{
    'id': 'res-123',
    'client_reservation_id': 'client-res-456',
    'demande_id': 'req-789',
    'offre_id': 'offer-101',
    'pharmacy_id': 'pharma-bastos-01',
    'code_retrait_otp_6_chiffres': '482910',
    'statut': 'pending',
    'created_at': tCreatedAt.toIso8601String(),
    'expires_at': tExpiresAt.toIso8601String(),
  };

  group('ReservationModel', () {
    test('is a subtype of Reservation entity', () {
      expect(tModel, isA<Reservation>());
    });

    test('fromJson deserializes JSON map correctly', () {
      final result = ReservationModel.fromJson(tJson);
      expect(result.id, equals('res-123'));
      expect(result.clientReservationId, equals('client-res-456'));
      expect(result.demandeId, equals('req-789'));
      expect(result.offreId, equals('offer-101'));
      expect(result.pharmacyId, equals('pharma-bastos-01'));
      expect(result.codeRetraitOtp6Chiffres, equals('482910'));
      expect(result.statut, equals(ReservationStatus.pending));
    });

    test('toJson serializes model to JSON map correctly', () {
      final result = tModel.toJson();
      expect(result['id'], equals('res-123'));
      expect(result['code_retrait_otp_6_chiffres'], equals('482910'));
      expect(result['statut'], equals('pending'));
    });

    test('fromDomain converts Reservation entity to ReservationModel', () {
      final domain = Reservation(
        id: 'res-dom',
        clientReservationId: 'client-dom',
        demandeId: 'dem-dom',
        offreId: 'off-dom',
        pharmacyId: 'pharma-nlongkak-01',
        codeRetraitOtp6Chiffres: '123456',
        statut: ReservationStatus.confirmedAtCounter,
        createdAt: tCreatedAt,
        expiresAt: tExpiresAt,
      );
      final model = ReservationModel.fromDomain(domain);
      expect(model.id, equals('res-dom'));
      expect(model.statut, equals(ReservationStatus.confirmedAtCounter));
      expect(model.toDomain(), equals(model));
    });
  });
}
