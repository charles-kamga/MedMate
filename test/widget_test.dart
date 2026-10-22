import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'package:medmate/main.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacyRepository extends Mock implements PharmacyRepository {}

void main() {
  late MockPharmacyRepository mockRepository;

  setUp(() {
    mockRepository = MockPharmacyRepository();
    when(
      () => mockRepository.searchNearbyPharmacies(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        maxRadiusMeters: any(named: 'maxRadiusMeters'),
      ),
    ).thenAnswer((_) async => const Right<Never, List<Pharmacy>>([]));
  });

  testWidgets('Smoke test affichage complet du prototype MedMate', (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // Vérification de la présence de la barre de navigation à 4 onglets
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Commande Flash'), findsOneWidget);
    expect(find.text('Médicaments'), findsOneWidget);
    expect(find.text('Pharmacies'), findsOneWidget);
    expect(find.text('Mon Espace'), findsOneWidget);

    // Onglet par défaut : Commande Flash
    expect(find.text('Commande Flash Démo'), findsOneWidget);
    expect(find.text('Vue Patient'), findsOneWidget);
    expect(find.text('Vue Pharmacien'), findsOneWidget);
    expect(find.text('Lancer la commande flash (2 à 3 pharmacies)'), findsOneWidget);

    // Basculer vers l'onglet Pharmacies pour valider la cartographie
    await tester.tap(find.text('Pharmacies'));
    await tester.pumpAndSettle();

    expect(find.text('Repères & Carrefours de Yaoundé'), findsOneWidget);
    expect(find.text('Carrefour Warda'), findsOneWidget);

    // Basculer vers l'onglet Catalogue pour valider le catalogue homologué
    await tester.tap(find.text('Médicaments'));
    await tester.pumpAndSettle();

    expect(find.text('Catalogue & Disponibilité'), findsOneWidget);

    // Basculer vers l'onglet Mon Espace pour valider l'espace sécurité
    await tester.tap(find.text('Mon Espace'));
    await tester.pumpAndSettle();

    expect(find.text('Espace Patient & Sécurité'), findsOneWidget);
    expect(find.text('Connexion Rapide par SMS OTP'), findsOneWidget);
  });

  testWidgets('Test complet du flux client Commande Flash (Patient -> Dispatch -> Pharmacien -> OTP)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pumpAndSettle();

    // 1. Patient lance la commande flash
    final launchButton = find.text('Lancer la commande flash (2 à 3 pharmacies)');
    expect(launchButton, findsOneWidget);
    await tester.ensureVisible(launchButton);
    await tester.tap(launchButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 2. Dispatch radar en cours vers 3 pharmacies
    expect(find.text('Dispatch MedMate en cours...'), findsOneWidget);
    expect(find.textContaining('Pharmacie du Soleil'), findsWidgets);

    // 3. Bascule vers la Vue Pharmacien pour répondre à la commande
    await tester.tap(find.text('Vue Pharmacien'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Demande #ORD-'), findsOneWidget);
    expect(find.text('1. Disponible (En Stock)'), findsOneWidget);
    expect(find.text('2. Disponible sous conditions...'), findsOneWidget);
    expect(find.text('3. Indisponible (Rupture)'), findsOneWidget);

    // 4. Le pharmacien clique "Disponible" (gagne immédiatement la commande)
    await tester.tap(find.text('1. Disponible (En Stock)'));
    await tester.pumpAndSettle();

    expect(find.text('Félicitations ! Vous avez remporté cette commande.'), findsOneWidget);

    // 5. Bascule vers la Vue Patient pour finaliser
    await tester.tap(find.text('Vue Patient'));
    await tester.pumpAndSettle();

    expect(find.text('Pharmacie trouvée !'), findsOneWidget);
    expect(find.text('Pharmacie du Soleil a répondu en premier'), findsOneWidget);

    // 6. Choix du mode d'acquisition : Code OTP au comptoir
    final reserveBtn = find.text('Générer mon Code de Réservation au Comptoir');
    expect(reserveBtn, findsOneWidget);
    await tester.ensureVisible(reserveBtn);
    await tester.tap(reserveBtn);
    await tester.pumpAndSettle();

    // 7. Vérification de la génération du code OTP et des consignes
    expect(find.text('Réservation au Comptoir Confirmée !'), findsOneWidget);
    expect(find.text('CODE DE RETRAIT COMPTOIR (OTP)'), findsOneWidget);
    expect(find.textContaining('RET-'), findsOneWidget);
    expect(find.textContaining('Valable pendant 02h 00m'), findsOneWidget);
  });
}
