import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/core/navigation/afya_app_shell.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_event.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_state.dart';
import 'package:medmate/features/duty_pharmacy/data/repositories/duty_pharmacy_repository_impl.dart';
import 'package:medmate/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_state.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_state.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/pharmacist_quote_reply_sheet.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/reservation.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/request_reservation.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_medications.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_pharmacies.dart';
import 'package:medmate/features/pharmacy_search/presentation/bloc/pharmacy_search_bloc.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_state.dart';
import 'package:medmate/features/pharmacy_search/presentation/views/pharmacy_map_view.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';
import 'package:medmate/features/reservation/presentation/widgets/reservation_otp_ticket_card.dart';
import 'package:medmate/features/reservation/presentation/widgets/wave_dispatch_progress_card.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacyRepository extends Mock implements PharmacyRepository {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockFlashOrderCubit extends MockCubit<FlashOrderState> implements FlashOrderCubit {}
class MockFlashReservationCubit extends MockCubit<FlashReservationState> implements FlashReservationCubit {}
class MockMedicationCatalogCubit extends MockCubit<MedicationCatalogState> implements MedicationCatalogCubit {}
class MockPharmacistCounterCubit extends MockCubit<PharmacistCounterState> implements PharmacistCounterCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(PharmacyAvailabilityType.fullyAvailable);
  });

  const sampleMedication = Medication(
    id: 'med-doliprane',
    nomCommercial: 'Doliprane 1000mg',
    dci: 'Paracétamol',
    forme: 'Comprimé',
    dosage: '1000mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1500,
    necessiteOrdonnance: false,
  );

  final sampleOrder = FlashOrder(
    id: 'ORD-TEST-V1',
    items: const [BasketItem(id: 'item-1', medication: sampleMedication, quantity: 1)],
    quarter: 'Melen, Yaoundé 3e',
    targets: const [
      DispatchedPharmacy(
        id: 'pharma-mandela',
        name: 'Pharmacie Mandela Face CHU',
        quarter: 'Melen / Face CHU',
        distanceKm: 0.5,
        phone: '+237242792985',
        waveIndex: 1,
      ),
    ],
    currentWave: 1,
    waveTimeRemainingSeconds: 90,
    offers: const [],
    status: FlashOrderStatus.dispatchingWave,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  group('Afya-Health V1 — Configuration, Constantes & Données Pilotes', () {
    test('Identité de marque & drapeaux V1 validés', () {
      expect(AppConfig.appName, 'Afya-Health');
      expect(AppConfig.appTagline, 'La santé, avec clarté.');
      expect(AppConfig.pricePolicyNotice, contains('Afya-Health'));
      expect(AppConfig.enableDeliveryInV1, isFalse);
      expect(AppConfig.enableInAppPaymentInV1, isFalse);
      expect(AppConfig.clientSupportPhone, '+237 656 63 25 01');
      expect(AppConfig.pharmacySupportPhone, contains('+237 659 80 58 04'));
      expect(AppConfig.officialEmail, 'deanstephan06.tf@gmail.com');
    });

    test('Repères géographiques de la zone pilote Yaoundé Melen / Ngoa-Ekellé', () {
      final melen = YaoundeLandmarks.list.firstWhere((l) => l.id == 'carrefour-melen-chu');
      expect(melen.nom, 'Carrefour Melen / CHU');
      expect(melen.latitude, closeTo(3.8539, 0.001));
      expect(melen.longitude, closeTo(11.4870, 0.001));

      final polytech = YaoundeLandmarks.list.firstWhere((l) => l.id == 'ngoa-ekelle-ensp');
      expect(polytech.nom, contains('ENSP'));
      expect(polytech.latitude, closeTo(3.8622, 0.001));
      expect(polytech.longitude, closeTo(11.5003, 0.001));
    });

    test('Référentiel des pharmacies de garde inclut les officines MboaPHARMA pilotes', () async {
      const repo = DutyPharmacyRepositoryImpl();
      final result = await repo.getDutyPharmacies(city: 'Yaoundé');
      expect(result.isRight(), isTrue);

      final pharmacies = result.getOrElse((_) => []);
      expect(pharmacies.any((p) => p.name.contains('Mandela')), isTrue);
      expect(pharmacies.any((p) => p.name.contains('Acacias')), isTrue);
      expect(pharmacies.any((p) => p.name.contains('Well')), isTrue);
      expect(pharmacies.any((p) => p.name.contains('Nsimeyong')), isTrue);
      expect(pharmacies.any((p) => p.quarter == 'Bastos'), isTrue);
    });
  });

  group('Afya-Health V1 — PharmacistQuoteReplySheet', () {
    late MockPharmacistCounterCubit mockCounterCubit;

    setUp(() {
      mockCounterCubit = MockPharmacistCounterCubit();
      when(() => mockCounterCubit.state).thenReturn(const PharmacistCounterState());
    });

    testWidgets('affiche bandeau V1 retrait comptoir quand enableDeliveryOption = false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PharmacistCounterCubit>.value(
              value: mockCounterCubit,
              child: PharmacistQuoteReplySheet(
                order: sampleOrder,
                pharmacyId: 'pharma-mandela',
                enableDeliveryOption: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Retrait au comptoir uniquement (V1) · Paiement sur place'), findsOneWidget);
      expect(find.byKey(const ValueKey('switch_mototaxi')), findsNothing);
    });

    testWidgets('affiche switch mototaxi quand enableDeliveryOption = true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PharmacistCounterCubit>.value(
              value: mockCounterCubit,
              child: PharmacistQuoteReplySheet(
                order: sampleOrder,
                pharmacyId: 'pharma-mandela',
                enableDeliveryOption: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('switch_mototaxi')), findsOneWidget);
    });

    testWidgets('case majorité requise sous conditions transmise au devis', (tester) async {
      when(
        () => mockCounterCubit.submitQuote(
          orderId: any(named: 'orderId'),
          pharmacyId: any(named: 'pharmacyId'),
          availability: any(named: 'availability'),
          quotedPriceCfa: any(named: 'quotedPriceCfa'),
          conditionRequirements: any(named: 'conditionRequirements'),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: any(named: 'proposesDelivery'),
          deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
          estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PharmacistCounterCubit>.value(
              value: mockCounterCubit,
              child: PharmacistQuoteReplySheet(
                order: sampleOrder,
                pharmacyId: 'pharma-mandela',
                enableDeliveryOption: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clic onglet Sous conditions
      await tester.tap(find.text('Sous conditions'));
      await tester.pumpAndSettle();

      // Coche majorité requise
      final majorityCheckbox = find.text("Pièce d'identité / Majorité requise");
      expect(majorityCheckbox, findsOneWidget);
      await tester.tap(majorityCheckbox);
      await tester.pumpAndSettle();

      // Saisie prix
      await tester.enterText(find.byKey(const ValueKey('input_quoted_price')), '4200');
      await tester.pump();

      // Soumission
      await tester.tap(find.byKey(const ValueKey('btn_submit_counter_quote')));
      await tester.pump();

      verify(
        () => mockCounterCubit.submitQuote(
          orderId: 'ORD-TEST-V1',
          pharmacyId: 'pharma-mandela',
          availability: PharmacyAvailabilityType.conditional,
          quotedPriceCfa: 4200,
          conditionRequirements: any(
            named: 'conditionRequirements',
            that: contains("Pièce d'identité / Majorité requise"),
          ),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: false,
          deliveryFeeCfa: 0,
          estimatedDeliveryMinutes: null,
        ),
      ).called(1);
    });
  });

  group('Afya-Health V1 — ReservationOtpTicketCard & WaveDispatchProgressCard', () {
    testWidgets('ReservationOtpTicketCard mentionne le règlement sur place au comptoir', (tester) async {
      final now = DateTime.now();
      final reservation = Reservation(
        id: 'RES-001',
        clientReservationId: 'ORD-001',
        pharmacyId: 'pharma-mandela',
        pharmacyName: 'Pharmacie Mandela Face CHU',
        medicationId: 'med-doliprane',
        medicationName: 'Doliprane 1000mg',
        quantite: 2,
        codeRetraitOtp: '654321',
        statut: ReservationStatus.confirmed,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReservationOtpTicketCard(
                reservation: reservation,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Règlement sur place au comptoir au moment du retrait (V1)'), findsOneWidget);
    });

    testWidgets('ReservationOtpTicketCard affiche le QR code et déclenche le bouton annuler ma demande', (tester) async {
      final now = DateTime.now();
      final reservation = Reservation(
        id: 'RES-002',
        clientReservationId: 'ORD-002',
        pharmacyId: 'pharma-mandela',
        pharmacyName: 'Pharmacie Mandela Face CHU',
        medicationId: 'med-doliprane',
        medicationName: 'Doliprane 1000mg',
        quantite: 1,
        codeRetraitOtp: '123456',
        statut: ReservationStatus.confirmed,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
      );

      var cancelTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReservationOtpTicketCard(
                reservation: reservation,
                onCancel: () => cancelTriggered = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('qr_code_otp_ticket')), findsOneWidget);
      final cancelBtn = find.byKey(const ValueKey('btn_cancel_reservation'));
      expect(cancelBtn, findsOneWidget);

      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(cancelTriggered, isTrue);
    });

    testWidgets('WaveDispatchProgressCard affiche et actionne bouton de recours pharmacies de garde', (tester) async {
      var dutyOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WaveDispatchProgressCard(
              order: sampleOrder,
              onOpenDutyPharmacies: () => dutyOpened = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dutyBtn = find.text('Pharmacies de garde les plus proches');
      expect(dutyBtn, findsOneWidget);

      await tester.tap(dutyBtn);
      await tester.pump();
      expect(dutyOpened, isTrue);
    });
  });

  group('Afya-Health V1 — AfyaAppShell Bascule Gardes & Carte', () {
    late MockPharmacyRepository mockRepo;
    late MockAuthBloc mockAuthBloc;
    late MockFlashOrderCubit mockFlashOrderCubit;
    late MockFlashReservationCubit mockFlashCubit;
    late MockMedicationCatalogCubit mockCatalogCubit;

    setUp(() {
      mockRepo = MockPharmacyRepository();
      mockAuthBloc = MockAuthBloc();
      mockFlashOrderCubit = MockFlashOrderCubit();
      mockFlashCubit = MockFlashReservationCubit();
      mockCatalogCubit = MockMedicationCatalogCubit();

      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockFlashOrderCubit.state).thenReturn(const FlashOrderState());
      when(() => mockFlashCubit.state).thenReturn(const FlashReservationState());
      when(() => mockCatalogCubit.state).thenReturn(const MedicationCatalogInitial());
    });

    testWidgets('onglet 2 bascule entre DutyPharmacyScreen et PharmacyMapView', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<FlashOrderCubit>.value(value: mockFlashOrderCubit),
            BlocProvider<PharmacySearchBloc>(
              create: (_) => PharmacySearchBloc(
                searchPharmaciesUseCase: SearchPharmaciesUseCase(mockRepo),
                searchMedicationsUseCase: SearchMedicationsUseCase(mockRepo),
                requestReservationUseCase: RequestReservationUseCase(mockRepo),
              ),
            ),
            BlocProvider<FlashReservationCubit>.value(value: mockFlashCubit),
            BlocProvider<MedicationCatalogCubit>.value(value: mockCatalogCubit),
          ],
          child: const MaterialApp(
            home: AfyaAppShell(
              initialIndex: 2,
              enableNetworkTiles: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Vérification état initial de l'onglet : Liste de gardes active
      expect(find.byKey(const ValueKey('btn_switch_duty_list')), findsOneWidget);
      expect(find.byKey(const ValueKey('btn_switch_map_view')), findsOneWidget);
      expect(find.byType(DutyPharmacyScreen), findsOneWidget);
      expect(find.byType(PharmacyMapView), findsNothing);

      // Clic pour basculer sur la carte OSM
      await tester.tap(find.byKey(const ValueKey('btn_switch_map_view')));
      await tester.pumpAndSettle();

      expect(find.byType(PharmacyMapView), findsOneWidget);
      expect(find.byType(DutyPharmacyScreen), findsNothing);

      // Re-clic pour revenir à la liste des gardes
      await tester.tap(find.byKey(const ValueKey('btn_switch_duty_list')));
      await tester.pumpAndSettle();

      expect(find.byType(DutyPharmacyScreen), findsOneWidget);
      expect(find.byType(PharmacyMapView), findsNothing);
    });
  });
}
