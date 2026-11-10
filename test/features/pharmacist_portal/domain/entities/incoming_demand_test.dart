import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/incoming_demand.dart';

void main() {
  group('IncomingDemand Entity', () {
    final fixedReceivedAt = DateTime(2026, 11, 9, 20, 0);

    const sampleMedication = Medication(
      id: 'med-para-500',
      codeNational: 'CIP-3400936184729',
      nomCommercial: 'Paracétamol Biogaran',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '500 mg',
      necessiteOrdonnance: false,
    );

    const sampleBasketItem = BasketItem(
      medication: sampleMedication,
      quantite: 1,
    );

    final sampleFlashRequest = FlashRequest(
      id: 'flash-1',
      clientRequestId: 'client-uuid-1',
      items: const [sampleBasketItem],
      quartierOuCarrefour: 'Mokolo',
      statut: FlashRequestStatus.active,
      vagueActuelle: 1,
      pharmaciesNotifieesIds: const ['pharma-1'],
      offresRecues: const [],
      createdAt: fixedReceivedAt,
      expiresAt: fixedReceivedAt.add(const Duration(minutes: 15)),
    );

    final demandA = IncomingDemand(
      id: 'inc-1',
      flashRequest: sampleFlashRequest,
      receivedAt: fixedReceivedAt,
      isResponded: false,
      distanceMetres: 650,
    );

    final demandB = IncomingDemand(
      id: 'inc-1',
      flashRequest: sampleFlashRequest,
      receivedAt: fixedReceivedAt,
      isResponded: false,
      distanceMetres: 650,
    );

    final demandOther = IncomingDemand(
      id: 'inc-2',
      flashRequest: sampleFlashRequest,
      receivedAt: fixedReceivedAt,
      isResponded: true,
      distanceMetres: 1200,
    );

    test('supports value equality via props', () {
      expect(demandA, equals(demandB));
      expect(demandA, isNot(equals(demandOther)));
      expect(demandA.props, [
        'inc-1',
        sampleFlashRequest,
        fixedReceivedAt,
        false,
        650,
      ]);
    });

    test('computed helper getters delegate correctly to flashRequest', () {
      expect(demandA.demandeId, equals('flash-1'));
      expect(demandA.items, equals(const [sampleBasketItem]));
      expect(demandA.quartierPatient, equals('Mokolo'));
      expect(demandA.isExpired, isTrue); // fixedReceivedAt is in the past
    });

    test('copyWith updates specified fields correctly', () {
      final updated = demandA.copyWith(isResponded: true);

      expect(updated.id, equals('inc-1'));
      expect(updated.isResponded, isTrue);
      expect(updated.distanceMetres, equals(650));
      expect(updated.flashRequest, equals(sampleFlashRequest));
    });
  });
}
