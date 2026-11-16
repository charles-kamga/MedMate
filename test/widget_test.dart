import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/navigation/afya_app_shell.dart';
import 'package:medmate/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart';
import 'package:medmate/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'package:medmate/features/reservation/presentation/widgets/patient_basket_composer_card.dart';
import 'package:medmate/main.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacyRepository extends Mock implements PharmacyRepository {}

void main() {
  late MockPharmacyRepository mockRepository;

  setUp(() {
    mockRepository = MockPharmacyRepository();
  });

  testWidgets('Test de la barre de navigation et en-tête unifié AfyaAppShell',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Vérification du Shell unifié
    expect(find.byType(AfyaAppShell), findsOneWidget);

    // Vérification de l'en-tête de marque et secours
    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.text('✚'), findsOneWidget);
    expect(find.text('Yaoundé'), findsWidgets);
    expect(find.text(AppConfig.emergencyPhone), findsOneWidget);

    // Vérification des 4 onglets officiels unifiés
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Flash Yango'), findsOneWidget);
    expect(find.text('Gardes'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Onglet Accueil par défaut : carte d'accès garde et message
    expect(find.text('Pharmacies de garde ce soir'), findsOneWidget);
  });

  testWidgets(
      'Test de l’onglet Gardes, accès à DutyPharmacyScreen et bascule Carte OSM',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Navigation vers l'onglet Gardes
    await tester.tap(find.text('Gardes'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab_map_duty')), findsOneWidget);
    expect(find.byType(DutyPharmacyScreen), findsOneWidget);
    expect(find.text('Pharmacies de garde'), findsWidgets);
    expect(
      find.text('Trouvez une pharmacie de garde près de vous'),
      findsOneWidget,
    );
    expect(find.text('Programme de garde'), findsOneWidget);
    expect(find.text('Plus proches'), findsOneWidget);
    expect(find.text('Toutes les gardes'), findsOneWidget);

    // Bascule vers la Carte OSM
    final mapSwitchBtn = find.byKey(const ValueKey('btn_switch_map_view'));
    expect(mapSwitchBtn, findsOneWidget);
    await tester.tap(mapSwitchBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('view_osm_map')), findsOneWidget);

    // Retour vers la liste de garde
    final listSwitchBtn = find.byKey(const ValueKey('btn_switch_duty_list'));
    expect(listSwitchBtn, findsOneWidget);
    await tester.tap(listSwitchBtn);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('view_duty_list')), findsOneWidget);
  });

  testWidgets(
      'Test du flux Flash Yango via le shell unifié (composer panier & repère)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Navigation vers l'onglet Flash Yango
    await tester.tap(find.text('Flash Yango'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab_flash_yango')), findsOneWidget);
    expect(find.byType(PatientBasketComposerCard), findsOneWidget);
    expect(find.text('Carrefour ou quartier repère'), findsOneWidget);
    expect(find.text('Rechercher un médicament homologué'), findsOneWidget);
    expect(find.text(AppConfig.pricePolicyNotice), findsOneWidget);
  });

  testWidgets(
      'Test de l’onglet Profil et passerelle vers le portail pharmacien',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Navigation vers l'onglet Profil
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tab_profile')), findsOneWidget);
    expect(find.text('Mon profil ${AppConfig.appName}'), findsOneWidget);
    expect(find.text('Portail Officine Partenaire'), findsOneWidget);

    // Ouverture du portail pharmacien
    await tester.tap(find.text('Portail Officine Partenaire'));
    await tester.pumpAndSettle();

    expect(find.byType(PharmacistPortalView), findsOneWidget);

    // Acquitter l'alerte pour annuler le timer d'alerte
    final ackBtn = find.byKey(const ValueKey('btn_acknowledge_alert'));
    if (ackBtn.evaluate().isNotEmpty) {
      await tester.tap(ackBtn);
      await tester.pump();
    }

    // Retour en arrière pour nettoyer la pile de navigation
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'Test rétrocompatibilité MainNavigationScreen quand useAfyaAppShell est false',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
        useAfyaAppShell: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mes recherches'), findsOneWidget);
    expect(find.text('Rappels'), findsOneWidget);
    expect(find.text('De quels médicaments avez-vous besoin ?'), findsOneWidget);
  });

  testWidgets('Test injection déterministe via AppDependencies',
      (WidgetTester tester) async {
    final customDeps = AppDependencies.build(
      pharmacyRepository: mockRepository,
    );

    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        dependencies: customDeps,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AfyaAppShell), findsOneWidget);
  });
}
