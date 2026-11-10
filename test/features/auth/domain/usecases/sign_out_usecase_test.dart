import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/core/usecases/no_params.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:medmate/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOutUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignOutUseCase(mockRepository);
  });

  group('SignOutUseCase', () {
    test('returns Right(null) when repository signOut succeeds without params',
        () async {
      when(() => mockRepository.signOut()).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await useCase();

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockRepository.signOut()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns Right(null) when called with explicit NoParams', () async {
      when(() => mockRepository.signOut()).thenAnswer(
        (_) async => const Right(null),
      );

      final result = await useCase(const NoParams());

      expect(result, equals(const Right<Failure, void>(null)));
      verify(() => mockRepository.signOut()).called(1);
    });

    test('returns Left(StorageFailure) when repository signOut fails',
        () async {
      const failure = StorageFailure("Impossible d'effacer le token de session.");
      when(() => mockRepository.signOut()).thenAnswer(
        (_) async => const Left(failure),
      );

      final result = await useCase();

      expect(result, equals(const Left<Failure, void>(failure)));
      verify(() => mockRepository.signOut()).called(1);
    });
  });
}
