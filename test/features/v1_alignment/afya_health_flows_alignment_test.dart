import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/navigation/afya_app_shell.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_event.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_state.dart';
import 'package:medmate/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_state.dart';
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

class MockFlashOrderCubit extends MockCubit<FlashOrderState>
    implements FlashOrderCubit {}

class MockFlashReservationCubit extends MockCubit<FlashReservationState>
    implements FlashReservationCubit {}

class MockMedicationCatalogCubit extends MockCubit<MedicationCatalogState>
    implements MedicationCatalogCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    items: const [
      BasketItem(id: 'item-1', medication: sampleMedication, quantity: 1),
    ],
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

  group('Afya-Health V1 — ReservationOtpTicketCard & WaveDispatchProgressCard',
      () {
    testWidgets(
        'ReservationOtpTicketCard mentionne le règlement sur place au comptoir',
        (tester) async {
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

      expect(
        find.text('Règlement sur place au comptoir au moment du retrait (V1)'),
        findsOneWidget,
      );
    });

    testWidgets(
        'ReservationOtpTicketCard affiche le QR code et déclenche le bouton annuler ma demande',
        (tester) async {
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

    testWidgets(
        'WaveDispatchProgressCard affiche et actionne bouton de recours pharmacies de garde',
        (tester) async {
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
      when(() => mockFlashCubit.state)
          .thenReturn(const FlashReservationState());
      when(() => mockCatalogCubit.state)
          .thenReturn(const MedicationCatalogInitial());
    });

    testWidgets('onglet 2 bascule entre DutyPharmacyScreen et PharmacyMapView',
        (tester) async {
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
      expect(
        find.byKey(const ValueKey('btn_switch_duty_list')),
        findsOneWidget,
      );
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
