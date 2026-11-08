import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/theme/app_theme.dart';
import 'package:medmate/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/flash_order/presentation/cubit/flash_order_cubit.dart';
import 'package:medmate/features/flash_order/presentation/views/patient_request_wizard_view.dart';
import 'package:medmate/features/flash_order/presentation/views/pharmacist_portal_view.dart';
import 'package:medmate/features/pharmacy_search/presentation/views/pharmacy_map_view.dart';

void main() {
  group('Afya Santé V2 - Démonstration & Critères de Validation (Section 12)', () {
    late FlashOrderCubit flashOrderCubit;
    late AuthBloc authBloc;

    setUp(() {
      flashOrderCubit = FlashOrderCubit();
      authBloc = AuthBloc();
    });

    tearDown(() {
      flashOrderCubit.close();
      authBloc.close();
    });

    Widget createTestApp(Widget child) {
      return MultiBlocProvider(
        providers: [
          BlocProvider<FlashOrderCubit>.value(value: flashOrderCubit),
          BlocProvider<AuthBloc>.value(value: authBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('Critère 1 & 2 : Recherche sans pharmacie et vague 1 vers 2 pharmacies avec timer 2 min', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const PatientRequestWizardView()));
      await tester.pumpAndSettle();

      // 1. Étape 1 : Le patient voit son panier et sa zone sans sélectionner de pharmacie
      expect(find.text('Recherche sans pharmacie imposée'), findsOneWidget);
      expect(find.text('Paracétamol 500 mg'), findsOneWidget);
      expect(find.text('Vitamine C 1000 mg'), findsOneWidget);
      expect(find.textContaining('Afya Santé ne fixe aucun tarif à l’avance'), findsOneWidget);

      // 2. Lancement de la recherche
      final launchButton = find.text('Lancer la recherche auprès des partenaires →');
      expect(launchButton, findsOneWidget);
      await tester.ensureVisible(launchButton);
      await tester.tap(launchButton);
      await tester.pump();

      // 3. Étape 2 : Radar de recherche en vagues
      expect(find.text('VAGUE 1 / 2'), findsOneWidget);
      expect(find.text('Sollicitation des pharmacies partenaires'), findsOneWidget);
      expect(find.text('Pharmacie du Soleil'), findsOneWidget);
      expect(find.text('Grande Pharmacie du Centre'), findsOneWidget);
      expect(find.text('Accélérer l’escalade (Démo 2 min)'), findsOneWidget);

      // 4. Test d'accélération de l'escalade
      await tester.tap(find.text('Accélérer l’escalade (Démo 2 min)'));
      await tester.pump();

      expect(find.text('VAGUE 2 / 2'), findsOneWidget);
      expect(find.text("Pharmacie d'Obili"), findsOneWidget);
      expect(find.text('Pharmacie Acacia Biyem-Assi'), findsOneWidget);
      flashOrderCubit.stopWaveTimer();
    });

    testWidgets('Critère 3 & 4 : Pharmacien transmet son offre avec son prix officiel et conditions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const PharmacistPortalView(initialPharmacyId: 'pharma-soleil')));
      await tester.pumpAndSettle();

      // 1. Profil de l'officine
      expect(find.text('Pharmacie du Soleil'), findsWidgets);
      expect(find.text('PARTENAIRE OFFICIEL AFYA SANTÉ'), findsOneWidget);

      // 2. Lancer une commande pour simuler une demande entrante
      flashOrderCubit.launchFlashOrder();
      await tester.pumpAndSettle();

      // 3. Fiche de réponse pharmacien
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Sous conditions'), findsOneWidget);
      expect(find.text('Indisponible'), findsOneWidget);
      expect(find.text('Montant total officiel des médicaments (FCFA) :'), findsOneWidget);

      // 4. Sélectionner "Sous conditions"
      await tester.tap(find.text('Sous conditions'));
      await tester.pumpAndSettle();
      expect(find.text('Présentation de l’ordonnance originale obligatoire'), findsOneWidget);

      // 5. Transmettre l'offre chiffrée
      final submitButton = find.text('Transmettre notre offre chiffrée →');
      expect(submitButton, findsOneWidget);
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.text('Offre transmise au patient'), findsOneWidget);
      flashOrderCubit.stopWaveTimer();
    });

    testWidgets('Critère 5 & 6 : Comparaison, Choix patient, Règlement et Code OTP de retrait', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const PatientRequestWizardView()));
      await tester.pumpAndSettle();

      // 1. Lancer la recherche et injecter 2 offres concurrentes
      flashOrderCubit
        ..launchFlashOrder()
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-soleil',
          availability: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 3500,
        )
        ..submitPharmacistQuote(
          pharmacyId: 'pharma-centre',
          availability: PharmacyAvailabilityType.conditional,
          quotedPriceCfa: 2900,
          conditionRequirements: const ['Ordonnance originale requise'],
          proposesDelivery: true,
          deliveryFeeCfa: 500,
        );
      await tester.pumpAndSettle();

      // 2. Étape 3 : Comparateur d'offres
      expect(find.text('Offres reçues (2)'), findsOneWidget);
      expect(find.text('3500 FCFA'), findsOneWidget);
      expect(find.text('3400 FCFA'), findsOneWidget); // 2900 + 500 livraison
      expect(find.textContaining('Ordonnance originale requise'), findsOneWidget);

      // 3. Le patient choisit l'offre de la Grande Pharmacie du Centre
      final chooseButtons = find.widgetWithText(ElevatedButton, 'Choisir cette pharmacie →');
      expect(chooseButtons, findsWidgets);
      await tester.tap(chooseButtons.last);
      await tester.pumpAndSettle();

      // 4. Étape 4 : Choix du règlement
      expect(find.text('Validation de votre réservation'), findsOneWidget);
      expect(find.text('3400 FCFA'), findsOneWidget);
      expect(find.text('Paiement au comptoir (Espèces ou Mobile Money sur place)'), findsOneWidget);

      // 5. Confirmer et générer le code OTP
      final confirmButton = find.text('Confirmer la réservation & Obtenir le code OTP →');
      expect(confirmButton, findsOneWidget);
      await tester.ensureVisible(confirmButton);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // 6. Code OTP grand format et TTL 2h
      expect(find.text('Réservation confirmée !'), findsOneWidget);
      expect(find.text('CODE DE RETRAIT UNIQUE (OTP)'), findsOneWidget);
      expect(find.textContaining('RET-'), findsOneWidget);
      expect(find.text('Validité : 2 heures au comptoir'), findsOneWidget);
      flashOrderCubit.stopWaveTimer();
    });

    testWidgets('Critère 7 : Carte interactive avec distinction stricte partenaires vs non-partenaires', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(const PharmacyMapView(enableNetworkTiles: false)));
      await tester.pumpAndSettle();

      // 1. Légende explicite
      expect(find.text('Partenaires in-app (3)'), findsOneWidget);
      expect(find.text('Non-partenaires (2)'), findsOneWidget);

      // 2. Clic sur une pharmacie partenaire (Grande Pharmacie du Centre)
      final partnerIcon = find.byIcon(Icons.local_pharmacy_rounded).first;
      await tester.tap(partnerIcon);
      await tester.pumpAndSettle();

      expect(find.text('✓ PARTENAIRE AFYA SANTÉ'), findsOneWidget);
      expect(find.text('Solliciter'), findsOneWidget);

      // 3. Clic sur une pharmacie non-partenaire (Pharmacie Acacia Biyem-Assi)
      final nonPartnerIcon = find.byIcon(Icons.storefront_outlined).first;
      await tester.tap(nonPartnerIcon);
      await tester.pumpAndSettle();

      expect(find.text('NON PARTENAIRE (RECENSÉE)'), findsOneWidget);
      expect(find.textContaining('Elle n’est pas partenaire et ne reçoit pas de requêtes directes'), findsOneWidget);
      expect(find.text('Appeler l’officine directement'), findsOneWidget);
      // Ne doit PAS afficher de bouton de commande in-app
      expect(find.text('Solliciter'), findsNothing);
    });
  });
}
