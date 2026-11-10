import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';

void main() {
  final tCreatedAt = DateTime(2026, 11, 9, 14, 0);
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

  const tBasketItem = BasketItemModel(
    medication: tMedication,
    quantite: 2,
  );

  final tModel = FlashRequestModel(
    id: 'req-123',
    clientRequestId: 'client-uuid-456',
    items: const [tBasketItem],
    quartierOuCarrefour: 'Bastos - Carrefour Warda',
    statut: FlashRequestStatus.active,
    vagueActuelle: 1,
    pharmaciesNotifieesIds: const ['pharma-bastos-01', 'pharma-nlongkak-01'],
    offresRecues: const [],
    createdAt: tCreatedAt,
    expiresAt: tExpiresAt,
  );

  final tJson = <String, dynamic>{
    'id': 'req-123',
    'client_request_id': 'client-uuid-456',
    'items': [
      {
        'medication': {
          'id': 'med-para-500',
          'code_national': 'CIP-3400936184729',
          'nom_commercial': 'Paracétamol Biogaran',
          'dci': 'Paracétamol',
          'forme': 'Comprimé effervescent',
          'dosage': '500 mg',
          'necessite_ordonnance': false,
        },
        'quantite': 2,
        'precision': null,
      }
    ],
    'quartier_ou_carrefour': 'Bastos - Carrefour Warda',
    'statut': 'active',
    'vague_actuelle': 1,
    'pharmacies_notifiees_ids': ['pharma-bastos-01', 'pharma-nlongkak-01'],
    'offres_recues': <dynamic>[],
    'created_at': tCreatedAt.toIso8601String(),
    'expires_at': tExpiresAt.toIso8601String(),
  };

  group('FlashRequestModel', () {
    test('is a subtype of FlashRequest entity', () {
      expect(tModel, isA<FlashRequest>());
    });

    test('fromJson deserializes JSON map correctly', () {
      final result = FlashRequestModel.fromJson(tJson);
      expect(result.id, equals('req-123'));
      expect(result.clientRequestId, equals('client-uuid-456'));
      expect(result.statut, equals(FlashRequestStatus.active));
      expect(result.vagueActuelle, equals(1));
      expect(
        result.pharmaciesNotifieesIds,
        equals(['pharma-bastos-01', 'pharma-nlongkak-01']),
      );
      expect(result.items.length, equals(1));
    });

    test('toJson serializes model to JSON map correctly', () {
      final result = tModel.toJson();
      expect(result['id'], equals('req-123'));
      expect(result['client_request_id'], equals('client-uuid-456'));
      expect(result['statut'], equals('active'));
      expect(result['vague_actuelle'], equals(1));
    });

    test('fromDomain converts FlashRequest entity to FlashRequestModel', () {
      final domain = FlashRequest(
        id: 'req-dom',
        clientRequestId: 'client-dom',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Mokolo',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const ['pharma-mokolo-01'],
        offresRecues: const [],
        createdAt: tCreatedAt,
        expiresAt: tExpiresAt,
      );
      final model = FlashRequestModel.fromDomain(domain);
      expect(model.id, equals('req-dom'));
      expect(model.quartierOuCarrefour, equals('Mokolo'));
      expect(model.toDomain(), equals(model));
    });
  });
}
