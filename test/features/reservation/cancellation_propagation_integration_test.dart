import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pending_counter_orders.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_counter_otp.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:medmate/features/reservation/domain/usecases/cancel_flash_request.dart';
import 'package:medmate/features/reservation/domain/usecases/escalate_dispatch_wave.dart';
import 'package:medmate/features/reservation/domain/usecases/select_pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/usecases/submit_flash_request.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';

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

  group(
      'Intégration Bout-en-Bout — Propagation Annulation Patient <-> Pharmacien',
      () {
    late Map<String, FlashOrder> sharedStore;
    late ReservationRepositoryImpl patientRepo;
    late PharmacistPortalRepositoryImpl pharmacistRepo;

    setUp(() {
      sharedStore = <String, FlashOrder>{};
      patientRepo = ReservationRepositoryImpl(sharedOrders: sharedStore);
      pharmacistRepo =
          PharmacistPortalRepositoryImpl(sharedOrders: sharedStore);
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

    test(
        'refus d’annulation si la commande a déjà été retirée au comptoir (delivered)',
        () async {
      // 1. Commande déjà livrée
      final deliveredOrder = FlashOrder(
        id: 'ORD-DELIVERED',
        items: const [
          BasketItem(id: 'b-2', medication: sampleMed, quantity: 1),
        ],
        quarter: 'Melen',
        targets: const [],
        status: FlashOrderStatus.delivered,
        isPickedUp: true,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      sharedStore[deliveredOrder.id] = deliveredOrder;

      // 2. Tentative d'annulation
      final cancelResult =
          await patientRepo.cancelFlashRequest(deliveredOrder.id);
      expect(cancelResult.isLeft(), isTrue);
      cancelResult.fold(
        (failure) => expect(
          failure.message,
          contains("Impossible d'annuler une commande déjà délivrée"),
        ),
        (_) => fail('L’annulation aurait dû être refusée'),
      );
    });

    test(
        'FlashReservationCubit.cancelReservation : succès réinitialise à initial et propage cancelled dans sharedStore',
        () async {
      final cubit = FlashReservationCubit(
        submitFlashRequestUseCase: SubmitFlashRequestUseCase(patientRepo),
        escalateDispatchWaveUseCase: EscalateDispatchWaveUseCase(patientRepo),
        selectPharmacyOfferUseCase: SelectPharmacyOfferUseCase(patientRepo),
        cancelFlashRequestUseCase: CancelFlashRequestUseCase(patientRepo),
        reservationRepository: patientRepo,
      )
        ..addItem(sampleMed, quantity: 1)
        ..selectLandmark(sampleLandmark);
      await cubit.submitFlashRequest();

      final activeOrder = cubit.state.currentOrder;
      expect(activeOrder, isNotNull);

      await cubit.cancelReservation();

      expect(cubit.state.status, equals(FlashReservationStatus.initial));
      expect(cubit.state.currentOrder, isNull);
      expect(cubit.state.confirmedReservation, isNull);
      expect(
        sharedStore[activeOrder!.id]?.status,
        equals(FlashOrderStatus.cancelled),
      );

      await cubit.close();
    });

    test(
        'FlashReservationCubit.cancelReservation : échec conserve la commande et émet errorMessage',
        () async {
      final cubit = FlashReservationCubit(
        submitFlashRequestUseCase: SubmitFlashRequestUseCase(patientRepo),
        escalateDispatchWaveUseCase: EscalateDispatchWaveUseCase(patientRepo),
        selectPharmacyOfferUseCase: SelectPharmacyOfferUseCase(patientRepo),
        cancelFlashRequestUseCase: CancelFlashRequestUseCase(patientRepo),
        reservationRepository: patientRepo,
      )
        ..addItem(sampleMed, quantity: 1)
        ..selectLandmark(sampleLandmark);
      await cubit.submitFlashRequest();

      final activeOrder = cubit.state.currentOrder!;
      // Simule la délivrance au comptoir entre-temps
      sharedStore[activeOrder.id] = activeOrder.copyWith(
        status: FlashOrderStatus.delivered,
        isPickedUp: true,
      );

      await cubit.cancelReservation();

      // La commande n'est pas effacée et le message d'erreur est présent
      expect(cubit.state.currentOrder, isNotNull);
      expect(
        cubit.state.errorMessage,
        contains("Impossible d'annuler une commande déjà délivrée"),
      );

      await cubit.close();
    });

    testWidgets(
        "commande urgente annulée par le patient -> l'alerte du portail pharmacien s'arrête d'elle-même",
        (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final ordersController = StreamController<void>.broadcast();
      addTearDown(ordersController.close);

      final customStore = <String, FlashOrder>{
        'ORD-URG-1': FlashOrder(
          id: 'ORD-URG-1',
          items: const [
            BasketItem(id: 'b-urg', medication: sampleMed, quantity: 1),
          ],
          quarter: 'Carrefour Warda',
          targets: const [
            DispatchedPharmacy(
              id: 'pharma-soleil',
              name: 'Pharmacie du Soleil',
              quarter: 'Warda',
              distanceKm: 0.4,
              phone: '+237 677 12 34 56',
              waveIndex: 1,
            ),
          ],
          status: FlashOrderStatus.dispatchingWave,
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(hours: 2)),
        ),
      };

      final reactivePatientRepo = ReservationRepositoryImpl(
        sharedOrders: customStore,
        onOrdersChanged: () {
          if (!ordersController.isClosed) {
            ordersController.add(null);
          }
        },
      );
      final reactivePharmaRepo = PharmacistPortalRepositoryImpl(
        sharedOrders: customStore,
      );

      final pharmaCubit = PharmacistCounterCubit(
        getPendingOrders: GetPendingCounterOrdersUseCase(reactivePharmaRepo),
        submitQuoteUseCase: SubmitCounterQuoteUseCase(reactivePharmaRepo),
        validateOtpUseCase: ValidateCounterOtpUseCase(reactivePharmaRepo),
        localOrdersStream: ordersController.stream,
      );
      addTearDown(pharmaCubit.close);

      var soundCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PharmacistCounterCubit>.value(
            value: pharmaCubit,
            child: PharmacistPortalView(
              initialPharmacyId: 'pharma-soleil',
              enableAlertCycle: true,
              onPlayAlertSound: () => soundCount++,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // L'alerte urgente est active au départ (t = 0s)
      expect(find.text('Nouvelle demande urgente'), findsOneWidget);
      expect(soundCount, equals(1));

      // Le patient annule sa commande : le flux réactif notifie immédiatement le portail
      await reactivePatientRepo.cancelFlashRequest('ORD-URG-1');
      await tester.pumpAndSettle();

      // Le bandeau disparaît et le timer sonore est arrêté sans intervention manuelle
      expect(find.text('Nouvelle demande urgente'), findsNothing);

      // Avance de 60s : aucune sonnerie supplémentaire
      await tester.pump(const Duration(seconds: 60));
      expect(soundCount, equals(1));
    });
  });
}
