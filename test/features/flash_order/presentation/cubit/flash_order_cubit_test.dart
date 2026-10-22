import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_state.dart';

void main() {
  group('FlashOrderCubit', () {
    late FlashOrderCubit cubit;

    setUp(() {
      cubit = FlashOrderCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('État initial conforme', () {
      expect(cubit.state.userRole, UserRole.patient);
      expect(cubit.state.quantity, 1);
      expect(cubit.state.activeOrder, isNull);
      expect(cubit.state.selectedMedication?.nomCommercial, 'Coartem 20/120');
      expect(cubit.state.selectedQuarter, 'Carrefour Warda, Poste Centrale');
    });

    test('Lancement de la commande flash génère un dispatch vers 3 pharmacies cibles', () {
      cubit.launchFlashOrder();

      final order = cubit.state.activeOrder;
      expect(order, isNotNull);
      expect(order!.status, FlashOrderStatus.dispatching);
      expect(order.targets.length, 3);
      expect(order.targets.every((t) => t.status == PharmacistReplyType.waiting), isTrue);
      expect(order.winnerPharmacy, isNull);
    });

    test('Règle "Premier répondant gagne" : La pharmacie qui répond "Disponible" remporte la commande', () {
      // Pharmacie du Soleil répond "Disponible"
      cubit
        ..launchFlashOrder()
        ..submitPharmacistResponse(
          pharmacyId: 'pharma-soleil',
          reply: PharmacistReplyType.available,
        );

      final order = cubit.state.activeOrder!;
      expect(order.status, FlashOrderStatus.replied);
      expect(order.winnerPharmacy, isNotNull);
      expect(order.winnerPharmacy!.id, 'pharma-soleil');
      expect(order.winnerReplyType, PharmacistReplyType.available);

      // Une 2ème pharmacie tente de répondre : doit être ignorée (verrouillage strict)
      cubit.submitPharmacistResponse(
        pharmacyId: 'pharma-centre',
        reply: PharmacistReplyType.available,
      );

      expect(cubit.state.activeOrder!.winnerPharmacy!.id, 'pharma-soleil');
    });

    test('Réponse "Disponible sous conditions" : Enregistre la condition et attribue la commande', () {
      const condition = "Nécessite présentation de l'ordonnance originale papier";
      cubit
        ..launchFlashOrder()
        ..submitPharmacistResponse(
          pharmacyId: 'pharma-centre',
          reply: PharmacistReplyType.conditional,
          conditionNote: condition,
        );

      final order = cubit.state.activeOrder!;
      expect(order.winnerPharmacy!.id, 'pharma-centre');
      expect(order.winnerReplyType, PharmacistReplyType.conditional);
      expect(order.conditionNote, condition);
    });

    test('Réponse "Indisponible" : Maintient le dispatch en attente pour les autres pharmacies', () {
      // 1ère pharmacie répond Indisponible
      cubit
        ..launchFlashOrder()
        ..submitPharmacistResponse(
          pharmacyId: 'pharma-soleil',
          reply: PharmacistReplyType.unavailable,
        );

      var order = cubit.state.activeOrder!;
      expect(order.status, FlashOrderStatus.dispatching);
      expect(order.winnerPharmacy, isNull);

      // 2ème pharmacie répond Disponible -> Elle gagne !
      cubit.submitPharmacistResponse(
        pharmacyId: 'pharma-obili',
        reply: PharmacistReplyType.available,
      );

      order = cubit.state.activeOrder!;
      expect(order.winnerPharmacy!.id, 'pharma-obili');
      expect(order.status, FlashOrderStatus.replied);
    });

    test('Paiement comptoir génère un code OTP et TTL 2h', () {
      cubit
        ..launchFlashOrder()
        ..submitPharmacistResponse(
          pharmacyId: 'pharma-soleil',
          reply: PharmacistReplyType.available,
        )
        ..confirmPayment(method: FlashPaymentMethod.cashCounter);

      final order = cubit.state.activeOrder!;
      expect(order.status, FlashOrderStatus.confirmed);
      expect(order.paymentMethod, FlashPaymentMethod.cashCounter);
      expect(order.reservationOtpCode, startsWith('RET-'));
      expect(order.reservationOtpCode!.length, 10); // RET-XXXXXX
    });

    test('Paiement Mobile Money enregistre le numéro et valide la confirmation', () {
      cubit
        ..launchFlashOrder()
        ..submitPharmacistResponse(
          pharmacyId: 'pharma-soleil',
          reply: PharmacistReplyType.available,
        )
        ..confirmPayment(
          method: FlashPaymentMethod.orangeMoney,
          phoneNumber: '699112233',
        );

      final order = cubit.state.activeOrder!;
      expect(order.status, FlashOrderStatus.confirmed);
      expect(order.paymentMethod, FlashPaymentMethod.orangeMoney);
      expect(order.phoneNumber, '699112233');
    });

    test('resetOrder réinitialise le cycle de démonstration', () {
      cubit
        ..launchFlashOrder()
        ..submitPharmacistResponse(
          pharmacyId: 'pharma-soleil',
          reply: PharmacistReplyType.available,
        )
        ..resetOrder();

      expect(cubit.state.activeOrder, isNull);
      expect(cubit.state.userRole, UserRole.patient);
    });
  });
}
