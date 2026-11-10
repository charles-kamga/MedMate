import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medmate/core/navigation/afya_app_shell.dart';
import 'package:medmate/core/theme/app_theme.dart';
import 'package:medmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:medmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_cubit.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Widget createShellWidget({int initialIndex = 0}) {
    final authDataSource = AuthLocalDataSourceImpl();
    final authRepo = AuthRepositoryImpl(localDataSource: authDataSource);
    final authCubit = AuthCubit(authRepository: authRepo);

    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: AfyaAppShell(initialIndex: initialIndex),
      ),
    );
  }

  group('AfyaAppShell Responsive Multi-Viewport Tests', () {
    testWidgets(
      'Viewport Mobile Compact (360x700) : NavigationBar présent, NavigationRail absent, zéro overflow',
      (tester) async {
        tester.view.physicalSize = const Size(360, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createShellWidget());
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('afya_bottom_navigation_bar')),
          findsOneWidget,
        );
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(find.byKey(const Key('afya_navigation_rail')), findsNothing);
        expect(find.byType(NavigationRail), findsNothing);

        expect(find.text('Afya Santé'), findsOneWidget);
        expect(find.text('Mode Mobile Patient'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Viewport Desktop Comptoir (1280x800) : NavigationRail présent, NavigationBar absent, zéro overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createShellWidget());
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('afya_navigation_rail')), findsOneWidget);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byKey(const Key('afya_bottom_navigation_bar')), findsNothing);
        expect(find.byType(NavigationBar), findsNothing);

        expect(find.text('Afya Santé'), findsOneWidget);
        expect(find.text('Mode Desktop Comptoir'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Viewport Large Desktop (1920x1080) : affiche sans exception ni débordement',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createShellWidget());
        await tester.pumpAndSettle();

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('Afya Santé'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('AfyaAppShell Tab Switching Tests', () {
    testWidgets(
      'bascule dynamiquement entre les 4 onglets sur Mobile (NavigationBar)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createShellWidget());
        await tester.pumpAndSettle();

        // Onglet initial 0 : Recherche
        expect(find.text('Yaoundé · Disponibilité & Gardes'), findsOneWidget);
        expect(find.text('Mode Mobile Patient'), findsOneWidget);

        // Bascule vers Onglet 1 : Gardes
        await tester.tap(find.text('Gardes'));
        await tester.pumpAndSettle();
        expect(find.text('Pharmacies de Garde à Yaoundé'), findsOneWidget);
        expect(find.text('Urgences médicales : 1510'), findsOneWidget);

        // Bascule vers Onglet 2 : Réservation
        await tester.tap(find.text('Réservation'));
        await tester.pumpAndSettle();
        expect(find.text('Commande Flash & Réservation'), findsOneWidget);
        expect(find.text('Délai de retrait : 2h max'), findsOneWidget);

        // Bascule vers Onglet 3 : Espace Pro
        await tester.tap(find.text('Espace Pro'));
        await tester.pumpAndSettle();
        expect(find.text('Espace Pro Pharmacien'), findsOneWidget);
        expect(find.byKey(const Key('pharmacist_sign_in_button')), findsOneWidget);

        // Retour vers Onglet 0 : Recherche
        await tester.tap(find.text('Recherche'));
        await tester.pumpAndSettle();
        expect(find.text('Yaoundé · Disponibilité & Gardes'), findsOneWidget);
      },
    );

    testWidgets(
      'bascule dynamiquement entre les 4 onglets sur Desktop (NavigationRail)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createShellWidget());
        await tester.pumpAndSettle();

        // Onglet 0 : Recherche
        expect(find.text('Mode Desktop Comptoir'), findsOneWidget);

        // Navigation vers Gardes
        await tester.tap(find.text('Gardes'));
        await tester.pumpAndSettle();
        expect(find.text('Pharmacies de Garde à Yaoundé'), findsOneWidget);

        // Navigation vers Réservation
        await tester.tap(find.text('Réservation'));
        await tester.pumpAndSettle();
        expect(find.text('Commande Flash & Réservation'), findsOneWidget);

        // Navigation vers Espace Pro
        await tester.tap(find.text('Espace Pro'));
        await tester.pumpAndSettle();
        expect(find.text('Espace Pro Pharmacien'), findsOneWidget);
      },
    );

    testWidgets(
      'ouvre directement le bon onglet si initialIndex est spécifié',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(createShellWidget(initialIndex: 3));
        await tester.pumpAndSettle();

        expect(find.text('Espace Pro Pharmacien'), findsOneWidget);
      },
    );
  });
}
