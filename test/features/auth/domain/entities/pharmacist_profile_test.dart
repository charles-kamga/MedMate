import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';

void main() {
  group('PharmacistProfile Entity', () {
    const profileA = PharmacistProfile(
      userId: 'user-pharma-1',
      pharmacyId: 'pharma-bastos-1',
      licenceOnpc: 'ONPC-CMR-8472',
      role: PharmacistRole.titulaire,
      fullName: 'Dr. Amadou Bello',
      email: 'amadou.bello@afyasante.cm',
      telephone: '+237699001122',
      isVerified: true,
    );

    const profileB = PharmacistProfile(
      userId: 'user-pharma-1',
      pharmacyId: 'pharma-bastos-1',
      licenceOnpc: 'ONPC-CMR-8472',
      role: PharmacistRole.titulaire,
      fullName: 'Dr. Amadou Bello',
      email: 'amadou.bello@afyasante.cm',
      telephone: '+237699001122',
      isVerified: true,
    );

    const profileOther = PharmacistProfile(
      userId: 'user-pharma-2',
      pharmacyId: 'pharma-mokolo-1',
      licenceOnpc: 'ONPC-CMR-9901',
      role: PharmacistRole.adjoint,
      fullName: 'Dr. Chantal Ngo',
      email: 'chantal.ngo@afyasante.cm',
      telephone: '+237677889900',
      isVerified: false,
    );

    test('supports value equality via props', () {
      expect(profileA, equals(profileB));
      expect(profileA, isNot(equals(profileOther)));
      expect(profileA.props, [
        'user-pharma-1',
        'pharma-bastos-1',
        'ONPC-CMR-8472',
        PharmacistRole.titulaire,
        'Dr. Amadou Bello',
        'amadou.bello@afyasante.cm',
        '+237699001122',
        true,
      ]);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = profileA.copyWith(
        role: PharmacistRole.gerant,
        isVerified: false,
      );

      expect(updated.userId, equals('user-pharma-1'));
      expect(updated.pharmacyId, equals('pharma-bastos-1'));
      expect(updated.role, equals(PharmacistRole.gerant));
      expect(updated.isVerified, isFalse);
      expect(updated.fullName, equals('Dr. Amadou Bello'));
    });

    test('contains all ONPC recognized roles', () {
      expect(
        PharmacistRole.values,
        containsAll([
          PharmacistRole.titulaire,
          PharmacistRole.adjoint,
          PharmacistRole.gerant,
          PharmacistRole.comptoir,
        ]),
      );
    });
  });
}
