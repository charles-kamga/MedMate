import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_state.dart';

void main() {
  group('FlashOrderCubit - Afya Santé V2', () {
    late FlashOrderCubit cubit;

    setUp(() {
      cubit = FlashOrderCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('État initial conforme', () {
      expect(cubit.state.userRole, UserRole.patient);
      expect(cubit.state.basketItems.length, 2);
      expect(cubit.state.selectedQuarter, 'Carrefour Warda, Poste Centrale');
      expect(cubit.state.activeOrder, isNull);
      expect(cubit.state.hasActiveOrder, isFalse);
    });

    test('Gestion du panier multi-médicaments (ajout, quantité, ordonnance, suppression)', () {
      // 1. Ajouter un antibiotique nécessitant une ordonnance
      cubit.addBasketItem(FlashOrderCubit.sampleMedicationAmox, quantity: 1, hasPrescription: true);
      expect(cubit.state.basketItems.length, 3);
      expect(cubit.state.basketItems.last.hasPrescription, isTrue);

      // 2. Modifier la quantité
      final itemId = cubit.state.basketItems.first.id;
      cubit.updateBasketItemQuantity(itemId, 5);
      expect(cubit.state.basketItems.first.quantity, 5);

      // 3. Basculer le statut d'ordonnance
      cubit.togglePrescription(itemId);
      expect(cubit.state.basketItems.first.hasPrescription, isTrue);

      // 4. Supprimer un article
      cubit.removeBasketItem(itemId);
      expect(cubit.state.basketItems.length, 2);
    });

    test('Lancement sans pharmacie : génère la Vague 1 vers les 2 pharmacies les plus proches', () {
      cubit.launchFlashOrder();

      final order = cubit.state.activeOrder;
      expect(order, isNotNull);
      expect(order!.status, FlashOrderStatus.dispatchingWave);
      expect(order.currentWave, 1);
      expect(order.waveTimeRemainingSeconds, 120);
      // Vague 1 : Exactement 2 pharmacies partenaires (Section 4 du CDC)
      expect(order.targets.length, 2);
      expect(order.targets[0].id, 'pharma-soleil');
      expect(order.targets[1].id, 'pharma-centre');
      expect(order.targets.every((t) => t.status == PharmacistReplyType.waiting), isTrue);
      expect(order.offers, isEmpty);
      expect(order.selectedOffer, isNull);
    });

    test('Escalade en Vague 2 : étend la recherche aux 2 pharmacies suivantes', () {
      cubit
        ..launchFlashOrder()
        ..accelerateWave(); // Déclenchement de l'escalade

      final order = cubit.state.activeOrder!;
      expect(order.currentWave, 2);
      // Vague 1 (2 pharma) + Vague 2 (2 pharma) = 4 officines contactées
      expect(order.targets.length, 4);
      expect(order.targets[2].id, 'pharma-obili');
      expect(order.targets[3].id, 'pharma-acacia');
    });

    test('Soumission d’offres par les pharmaciens : Prix fixé par l’officine et non par l’app', () {
      cubit
        ..launchFlashOrder()
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-soleil',
          availability: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 3200,
          proposesDelivery: true,
          deliveryFeeCfa: 800,
        )
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-centre',
          availability: PharmacyAvailabilityType.conditional,
          quotedPriceCfa: 2900,
          conditionRequirements: const ['Ordonnance originale requise'],
        );

      final order = cubit.state.activeOrder!;
      expect(order.offers.length, 2);
      expect(order.status, FlashOrderStatus.offersReceived);

      // AUCUN gagnant automatique n'est désigné : c'est au patient de choisir
      expect(order.selectedOffer, isNull);

      // Vérification des devis fixés par chaque officine
      final offerA = order.offers.firstWhere((o) => o.pharmacyId == 'pharma-soleil');
      expect(offerA.quotedPriceCfa, 3200);
      expect(offerA.deliveryFeeCfa, 800);
      expect(offerA.grandTotalCfa, 4000);

      final offerB = order.offers.firstWhere((o) => o.pharmacyId == 'pharma-centre');
      expect(offerB.quotedPriceCfa, 2900);
      expect(offerB.conditionRequirements, contains('Ordonnance originale requise'));
    });

    test('Choix souverain du patient : sélection explicite parmi les offres reçues', () {
      cubit
        ..launchFlashOrder()
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-soleil',
          availability: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 3500,
        )
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-centre',
          availability: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 3000,
        );

      final offers = cubit.state.activeOrder!.offers;
      final cheaperOffer = offers.firstWhere((o) => o.quotedPriceCfa == 3000);

      // Le patient choisit l'offre la moins chère
      cubit.selectOffer(cheaperOffer.id);

      final order = cubit.state.activeOrder!;
      expect(order.status, FlashOrderStatus.accepted);
      expect(order.selectedOffer, isNotNull);
      expect(order.selectedOffer!.pharmacyId, 'pharma-centre');
      expect(order.totalAmountCfa, 3000);
    });

    test('Confirmation réservation : Génération du code OTP avec TTL 2h', () {
      cubit
        ..launchFlashOrder()
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-soleil',
          availability: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 2800,
        );

      final offerId = cubit.state.activeOrder!.offers.first.id;
      cubit
        ..selectOffer(offerId)
        ..confirmPayment(
          method: FlashPaymentMethod.cashCounter,
          phoneNumber: '699112233',
        );

      final order = cubit.state.activeOrder!;
      expect(order.status, FlashOrderStatus.readyForPickup);
      expect(order.paymentMethod, FlashPaymentMethod.cashCounter);
      expect(order.paymentStatus, FlashPaymentStatus.pending);
      expect(order.reservationOtpCode, startsWith('RET-'));
      expect(order.reservationOtpCode!.length, 10);
      expect(order.isExpired, isFalse);
    });

    test('Contrôle et validation du code OTP au comptoir par le pharmacien', () {
      cubit
        ..launchFlashOrder()
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-soleil',
          availability: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 2800,
        );

      final offerId = cubit.state.activeOrder!.offers.first.id;
      cubit
        ..selectOffer(offerId)
        ..confirmPayment(method: FlashPaymentMethod.cashCounter);

      final otpCode = cubit.state.activeOrder!.reservationOtpCode!;

      // 1. Test avec un code OTP erroné
      cubit.validateOtpAtCounter(enteredOtp: 'RET-000000', pharmacyId: 'pharma-soleil');
      expect(cubit.state.otpValidationSuccess, isFalse);
      expect(cubit.state.otpValidationError, isNotNull);

      // 2. Test avec le code OTP exact
      cubit.validateOtpAtCounter(enteredOtp: otpCode, pharmacyId: 'pharma-soleil');
      expect(cubit.state.otpValidationSuccess, isTrue);
      expect(cubit.state.activeOrder!.status, FlashOrderStatus.delivered);
      expect(cubit.state.activeOrder!.isPickedUp, isTrue);
    });

    test('resetOrder réinitialise le cycle de commande', () {
      cubit
        ..launchFlashOrder()
        ..resetOrder();

      expect(cubit.state.activeOrder, isNull);
      expect(cubit.state.userRole, UserRole.patient);
    });
  });
}
