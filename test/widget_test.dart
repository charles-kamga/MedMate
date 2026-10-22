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
    // Render de l'application avec repository mocké (zéro appel réseau/timer)
    await tester.pumpWidget(
      MedMateApp(
        enableNetworkTiles: false,
        pharmacyRepository: mockRepository,
      ),
    );
    await tester.pump();

    // Vérification de la présence de la barre de navigation à 3 onglets
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Pharmacies'), findsOneWidget);
    expect(find.text('Médicaments'), findsOneWidget);
    expect(find.text('Mon Espace'), findsOneWidget);

    // Vérification des repères urbains de Yaoundé
    expect(find.text('Repères & Carrefours de Yaoundé'), findsOneWidget);
    expect(find.text('Carrefour Warda'), findsOneWidget);

    // Basculer vers l'onglet Catalogue pour valider l'interactivité
    await tester.tap(find.text('Médicaments'));
    await tester.pump();

    expect(find.text('Catalogue & Disponibilité'), findsOneWidget);

    // Basculer vers l'onglet Mon Espace pour valider l'authentification
    await tester.tap(find.text('Mon Espace'));
    await tester.pump();

    expect(find.text('Espace Patient & Sécurité'), findsOneWidget);
    expect(find.text('Connexion Rapide par SMS OTP'), findsOneWidget);
  });
}
