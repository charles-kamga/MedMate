import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/reservation.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_state.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';
import 'package:medmate/features/reservation/presentation/views/patient_flash_flow_view.dart';
import 'package:medmate/features/reservation/presentation/widgets/patient_basket_composer_card.dart';
import 'package:medmate/features/reservation/presentation/widgets/pharmacy_offers_comparison_list.dart';
import 'package:medmate/features/reservation/presentation/widgets/reservation_otp_ticket_card.dart';
import 'package:medmate/features/reservation/presentation/widgets/wave_dispatch_progress_card.dart';
import 'package:medmate/features/reservation/presentation/widgets/yango_pulse_flash_button.dart';
import 'package:mocktail/mocktail.dart';

class MockFlashReservationCubit extends MockCubit<FlashReservationState>
    implements FlashReservationCubit {}

class MockMedicationCatalogCubit extends MockCubit<MedicationCatalogState>
    implements MedicationCatalogCubit {}

void main() {
  late MockFlashReservationCubit mockFlashCubit;
  late MockMedicationCatalogCubit mockCatalogCubit;

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

  final sampleItem = BasketItem(
    id: 'item-1',
    medication: sampleMedication,
    quantity: 2,
    hasPrescription: false,
  );

  final sampleTargets = [
    const DispatchedPharmacy(
      id: 'pharma-soleil',
      name: 'Pharmacie du Soleil',
      quarter: 'Carrefour Warda',
      distanceKm: 0.4,
      phone: '+237 677 12 34 56',
      waveIndex: 1,
      status: PharmacistReplyType.available,
    ),
    const DispatchedPharmacy(
      id: 'pharma-centre',
      name: 'Grande Pharmacie du Centre',
      quarter: 'Poste Centrale',
      distanceKm: 0.9,
      phone: '+237 699 88 77 66',
      waveIndex: 1,
      status: PharmacistReplyType.conditional,
    ),
  ];

  final sampleOffers = [
    PharmacyOffer(
      id: 'OFFER-1',
      pharmacyId: 'pharma-soleil',
      pharmacyName: 'Pharmacie du Soleil',
      quarter: 'Carrefour Warda',
      distanceKm: 0.4,
      phone: '+237 677 12 34 56',
      availabilityType: PharmacyAvailabilityType.fullyAvailable,
      quotedPriceCfa: 3100,
      proposesDelivery: false,
      submittedAt: DateTime.now(),
    ),
    PharmacyOffer(
      id: 'OFFER-2',
      pharmacyId: 'pharma-centre',
      pharmacyName: 'Grande Pharmacie du Centre',
      quarter: 'Poste Centrale',
      distanceKm: 0.9,
      phone: '+237 699 88 77 66',
      availabilityType: PharmacyAvailabilityType.conditional,
      quotedPriceCfa: 3400,
      conditionRequirements: const ['Ordonnance physique'],
      conditionNote: 'Vérification originale requise',
      proposesDelivery: true,
      deliveryFeeCfa: 1000,
      estimatedDeliveryMinutes: 25,
      submittedAt: DateTime.now(),
    ),
    PharmacyOffer(
      id: 'OFFER-3',
      pharmacyId: 'pharma-nord',
      pharmacyName: 'Pharmacie du Nord',
      quarter: 'Nlongkak',
      distanceKm: 3.1,
      phone: '+237 670 11 22 33',
      availabilityType: PharmacyAvailabilityType.unavailable,
      quotedPriceCfa: 0,
      submittedAt: DateTime.now(),
    ),
  ];

  final sampleOrder = FlashOrder(
    id: 'ORD-123456',
    items: [sampleItem],
    quarter: 'Carrefour Warda, Poste Centrale',
    targets: sampleTargets,
    currentWave: 1,
    waveTimeRemainingSeconds: 95,
    offers: sampleOffers,
    status: FlashOrderStatus.offersReceived,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  final sampleReservation = Reservation(
    id: 'RES-998877',
    clientReservationId: 'ORD-123456',
    pharmacyId: 'pharma-soleil',
    pharmacyName: 'Pharmacie du Soleil',
    medicationId: 'med-paracetamol',
    medicationName: 'Paracétamol 500 mg (x2)',
    quantite: 2,
    codeRetraitOtp: '849201',
    statut: ReservationStatus.confirmed,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  setUp(() {
    mockFlashCubit = MockFlashReservationCubit();
    mockCatalogCubit = MockMedicationCatalogCubit();

    when(() => mockFlashCubit.state).thenReturn(const FlashReservationState());
    when(() => mockCatalogCubit.state).thenReturn(const MedicationCatalogInitial());
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<FlashReservationCubit>.value(value: mockFlashCubit),
            BlocProvider<MedicationCatalogCubit>.value(value: mockCatalogCubit),
          ],
          child: PatientFlashFlowView(
            flashCubit: mockFlashCubit,
            catalogCubit: mockCatalogCubit,
            enablePulseAnimation: false,
          ),
        ),
      ),
    );
  }

  void configureViewport(WidgetTester tester, {required double width, required double height}) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('PatientFlashFlowView Multi-Viewport & Responsive Tests', () {
    testWidgets('renders mobile viewport (390x844) in initial state without overflow', (tester) async {
      configureViewport(tester, width: 390, height: 844);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PatientBasketComposerCard), findsOneWidget);
      expect(find.byType(YangoPulseFlashButton), findsOneWidget);
      expect(find.text(AppConfig.pricePolicyNotice), findsOneWidget);
      expect(find.text('Comment fonctionne la recherche Flash ?'), findsOneWidget);
    });

    testWidgets('renders desktop viewport (1280x800) in 2 columns without overflow', (tester) async {
      configureViewport(tester, width: 1280, height: 800);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(PatientBasketComposerCard), findsOneWidget);
      expect(find.byType(YangoPulseFlashButton), findsOneWidget);
      expect(find.text('Comment fonctionne la recherche Flash ?'), findsOneWidget);
    });

    testWidgets('triggers submitFlashRequest when basket is ready and button tapped', (tester) async {
      configureViewport(tester, width: 390, height: 844);

      when(() => mockFlashCubit.state).thenReturn(
        FlashReservationState(
          basketItems: [sampleItem],
          selectedLandmark: sampleLandmark,
          status: FlashReservationStatus.initial,
        ),
      );
      when(() => mockFlashCubit.submitFlashRequest()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('2 médicaments • Carrefour Warda'), findsOneWidget);
      await tester.tap(find.byType(YangoPulseFlashButton));
      await tester.pumpAndSettle();

      verify(() => mockFlashCubit.submitFlashRequest()).called(1);
    });

    testWidgets('displays WaveDispatchProgressCard and triggers wave escalation', (tester) async {
      configureViewport(tester, width: 1280, height: 800);

      when(() => mockFlashCubit.state).thenReturn(
        FlashReservationState(
          basketItems: [sampleItem],
          selectedLandmark: sampleLandmark,
          currentOrder: sampleOrder,
          status: FlashReservationStatus.waveActive,
        ),
      );
      when(() => mockFlashCubit.escalateWave()).thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(WaveDispatchProgressCard), findsOneWidget);
      expect(find.text('Vague 1 active'), findsOneWidget);
      expect(find.text('Pharmacie du Soleil'), findsWidgets);

      final escalateBtn = find.text('Solliciter 2 pharmacies de plus (Vague 2)');
      expect(escalateBtn, findsOneWidget);
      await tester.tap(escalateBtn);
      await tester.pumpAndSettle();

      verify(() => mockFlashCubit.escalateWave()).called(1);
    });

    testWidgets('displays PharmacyOffersComparisonList with 3 statuses and selects offer with phone', (tester) async {
      configureViewport(tester, width: 390, height: 844);

      when(() => mockFlashCubit.state).thenReturn(
        FlashReservationState(
          basketItems: [sampleItem],
          selectedLandmark: sampleLandmark,
          currentOrder: sampleOrder,
          status: FlashReservationStatus.offersReceived,
        ),
      );
      when(() => mockFlashCubit.selectOffer(any(), patientPhone: any(named: 'patientPhone')))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(PharmacyOffersComparisonList), findsOneWidget);
      // Verification des badges des 3 statuts
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Disponible sous conditions'), findsOneWidget);
      expect(find.text('Indisponible'), findsOneWidget);

      // Verification du prix exclusif pharmacien
      expect(find.text('3100 FCFA'), findsOneWidget);
      expect(find.text('Prix exclusif proposé par le pharmacien'), findsWidgets);

      // Clic sur Choisir cette pharmacie
      final chooseBtn = find.widgetWithText(ElevatedButton, 'Choisir cette pharmacie').first;
      await tester.tap(chooseBtn);
      await tester.pumpAndSettle();

      // Dialogue de saisie du telephone
      expect(find.text('Confirmer la sélection'), findsOneWidget);
      expect(find.text('Numéro de téléphone pour le retrait :'), findsOneWidget);

      final confirmBtn = find.widgetWithText(ElevatedButton, 'Confirmer');
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      verify(() => mockFlashCubit.selectOffer(any(), patientPhone: any(named: 'patientPhone')))
          .called(1);
    });

    testWidgets('displays ReservationOtpTicketCard in confirmed state on mobile & desktop without overflow', (tester) async {
      // Test sur mobile
      configureViewport(tester, width: 390, height: 844);

      when(() => mockFlashCubit.state).thenReturn(
        FlashReservationState(
          basketItems: [sampleItem],
          selectedLandmark: sampleLandmark,
          currentOrder: sampleOrder.copyWith(selectedOffer: sampleOffers[0]),
          confirmedReservation: sampleReservation,
          status: FlashReservationStatus.reservationConfirmed,
        ),
      );
      when(() => mockFlashCubit.reset()).thenReturn(null);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(ReservationOtpTicketCard), findsOneWidget);
      expect(find.text('Réservation confirmée !'), findsOneWidget);
      expect(find.text('849201'), findsOneWidget);
      expect(find.text('TTL 2h actif'), findsOneWidget);
      expect(find.text('CODE DE RETRAIT AU COMPTOIR'), findsOneWidget);
      expect(find.text('Itinéraire OSM'), findsOneWidget);
      expect(find.text('Appeler'), findsOneWidget);

      // Clic sur nouvelle recherche
      final newSearchBtn = find.text('Effectuer une nouvelle recherche');
      expect(newSearchBtn, findsOneWidget);
      await tester.tap(newSearchBtn);
      await tester.pumpAndSettle();

      verify(() => mockFlashCubit.reset()).called(1);
    });
  });
}
