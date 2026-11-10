import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:medmate/features/auth/domain/usecases/sign_in_pharmacist_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInPharmacistUseCase useCase;
  late MockAuthRepository mockRepository;

  const testProfile = PharmacistProfile(
    userId: 'user-pharma-1',
    pharmacyId: 'pharma-bastos-1',
    licenceOnpc: 'ONPC-CMR-8472',
    role: PharmacistRole.titulaire,
    fullName: 'Dr. Amadou Bello',
    email: 'amadou.bello@afyasante.cm',
    telephone: '+237699001122',
    isVerified: true,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInPharmacistUseCase(mockRepository);
  });

  group('SignInPharmacistUseCase', () {
    test('returns Right(PharmacistProfile) on valid email and password',
        () async {
      when(
        () => mockRepository.signInPharmacist(
          email: 'amadou.bello@afyasante.cm',
          password: 'securePassword123',
        ),
      ).thenAnswer((_) async => const Right(testProfile));

      final result = await useCase(
        const SignInPharmacistParams(
          email: ' amadou.bello@afyasante.cm ',
          password: 'securePassword123',
        ),
      );

      expect(result, equals(const Right<Failure, PharmacistProfile>(testProfile)));
      verify(
        () => mockRepository.signInPharmacist(
          email: 'amadou.bello@afyasante.cm',
          password: 'securePassword123',
        ),
      ).called(1);
    });

    test('returns Left(AuthFailure) when email is empty', () async {
      final result = await useCase(
        const SignInPharmacistParams(
          email: '   ',
          password: 'securePassword123',
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, PharmacistProfile>(
            AuthFailure('Adresse email invalide.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(AuthFailure) when email format does not contain @',
        () async {
      final result = await useCase(
        const SignInPharmacistParams(
          email: 'invalid-email-format',
          password: 'securePassword123',
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, PharmacistProfile>(
            AuthFailure('Adresse email invalide.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(AuthFailure) when password is shorter than 6 characters',
        () async {
      final result = await useCase(
        const SignInPharmacistParams(
          email: 'test@afyasante.cm',
          password: '12345',
        ),
      );

      expect(
        result,
        equals(
          const Left<Failure, PharmacistProfile>(
            AuthFailure(
              'Le mot de passe doit comporter au moins 6 caractères.',
            ),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(AuthFailure) when repository returns credentials error',
        () async {
      const authFailure = AuthFailure('Identifiants invalides');
      when(
        () => mockRepository.signInPharmacist(
          email: 'test@afyasante.cm',
          password: 'wrongPassword123',
        ),
      ).thenAnswer((_) async => const Left(authFailure));

      final result = await useCase(
        const SignInPharmacistParams(
          email: 'test@afyasante.cm',
          password: 'wrongPassword123',
        ),
      );

      expect(
        result,
        equals(const Left<Failure, PharmacistProfile>(authFailure)),
      );
      verify(
        () => mockRepository.signInPharmacist(
          email: 'test@afyasante.cm',
          password: 'wrongPassword123',
        ),
      ).called(1);
    });
  });
}
