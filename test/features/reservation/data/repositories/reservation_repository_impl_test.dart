import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';

void main() {
  late ReservationRepositoryImpl repository;

  const sampleLandmark = YaoundeLandmark(
    id: 'carrefour-warda',
    nom: 'Carrefour Warda',
    quartier: 'Poste Centrale',
    arrondissement: 'Yaoundé 1er',
    latitude: 3.8688,
    longitude: 11.5175,
    description: 'Face au Bois Sainte-Anastasie',
  );

  const sampleMedication = Medication(
    id: 'med-paracetamol',
    nomCommercial: 'Paracétamol 500 mg',
    dci: 'Paracétamol',
    forme: 'Comprimé',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1500,
    necessiteOrdonnance: false,
  );

  const sampleItems = [
    BasketItem(
      id: 'item-1',
      medication: sampleMedication,
      quantity: 2,
    ),
  ];

  setUp(() {
    repository = ReservationRepositoryImpl();
  });

  group('ReservationRepositoryImpl', () {
    test('submitFlashRequest génère la vague 1 avec 2 officines et devis pharmaciens', () async {
      final result = await repository.submitFlashRequest(
        items: sampleItems,
        landmark: sampleLandmark,
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Devrait réussir'),
        (order) {
          expect(order.currentWave, 1);
          expect(order.targets.length, 2);
          expect(order.offers.length, 2);
          expect(order.status, FlashOrderStatus.offersReceived);
          expect(order.quarter, contains('Carrefour Warda'));
          expect(order.isExpired, isFalse);
        },
      );
    });

    test('submitFlashRequest échoue si le panier est vide', () async {
      final result = await repository.submitFlashRequest(
        items: const [],
        landmark: sampleLandmark,
      );

      expect(result.isLeft(), isTrue);
    });

    test('escalateDispatchWave ajoute les pharmacies et offres de vague 2', () async {
      final initResult = await repository.submitFlashRequest(
        items: sampleItems,
        landmark: sampleLandmark,
      );
      final order = initResult.getOrElse((_) => throw Exception());

      final escalateResult = await repository.escalateDispatchWave(order.id);
      expect(escalateResult.isRight(), isTrue);

      escalateResult.fold(
        (_) => fail('Devrait réussir'),
        (escalated) {
          expect(escalated.currentWave, 2);
          expect(escalated.targets.length, 4);
          expect(escalated.offers.length, 3);
        },
      );
    });

    test('selectPharmacyOffer crée une réservation avec code OTP à 6 chiffres et TTL 2h', () async {
      final initResult = await repository.submitFlashRequest(
        items: sampleItems,
        landmark: sampleLandmark,
      );
      final order = initResult.getOrElse((_) => throw Exception());
      final offer = order.offers.first;

      final resResult = await repository.selectPharmacyOffer(
        orderId: order.id,
        offer: offer,
        patientPhone: '+237 699 00 11 22',
      );

      expect(resResult.isRight(), isTrue);
      resResult.fold(
        (_) => fail('Devrait réussir'),
        (reservation) {
          expect(reservation.statut, ReservationStatus.confirmed);
          expect(reservation.codeRetraitOtp.length, 6);
          expect(int.tryParse(reservation.codeRetraitOtp), isNotNull);
          expect(reservation.pharmacyId, offer.pharmacyId);
          expect(reservation.isExpired, isFalse);
        },
      );
    });
  });
}
