import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'package:medmate/main.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacyRepository extends Mock implements PharmacyRepository {}

void main() {
  late MockPharmacyRepository mockRepository;

  setUp(() {
    mockRepository = MockPharmacyRepository();
  });

  testWidgets('Test de la barre de navigation et en-tête MedMate', (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Vérification de la marque MedMate dans le Header
    expect(find.text('MedMate'), findsOneWidget);
    expect(find.text('✚'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    expect(find.byIcon(Icons.person_outline_rounded), findsWidgets);

    // Vérification des 4 onglets de navigation
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Mes recherches'), findsOneWidget);
    expect(find.text('Rappels'), findsOneWidget);
    expect(find.text('Profil'), findsOneWidget);

    // Vue par défaut : Étape 0 (Accueil)
    expect(find.text('De quels médicaments avez-vous besoin ?'), findsOneWidget);
    expect(find.text('Trouver mes médicaments →'), findsOneWidget);
  });

  testWidgets('Test du parcours complet Étape 0 à 4 selon spécifications maître d’œuvre', (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Étape 0 : Clic sur le bouton principal pour démarrer le parcours
    final startButton = find.text('Trouver mes médicaments →');
    expect(startButton, findsOneWidget);
    await tester.ensureVisible(startButton);
    await tester.tap(startButton);
    await tester.pumpAndSettle();

    // Étape 1 : Choisissez vos médicaments
    expect(find.text('Étape 1 sur 4'), findsOneWidget);
    expect(find.text('Choisissez vos médicaments'), findsOneWidget);
    expect(find.text('Votre liste est vide.'), findsOneWidget);

    // Ajouter 'Paracétamol 500 mg'
    final addButtons = find.widgetWithText(OutlinedButton, '+ Ajouter');
    expect(addButtons, findsWidgets);
    await tester.ensureVisible(addButtons.first);
    await tester.tap(addButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Ma liste (1)'), findsOneWidget);
    expect(find.text('Retirer'), findsOneWidget);

    // Clic sur Continuer vers l'étape 2
    final continueButton = find.text('Continuer →');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // Étape 2 : Trouvez une pharmacie
    expect(find.text('Étape 2 sur 4'), findsOneWidget);
    expect(find.text('Trouvez une pharmacie'), findsOneWidget);
    expect(find.textContaining('Pharmacie du Centre'), findsWidgets);
    expect(find.text('Tous disponibles'), findsWidgets);

    // Choisir la première pharmacie
    final choosePharmacy = find.widgetWithText(OutlinedButton, 'Choisir cette pharmacie →').first;
    await tester.ensureVisible(choosePharmacy);
    await tester.tap(choosePharmacy);
    await tester.pumpAndSettle();

    // Étape 3 : Fiche détaillée de la pharmacie
    expect(find.text('Étape 3 sur 4'), findsOneWidget);
    expect(find.text('Pharmacie du Centre'), findsOneWidget);
    expect(find.text('Votre liste'), findsOneWidget);
    expect(find.text('Total indicatif'), findsOneWidget);
    expect(find.textContaining('500 FCFA'), findsWidgets);

    // Clic sur 'Voir l’itinéraire →'
    final routeButton = find.text('Voir l’itinéraire →');
    await tester.ensureVisible(routeButton);
    await tester.tap(routeButton);
    await tester.pumpAndSettle();

    // Étape 4 : Rendez-vous à la pharmacie
    expect(find.text('Étape 4 sur 4'), findsOneWidget);
    expect(find.text('Rendez-vous à la pharmacie'), findsOneWidget);
    expect(find.text('Ouvrir dans Google Maps ↗'), findsOneWidget);

    // Terminer et retourner à l'accueil
    final finishButton = find.text('Terminer');
    await tester.ensureVisible(finishButton);
    await tester.tap(finishButton);
    await tester.pumpAndSettle();

    // De retour sur Étape 0
    expect(find.text('De quels médicaments avez-vous besoin ?'), findsOneWidget);
  });

  testWidgets('Test de navigation dans les onglets auxiliaires et raccourcis', (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigation vers Mes recherches
    await tester.tap(find.text('Mes recherches'));
    await tester.pumpAndSettle();
    expect(find.text('Retrouvez vos médicaments rapidement.'), findsOneWidget);
    expect(find.text('Rechercher maintenant'), findsOneWidget);

    // 2. Navigation vers Rappels
    await tester.tap(find.text('Rappels'));
    await tester.pumpAndSettle();
    expect(find.text('Mes rappels'), findsOneWidget);
    expect(find.text('Vos rappels de prise de médicaments apparaîtront ici.'), findsOneWidget);

    // 3. Navigation vers Profil
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Mon profil'), findsOneWidget);
    expect(find.text('Bienvenue dans votre espace patient MedMate.'), findsOneWidget);
    expect(find.text('Carte interactive des pharmacies'), findsOneWidget);

    // 4. Clic sur Notifications dans la barre supérieure
    await tester.tap(find.byIcon(Icons.notifications_none_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Aucune nouvelle notification.'), findsOneWidget);

    // 5. Clic sur 'Retour à l’accueil'
    await tester.tap(find.text('Retour à l’accueil'));
    await tester.pumpAndSettle();
    expect(find.text('De quels médicaments avez-vous besoin ?'), findsOneWidget);
  });
}
