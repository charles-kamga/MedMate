import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/reservation/presentation/widgets/yango_pulse_flash_button.dart';

void main() {
  const sampleLandmark = YaoundeLandmark(
    id: 'carrefour-warda',
    nom: 'Carrefour Warda',
    quartier: 'Poste Centrale',
    arrondissement: 'Yaoundé 1er',
    latitude: 3.8688,
    longitude: 11.5175,
    description: 'Face au Bois Sainte-Anastasie',
  );

  Widget buildTestableWidget({
    required int itemCount,
    required YaoundeLandmark? landmark,
    required VoidCallback? onPressed,
    bool isLoading = false,
    bool enableAnimation = false,
    String label = 'Lancer la recherche Flash',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: YangoPulseFlashButton(
            itemCount: itemCount,
            landmark: landmark,
            onPressed: onPressed,
            isLoading: isLoading,
            enableAnimation: enableAnimation,
            label: label,
          ),
        ),
      ),
    );
  }

  group('YangoPulseFlashButton Widget Tests', () {
    testWidgets('pumpAndSettle settles immediately when enableAnimation is false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          itemCount: 2,
          landmark: sampleLandmark,
          onPressed: () {},
          enableAnimation: false,
        ),
      );

      // Must settle immediately without timing out
      await tester.pumpAndSettle();
      expect(find.text('Lancer la recherche Flash'), findsOneWidget);
      expect(find.text('2 médicaments • Carrefour Warda'), findsOneWidget);
    });

    testWidgets('shows warning subtitle and does not trigger onPressed when basket is empty', (tester) async {
      var wasPressed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          itemCount: 0,
          landmark: sampleLandmark,
          onPressed: () => wasPressed = true,
          enableAnimation: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ajoutez au moins 1 médicament au panier'), findsOneWidget);
      await tester.tap(find.byType(YangoPulseFlashButton));
      await tester.pumpAndSettle();

      expect(wasPressed, isFalse);
    });

    testWidgets('shows warning subtitle when landmark is missing', (tester) async {
      var wasPressed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          itemCount: 1,
          landmark: null,
          onPressed: () => wasPressed = true,
          enableAnimation: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sélectionnez un carrefour ou quartier'), findsOneWidget);
      await tester.tap(find.byType(YangoPulseFlashButton));
      await tester.pumpAndSettle();

      expect(wasPressed, isFalse);
    });

    testWidgets('triggers onPressed when enabled and tapped', (tester) async {
      var wasPressed = false;
      await tester.pumpWidget(
        buildTestableWidget(
          itemCount: 1,
          landmark: sampleLandmark,
          onPressed: () => wasPressed = true,
          enableAnimation: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 médicament • Carrefour Warda'), findsOneWidget);
      await tester.tap(find.byType(YangoPulseFlashButton));
      await tester.pumpAndSettle();

      expect(wasPressed, isTrue);
    });

    testWidgets('shows circular progress indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          itemCount: 2,
          landmark: sampleLandmark,
          onPressed: () {},
          isLoading: true,
          enableAnimation: false,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Lancer la recherche Flash'), findsNothing);
    });
  });
}
