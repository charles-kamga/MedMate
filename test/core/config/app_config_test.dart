import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test("buildOsmSearchUrl génère l'URL conforme OpenStreetMap", () {
      final url = AppConfig.buildOsmSearchUrl(
        latitude: 3.8688,
        longitude: 11.5175,
      );

      expect(url, 'https://www.openstreetmap.org/?mlat=3.8688&mlon=11.5175#map=16/3.8688/11.5175');
    });

    test('buildOsmSearchUrl accepte un label optionnel', () {
      final url = AppConfig.buildOsmSearchUrl(
        latitude: 3.8667,
        longitude: 11.5200,
        label: 'Poste Centrale',
      );

      expect(url, contains('mlat=3.8667'));
      expect(url, contains('mlon=11.52'));
      expect(url, contains('#map=16/3.8667/11.52'));
    });
  });
}
