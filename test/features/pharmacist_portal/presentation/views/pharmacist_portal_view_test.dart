import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_state.dart';
import 'package:medmate/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/counter_otp_validation_keypad.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/pharmacist_quote_reply_sheet.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/pharmacist_request_inbox_card.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistCounterCubit extends MockCubit<PharmacistCounterState>
    implements PharmacistCounterCubit {}

void main() {
  late MockPharmacistCounterCubit mockCubit;

  const sampleMed = Medication(
    id: 'med-efferalgan-500',
    dci: 'Paracétamol',
    nomCommercial: 'Efferalgan 500mg',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1200,
    necessiteOrdonnance: false,
  );

  final sampleOrderWaiting = FlashOrder(
    id: 'ORD-101',
    items: const [
      BasketItem(id: 'item-1', medication: sampleMed, quantity: 2),
    ],
    quarter: 'Carrefour Warda, Yaoundé',
    targets: const [],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    status: FlashOrderStatus.dispatchingWave,
  );

  final sampleOrderReady = FlashOrder(
    id: 'ORD-102',
    items: const [
      BasketItem(id: 'item-2', medication: sampleMed, quantity: 1),
    ],
    quarter: 'Poste Centrale, Yaoundé',
    targets: const [],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
    status: FlashOrderStatus.readyForPickup,
    reservationOtpCode: '842915',
  );

  setUp(() {
    mockCubit = MockPharmacistCounterCubit();
    when(() => mockCubit.state).thenReturn(
      PharmacistCounterState(
        status: PharmacistCounterStatus.loaded,
        orders: [sampleOrderWaiting, sampleOrderReady],
      ),
    );
  });

  Widget buildTestWidget({PharmacistCounterCubit? cubit}) {
    const view = PharmacistPortalView(initialPharmacyId: 'pharma-soleil');
    if (cubit != null) {
      return MaterialApp(
        home: BlocProvider<PharmacistCounterCubit>.value(
          value: cubit,
          child: view,
        ),
      );
    }
    return const MaterialApp(home: view);
  }

  group('PharmacistPortalView Responsive Multi-Viewport', () {
    testWidgets('rendu desktop split view 1280x800 sans aucun overflow',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(cubit: mockCubit));
      await tester.pump();

      // Vérifie la présence des cartes dans l'inbox
      expect(find.byType(PharmacistRequestInboxCard), findsNWidgets(2));
      expect(find.text('#ORD-101'), findsOneWidget);
      expect(find.text('#ORD-102'), findsOneWidget);

      // Panneau de droite vide au départ
      expect(
        find.text('Sélectionnez une commande dans la file'),
        findsOneWidget,
      );
    });

    testWidgets(
        "desktop : sélection d'une commande affiche le panneau de devis à droite",
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCubit.state).thenReturn(
        PharmacistCounterState(
          status: PharmacistCounterStatus.loaded,
          orders: [sampleOrderWaiting, sampleOrderReady],
          selectedOrder: sampleOrderWaiting,
        ),
      );

      await tester.pumpWidget(buildTestWidget(cubit: mockCubit));
      await tester.pump();

      expect(find.byType(PharmacistQuoteReplySheet), findsOneWidget);
    });

    testWidgets(
        "desktop : sélection d'une commande prête affiche le clavier OTP",
        (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      when(() => mockCubit.state).thenReturn(
        PharmacistCounterState(
          status: PharmacistCounterStatus.loaded,
          orders: [sampleOrderWaiting, sampleOrderReady],
          selectedOrder: sampleOrderReady,
        ),
      );

      await tester.pumpWidget(buildTestWidget(cubit: mockCubit));
      await tester.pump();

      expect(find.byType(CounterOtpValidationKeypad), findsOneWidget);
    });

    testWidgets('rendu mobile 390x844 avec onglets fluides sans overflow',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(cubit: mockCubit));
      await tester.pump();

      expect(find.text('Demandes (2)'), findsOneWidget);
      expect(find.text('Traitement & Retrait'), findsOneWidget);
      expect(find.byType(PharmacistRequestInboxCard), findsNWidgets(2));
    });

    testWidgets('instanciation autonome par défaut sans injection préalable',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Sans fournir de cubit au buildTestWidget
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.byType(PharmacistPortalView), findsOneWidget);
    });

    testWidgets(
        'déclenche le son et affiche le badge alerte urgente qui se dissipe lors de l’acquittement',
        (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var soundCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PharmacistCounterCubit>.value(
            value: mockCubit,
            child: PharmacistPortalView(
              initialPharmacyId: 'pharma-soleil',
              enableAlertCycle: false, // évite un timer pendant en fin de test
              onPlayAlertSound: () => soundCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      // Le listener réagit à sampleOrderWaiting (dispatchingWave)
      expect(find.text('Nouvelle demande urgente'), findsOneWidget);
      expect(soundCount, equals(1));

      // Clic sur Acquitter
      final ackBtn = find.byKey(const ValueKey('btn_acknowledge_alert'));
      expect(ackBtn, findsOneWidget);
      await tester.tap(ackBtn);
      await tester.pump();

      expect(find.text('Nouvelle demande urgente'), findsNothing);
    });

    testWidgets('dropdown contient les officines Mandela (Face CHU) et Melen 8',
        (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PharmacistCounterCubit>.value(
            value: mockCubit,
            child: const PharmacistPortalView(
              initialPharmacyId: 'pharma-soleil',
              enableAlertCycle: false,
            ),
          ),
        ),
      );
      await tester.pump();

      // Ouverture du dropdown
      await tester.tap(find.textContaining('Pharmacie du Soleil'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Pharmacie Mandela (Face CHU)'), findsWidgets);
      expect(find.textContaining('Pharmacie Melen 8'), findsWidgets);
    });

    testWidgets(
        'cycle complet 30s/2min : 4 sonneries puis arrêt audio et bandeau maintenu jusqu’à acquittement',
        (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var soundCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PharmacistCounterCubit>.value(
            value: mockCubit,
            child: PharmacistPortalView(
              initialPharmacyId: 'pharma-soleil',
              enableAlertCycle: true,
              onPlayAlertSound: () => soundCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      // t = 0s : 1er déclenchement
      expect(soundCount, equals(1));
      expect(find.text('Nouvelle demande urgente'), findsOneWidget);

      // t = 30s : 2e déclenchement
      await tester.pump(const Duration(seconds: 30));
      expect(soundCount, equals(2));

      // t = 60s : 3e déclenchement
      await tester.pump(const Duration(seconds: 30));
      expect(soundCount, equals(3));

      // t = 90s : 4e déclenchement
      await tester.pump(const Duration(seconds: 30));
      expect(soundCount, equals(4));

      // t = 120s : cycle audio terminé, aucun 5e déclenchement
      await tester.pump(const Duration(seconds: 30));
      expect(soundCount, equals(4));

      // Le bandeau visuel reste présent après 120s tant qu'il n'est pas acquitté
      expect(find.text('Nouvelle demande urgente'), findsOneWidget);

      // Acquittement final
      final ackBtn = find.byKey(const ValueKey('btn_acknowledge_alert'));
      await tester.tap(ackBtn);
      await tester.pump();

      expect(find.text('Nouvelle demande urgente'), findsNothing);
    });

    testWidgets(
        'acquittement précoce à 45s stoppe immédiatement les rappels sonores et le timer',
        (tester) async {
      tester.view.physicalSize = const Size(900, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var soundCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PharmacistCounterCubit>.value(
            value: mockCubit,
            child: PharmacistPortalView(
              initialPharmacyId: 'pharma-soleil',
              enableAlertCycle: true,
              onPlayAlertSound: () => soundCount++,
            ),
          ),
        ),
      );
      await tester.pump();

      // t = 0s
      expect(soundCount, equals(1));

      // t = 30s : 2e déclenchement
      await tester.pump(const Duration(seconds: 30));
      expect(soundCount, equals(2));

      // t = 45s : avance de 15s supplémentaire
      await tester.pump(const Duration(seconds: 15));
      expect(soundCount, equals(2));

      // Acquittement anticipé à 45s
      final ackBtn = find.byKey(const ValueKey('btn_acknowledge_alert'));
      await tester.tap(ackBtn);
      await tester.pump();

      expect(find.text('Nouvelle demande urgente'), findsNothing);

      // Avance de 60s supplémentaires : aucun nouveau son déclenché
      await tester.pump(const Duration(seconds: 60));
      expect(soundCount, equals(2));
    });
  });
}
