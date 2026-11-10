import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/auth/data/models/pharmacist_profile_model.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';

void main() {
  const testModel = PharmacistProfileModel(
    userId: 'usr-pharma-042',
    pharmacyId: 'pharma-bastos-01',
    licenceOnpc: 'ONPC-2024-CMR-042',
    role: PharmacistRole.titulaire,
    fullName: 'Dr. Charles Kamga',
    email: 'pharmacist@afya.cm',
    telephone: '+237699001122',
    isVerified: true,
  );

  group('PharmacistProfileModel', () {
    test('is a subclass of PharmacistProfile entity', () {
      expect(testModel, isA<PharmacistProfile>());
    });

    test('fromJson deserializes valid JSON correctly', () {
      final json = <String, dynamic>{
        'user_id': 'usr-pharma-042',
        'pharmacy_id': 'pharma-bastos-01',
        'licence_onpc': 'ONPC-2024-CMR-042',
        'role': 'titulaire',
        'full_name': 'Dr. Charles Kamga',
        'email': 'pharmacist@afya.cm',
        'telephone': '+237699001122',
        'is_verified': true,
      };

      final result = PharmacistProfileModel.fromJson(json);

      expect(result, equals(testModel));
      expect(result.role, equals(PharmacistRole.titulaire));
      expect(result.licenceOnpc, equals('ONPC-2024-CMR-042'));
    });

    test('fromJson falls back to comptoir role when unknown role string is passed', () {
      final json = <String, dynamic>{
        'user_id': 'usr-pharma-999',
        'pharmacy_id': 'pharma-bastos-01',
        'licence_onpc': 'ONPC-2024-CMR-999',
        'role': 'stagiaire_inconnu',
        'full_name': 'Test User',
        'email': 'test@afya.cm',
        'telephone': '+237600000000',
        'is_verified': false,
      };

      final result = PharmacistProfileModel.fromJson(json);
      expect(result.role, equals(PharmacistRole.comptoir));
    });

    test('toJson serializes model correctly', () {
      final result = testModel.toJson();

      expect(result['user_id'], equals('usr-pharma-042'));
      expect(result['pharmacy_id'], equals('pharma-bastos-01'));
      expect(result['licence_onpc'], equals('ONPC-2024-CMR-042'));
      expect(result['role'], equals('titulaire'));
      expect(result['full_name'], equals('Dr. Charles Kamga'));
      expect(result['email'], equals('pharmacist@afya.cm'));
      expect(result['telephone'], equals('+237699001122'));
      expect(result['is_verified'], isTrue);
    });

    test('toDomain and fromDomain convert faithfully', () {
      final domain = testModel.toDomain();
      expect(domain, equals(testModel));

      final fromDomain = PharmacistProfileModel.fromDomain(domain);
      expect(fromDomain, equals(testModel));
    });

    test('copyWith produces updated instance with modified fields', () {
      final updated = testModel.copyWith(
        role: PharmacistRole.adjoint,
        isVerified: false,
      );

      expect(updated.role, equals(PharmacistRole.adjoint));
      expect(updated.isVerified, isFalse);
      expect(updated.userId, equals(testModel.userId));
    });
  });
}
