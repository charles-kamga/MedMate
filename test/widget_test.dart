import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/main.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Invariants Métier & Configuration Afya Santé', () {
    test('vérifie le nom officiel et la politique Zéro Prix Affiché', () {
      expect(AppConfig.appName, equals('Afya Santé'));
      expect(
        AppConfig.pricePolicyNotice,
        contains('ne fixe et n’affiche aucun prix'),
      );
    });

    test('vérifie la souveraineté cartographique OpenStreetMap (OSM)', () {
      expect(AppConfig.mapProviderName, equals('OpenStreetMap'));
      expect(
        AppConfig.osmFranceTileUrlTemplate,
        contains('tile.openstreetmap.fr/osmfr'),
      );
      expect(AppConfig.osmUserAgent, equals('cm.afyasante.app'));

      final searchUrl = AppConfig.buildOsmSearchUrl('Pharmacie Obili');
      expect(
        searchUrl,
        startsWith('https://www.openstreetmap.org/search?query='),
      );
      expect(searchUrl, contains('Yaound%C3%A9'));

      final pointUrl = AppConfig.buildOsmPointUrl(
        latitude: AppConfig.yaoundeLatitude,
        longitude: AppConfig.yaoundeLongitude,
      );
      expect(pointUrl, startsWith('https://www.openstreetmap.org/?mlat='));
    });

    test('vérifie le référentiel des repères urbains de Yaoundé', () {
      expect(YaoundeLandmarks.list, isNotEmpty);
      final quarters = YaoundeLandmarks.list.map((e) => e.quartier).toSet();
      expect(
        quarters,
        containsAll(['Poste Centrale', 'Bastos', 'Obili', 'Biyem-Assi']),
      );
    });

    test('vérifie l’égalité par valeur des Failures du domaine', () {
      const failureA = NetworkFailure();
      const failureB = NetworkFailure();
      const stockFailure = InsufficientStockFailure();

      expect(failureA, equals(failureB));
      expect(failureA, isNot(equals(stockFailure)));
    });
  });

  group('Tests Multi-Viewport Flutter Web & Mobile (Socle V0)', () {
    testWidgets(
      'affiche le socle sans débordement sur Viewport Mobile Patient (390x844)',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const AfyaSanteApp());
        await tester.pumpAndSettle();

        expect(find.text('Afya Santé'), findsOneWidget);
        expect(find.text('Mode Mobile Patient'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'affiche le socle sans débordement sur Viewport Desktop Comptoir (1280x800)',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const AfyaSanteApp());
        await tester.pumpAndSettle();

        expect(find.text('Afya Santé'), findsOneWidget);
        expect(find.text('Mode Desktop Comptoir'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
