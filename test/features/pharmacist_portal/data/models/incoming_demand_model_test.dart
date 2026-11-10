import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacist_portal/data/models/incoming_demand_model.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/incoming_demand.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';

void main() {
  final tCreatedAt = DateTime(2026, 11, 9, 14, 0);
  final tReceivedAt = DateTime(2026, 11, 9, 14, 1);
  final tExpiresAt = DateTime(2026, 11, 9, 14, 30);

  const tMedication = Medication(
    id: 'med-para-500',
    codeNational: 'CIP-3400936184729',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  final tFlashRequest = FlashRequestModel(
    id: 'req-123',
    clientRequestId: 'client-uuid-456',
    items: const [
      BasketItemModel(medication: tMedication, quantite: 2),
    ],
    quartierOuCarrefour: 'Bastos - Carrefour Warda',
    statut: FlashRequestStatus.active,
    vagueActuelle: 1,
    pharmaciesNotifieesIds: const ['pharma-bastos-01'],
    offresRecues: const [],
    createdAt: tCreatedAt,
    expiresAt: tExpiresAt,
  );

  final tModel = IncomingDemandModel(
    id: 'demand-notif-1',
    flashRequest: tFlashRequest,
    receivedAt: tReceivedAt,
    isResponded: false,
    distanceMetres: 450,
  );

  final tJson = <String, dynamic>{
    'id': 'demand-notif-1',
    'flash_request': tFlashRequest.toJson(),
    'received_at': tReceivedAt.toIso8601String(),
    'is_responded': false,
    'distance_metres': 450.0,
  };

  group('IncomingDemandModel', () {
    test('is a subtype of IncomingDemand entity', () {
      expect(tModel, isA<IncomingDemand>());
    });

    test('fromJson deserializes JSON map correctly', () {
      final result = IncomingDemandModel.fromJson(tJson);
      expect(result.id, equals('demand-notif-1'));
      expect(result.isResponded, isFalse);
      expect(result.distanceMetres, equals(450));
      expect(result.demandeId, equals('req-123'));
      expect(result.quartierPatient, equals('Bastos - Carrefour Warda'));
    });

    test('toJson serializes model to JSON map correctly', () {
      final result = tModel.toJson();
      expect(result['id'], equals('demand-notif-1'));
      expect(result['is_responded'], isFalse);
      expect(result['distance_metres'], equals(450));
    });

    test('fromDomain converts IncomingDemand entity to IncomingDemandModel', () {
      final domain = IncomingDemand(
        id: 'demand-dom',
        flashRequest: tFlashRequest,
        receivedAt: tReceivedAt,
        isResponded: true,
        distanceMetres: 600,
      );
      final model = IncomingDemandModel.fromDomain(domain);
      expect(model.id, equals('demand-dom'));
      expect(model.isResponded, isTrue);
      expect(model.toDomain(), equals(model));
    });
  });
}
