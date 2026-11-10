import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/reservation/data/models/item_availability_status_model.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';

void main() {
  group('ItemAvailabilityStatusModel', () {
    test('fromString parses valid and french status strings', () {
      expect(
        ItemAvailabilityStatusModel.fromString('available'),
        equals(ItemAvailabilityStatus.available),
      );
      expect(
        ItemAvailabilityStatusModel.fromString('disponible'),
        equals(ItemAvailabilityStatus.available),
      );
      expect(
        ItemAvailabilityStatusModel.fromString('unavailable'),
        equals(ItemAvailabilityStatus.unavailable),
      );
      expect(
        ItemAvailabilityStatusModel.fromString('indisponible'),
        equals(ItemAvailabilityStatus.unavailable),
      );
      expect(
        ItemAvailabilityStatusModel.fromString('conditional'),
        equals(ItemAvailabilityStatus.conditional),
      );
      expect(
        ItemAvailabilityStatusModel.fromString('conditionnel'),
        equals(ItemAvailabilityStatus.conditional),
      );
    });

    test('fromString defaults to unavailable on unknown string', () {
      expect(
        ItemAvailabilityStatusModel.fromString('unknown_status'),
        equals(ItemAvailabilityStatus.unavailable),
      );
    });

    test('toValue returns enum name', () {
      expect(
        ItemAvailabilityStatusModel.toValue(ItemAvailabilityStatus.available),
        equals('available'),
      );
      expect(
        ItemAvailabilityStatusModel.toValue(ItemAvailabilityStatus.unavailable),
        equals('unavailable'),
      );
      expect(
        ItemAvailabilityStatusModel.toValue(ItemAvailabilityStatus.conditional),
        equals('conditional'),
      );
    });
  });
}
