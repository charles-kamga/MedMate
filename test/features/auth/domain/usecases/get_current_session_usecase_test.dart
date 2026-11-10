import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/core/usecases/no_params.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:medmate/features/auth/domain/usecases/get_current_session_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentSessionUseCase useCase;
  late MockAuthRepository mockRepository;

  final now = DateTime(2026, 11, 9, 12);
  final testSession = UserSession(
    sessionId: 'session-xyz',
    createdAt: now,
    patientSession: PatientSession(
      sessionId: 'session-xyz',
      createdAt: now,
      lastActiveAt: now,
    ),
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = GetCurrentSessionUseCase(mockRepository);
  });

  group('GetCurrentSessionUseCase', () {
    test('returns Right(UserSession) when repository succeeds without params',
        () async {
      when(() => mockRepository.getCurrentSession()).thenAnswer(
        (_) async => Right(testSession),
      );

      final result = await useCase();

      expect(result, equals(Right<Failure, UserSession>(testSession)));
      verify(() => mockRepository.getCurrentSession()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('returns Right(UserSession) when called with explicit NoParams',
        () async {
      when(() => mockRepository.getCurrentSession()).thenAnswer(
        (_) async => Right(testSession),
      );

      final result = await useCase(const NoParams());

      expect(result, equals(Right<Failure, UserSession>(testSession)));
      verify(() => mockRepository.getCurrentSession()).called(1);
    });

    test('returns Left(AuthFailure) when repository fails', () async {
      const failure = AuthFailure('Session introuvable ou expirée.');
      when(() => mockRepository.getCurrentSession()).thenAnswer(
        (_) async => const Left(failure),
      );

      final result = await useCase();

      expect(result, equals(const Left<Failure, UserSession>(failure)));
      verify(() => mockRepository.getCurrentSession()).called(1);
    });
  });
}
