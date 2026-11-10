import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/navigation/afya_app_shell.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_event.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_state.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_state.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/request_reservation.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_medications.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_pharmacies.dart';
import 'package:medmate/features/pharmacy_search/presentation/bloc/pharmacy_search_bloc.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_state.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';
import 'package:medmate/features/reservation/presentation/views/patient_flash_flow_view.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacyRepository extends Mock implements PharmacyRepository {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockFlashOrderCubit extends MockCubit<FlashOrderState> implements FlashOrderCubit {}
class MockFlashReservationCubit extends MockCubit<FlashReservationState>
    implements FlashReservationCubit {}
class MockMedicationCatalogCubit extends MockCubit<MedicationCatalogState>
    implements MedicationCatalogCubit {}

void main() {
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

  Widget createShellUnderTest({int initialIndex = 0}) {
    return MultiBlocProvider(
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
      child: MaterialApp(
        home: AfyaAppShell(
          initialIndex: initialIndex,
          enableNetworkTiles: false,
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

  group('AfyaAppShell Navigation & Viewport Tests', () {
    testWidgets('renders mobile shell (390x844) with BottomNavigationBar without overflow', (tester) async {
      configureViewport(tester, width: 390, height: 844);

      await tester.pumpWidget(createShellUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppConfig.appName), findsOneWidget);
      expect(find.text('Yaoundé'), findsWidgets);
      expect(find.text(AppConfig.emergencyPhone), findsOneWidget);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Accueil'), findsOneWidget);
      expect(find.text('Flash Yango'), findsOneWidget);
      expect(find.text('Gardes'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    });

    testWidgets('renders desktop shell (1280x800) with NavigationRail without overflow', (tester) async {
      configureViewport(tester, width: 1280, height: 800);

      await tester.pumpWidget(createShellUnderTest());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Flash Yango'), findsOneWidget);
      expect(find.text('Gardes & Carte'), findsOneWidget);
    });

    testWidgets('navigates to Flash Yango tab when tapped on mobile', (tester) async {
      configureViewport(tester, width: 390, height: 844);

      await tester.pumpWidget(createShellUnderTest());
      await tester.pumpAndSettle();

      final flashTab = find.text('Flash Yango');
      expect(flashTab, findsOneWidget);
      await tester.tap(flashTab);
      await tester.pumpAndSettle();

      expect(find.byType(PatientFlashFlowView), findsOneWidget);
      expect(find.text('Comment fonctionne la recherche Flash ?'), findsOneWidget);
    });

    testWidgets('loads directly to Flash Yango tab with initialIndex = 1', (tester) async {
      configureViewport(tester, width: 1280, height: 800);

      await tester.pumpWidget(createShellUnderTest(initialIndex: 1));
      await tester.pumpAndSettle();

      expect(find.byType(PatientFlashFlowView), findsOneWidget);
      expect(find.text('Comment fonctionne la recherche Flash ?'), findsOneWidget);
    });

    testWidgets('shows emergency call snackbar when tapping emergency badge', (tester) async {
      configureViewport(tester, width: 390, height: 844);

      await tester.pumpWidget(createShellUnderTest());
      await tester.pumpAndSettle();

      final emergencyBtn = find.text(AppConfig.emergencyPhone);
      expect(emergencyBtn, findsOneWidget);
      await tester.tap(emergencyBtn);
      await tester.pump();

      expect(find.text('Numéro d\'urgence Yaoundé : ${AppConfig.emergencyPhone}'), findsOneWidget);
    });
  });
}
