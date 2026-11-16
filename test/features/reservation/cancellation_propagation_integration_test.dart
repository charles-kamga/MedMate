import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';

void main() {
  const sampleMed = Medication(
    id: 'med-parac-500',
    dci: 'Paracétamol',
    nomCommercial: 'Efferalgan 500mg',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1200,
    necessiteOrdonnance: false,
  );

  final sampleLandmark = YaoundeLandmarks.list.firstWhere(
    (l) => l.id == 'carrefour-warda',
    orElse: () => YaoundeLandmarks.list.first,
  );

  group('Intégration Bout-en-Bout — Propagation Annulation Patient <-> Pharmacien', () {
    late Map<String, FlashOrder> sharedStore;
    late ReservationRepositoryImpl patientRepo;
    late PharmacistPortalRepositoryImpl pharmacistRepo;

    setUp(() {
      sharedStore = <String, FlashOrder>{};
      patientRepo = ReservationRepositoryImpl(sharedOrders: sharedStore);
      pharmacistRepo = PharmacistPortalRepositoryImpl(sharedOrders: sharedStore);
    });

    test(
        'commande créée -> visible pharmacien -> patient annule -> exclue inbox pharmacien -> validation OTP échoue',
        () async {
      // 1. Patient émet une demande flash
      final submitResult = await patientRepo.submitFlashRequest(
        items: const [
          BasketItem(id: 'b-1', medication: sampleMed, quantity: 2),
        ],
        landmark: sampleLandmark,
      );
      expect(submitResult.isRight(), isTrue);
      final createdOrder = submitResult.getOrElse((_) => throw Exception());
      final orderId = createdOrder.id;

      // 2. Pharmacie ciblée voit la commande dans ses commandes en attente
      final initialPending =
          await pharmacistRepo.getPendingOrdersForPharmacy('pharma-soleil');
      expect(initialPending.isRight(), isTrue);
      final listBeforeCancel = initialPending.getOrElse((_) => []);
      expect(listBeforeCancel.any((o) => o.id == orderId), isTrue);

      // 3. Pharmacien émet un devis
      final quoteResult = await pharmacistRepo.submitQuote(
        orderId: orderId,
        pharmacyId: 'pharma-soleil',
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
      );
      expect(quoteResult.isRight(), isTrue);
      final quoteOffer = quoteResult.getOrElse((_) => throw Exception());

      // 4. Patient retient l'offre et génère le ticket OTP
      final selectResult = await patientRepo.selectPharmacyOffer(
        orderId: orderId,
        offer: quoteOffer,
        patientPhone: '+237 690 12 34 56',
      );
      expect(selectResult.isRight(), isTrue);
      final reservation = selectResult.getOrElse((_) => throw Exception());
      final otpCode = reservation.codeRetraitOtp;

      // 5. Patient confirme l'annulation de sa commande avant passage au comptoir
      final cancelResult = await patientRepo.cancelFlashRequest(orderId);
      expect(cancelResult.isRight(), isTrue);
      final cancelledOrder = cancelResult.getOrElse((_) => throw Exception());
      expect(cancelledOrder.status, equals(FlashOrderStatus.cancelled));

      // 6. La commande est immédiatement exclue de la boîte du pharmacien
      final updatedPending =
          await pharmacistRepo.getPendingOrdersForPharmacy('pharma-soleil');
      expect(updatedPending.isRight(), isTrue);
      final listAfterCancel = updatedPending.getOrElse((_) => []);
      expect(listAfterCancel.any((o) => o.id == orderId), isFalse);

      // 7. Toute tentative de validation OTP au comptoir pour cette commande échoue
      final otpAttempt = await pharmacistRepo.validateOtpAtCounter(
        orderId: orderId,
        pharmacyId: 'pharma-soleil',
        otpCode: otpCode,
      );
      expect(otpAttempt.isLeft(), isTrue);
      otpAttempt.fold(
        (failure) => expect(
          failure.message,
          contains('annulée'),
        ),
        (_) => fail('Validation OTP aurait dû échouer'),
      );

      // 8. Toute nouvelle soumission de devis échoue également
      final quoteAttempt = await pharmacistRepo.submitQuote(
        orderId: orderId,
        pharmacyId: 'pharma-soleil',
        availability: PharmacyAvailabilityType.fullyAvailable,
        quotedPriceCfa: 2400,
      );
      expect(quoteAttempt.isLeft(), isTrue);
      quoteAttempt.fold(
        (failure) => expect(
          failure.message,
          contains('annulée'),
        ),
        (_) => fail('Soumission devis aurait dû échouer'),
      );
    });

    test('refus d’annulation si la commande a déjà été retirée au comptoir (delivered)',
        () async {
      // 1. Commande déjà livrée
      final deliveredOrder = FlashOrder(
        id: 'ORD-DELIVERED',
        items: const [BasketItem(id: 'b-2', medication: sampleMed, quantity: 1)],
        quarter: 'Melen',
        targets: const [],
        status: FlashOrderStatus.delivered,
        isPickedUp: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      sharedStore[deliveredOrder.id] = deliveredOrder;

      // 2. Tentative d'annulation
      final cancelResult = await patientRepo.cancelFlashRequest(deliveredOrder.id);
      expect(cancelResult.isLeft(), isTrue);
      cancelResult.fold(
        (failure) => expect(
          failure.message,
          contains("Impossible d'annuler une commande déjà délivrée"),
        ),
        (_) => fail('L’annulation aurait dû être refusée'),
      );
    });
  });
}
