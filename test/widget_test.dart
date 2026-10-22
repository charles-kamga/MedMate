import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/main.dart';

void main() {
  testWidgets('Smoke test affichage de la page d''accueil MedMate', (WidgetTester tester) async {
    // Render de l'application
    await tester.pumpWidget(const MedMateApp());

    // Vérification de la présence du titre et des repères
    expect(find.text('MedMate — Pharmacies Yaoundé'), findsOneWidget);
    expect(find.text('Repères Urbains de Yaoundé'), findsOneWidget);
    expect(find.text('Carrefour Warda'), findsOneWidget);
  });
}
