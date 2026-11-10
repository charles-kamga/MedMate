import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:medmate/features/auth/data/models/patient_session_model.dart';
import 'package:medmate/features/auth/data/models/pharmacist_profile_model.dart';
import 'package:medmate/features/auth/data/models/user_session_model.dart';
import 'package:medmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthLocalDataSource mockDataSource;

  final testDate = DateTime(2026, 11, 9, 10, 0, 0);

  final testPatientModel = PatientSessionModel(
    sessionId: 'sess-pat-01',
    phoneNumber: '+237699112233',
    createdAt: testDate,
    lastActiveAt: testDate,
  );

  const testPharmacistModel = PharmacistProfileModel(
    userId: 'usr-pharma-042',
    pharmacyId: 'pharma-bastos-01',
    licenceOnpc: 'ONPC-2024-CMR-042',
    role: PharmacistRole.titulaire,
    fullName: 'Dr. Charles Kamga',
    email: 'pharmacist@afya.cm',
    telephone: '+237699001122',
    isVerified: true,
  );

  final testUserSessionModel = UserSessionModel(
    sessionId: 'sess-user-01',
    createdAt: testDate,
    pharmacistProfile: testPharmacistModel,
    isActive: true,
  );

  setUp(() {
    mockDataSource = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(localDataSource: mockDataSource);
  });

  group('AuthRepositoryImpl', () {
    group('getCurrentSession', () {
      test('returns Right(UserSession) on success', () async {
        when(() => mockDataSource.getCurrentSession())
            .thenAnswer((_) async => testUserSessionModel);

        final result = await repository.getCurrentSession();

        expect(result, equals(Right<Failure, UserSession>(testUserSessionModel)));
        verify(() => mockDataSource.getCurrentSession()).called(1);
      });

      test('returns Left(CacheFailure) when CacheException is thrown', () async {
        when(() => mockDataSource.getCurrentSession())
            .thenThrow(const CacheException('Stockage inaccessible'));

        final result = await repository.getCurrentSession();

        expect(
          result,
          equals(const Left<Failure, UserSession>(CacheFailure('Stockage inaccessible'))),
        );
      });

      test('returns Left(ServerFailure) on general exception', () async {
        when(() => mockDataSource.getCurrentSession())
            .thenThrow(Exception('Erreur inattendue'));

        final result = await repository.getCurrentSession();

        expect(
          result.isLeft(),
          isTrue,
        );
      });
    });

    group('signInPharmacist', () {
      test('returns Right(PharmacistProfile) on valid authentication', () async {
        when(() => mockDataSource.signInPharmacist('pharmacist@afya.cm', 'Afya2026!'))
            .thenAnswer((_) async => testUserSessionModel);

        final result = await repository.signInPharmacist(
          email: 'pharmacist@afya.cm',
          password: 'Afya2026!',
        );

        expect(
          result,
          equals(const Right<Failure, PharmacistProfile>(testPharmacistModel)),
        );
        verify(() => mockDataSource.signInPharmacist('pharmacist@afya.cm', 'Afya2026!'))
            .called(1);
      });

      test('returns Left(AuthFailure) when AuthException is thrown', () async {
        when(() => mockDataSource.signInPharmacist(any(), any()))
            .thenThrow(const AuthException('Identifiants incorrects.'));

        final result = await repository.signInPharmacist(
          email: 'wrong@afya.cm',
          password: 'bad',
        );

        expect(
          result,
          equals(const Left<Failure, PharmacistProfile>(AuthFailure('Identifiants incorrects.'))),
        );
      });

      test('returns Left(AuthFailure) when pharmacistProfile is null in returned session', () async {
        final sessionWithoutProfile = UserSessionModel(
          sessionId: 'sess-empty',
          createdAt: testDate,
        );
        when(() => mockDataSource.signInPharmacist(any(), any()))
            .thenAnswer((_) async => sessionWithoutProfile);

        final result = await repository.signInPharmacist(
          email: 'pharmacist@afya.cm',
          password: 'Afya2026!',
        );

        expect(
          result,
          equals(
            const Left<Failure, PharmacistProfile>(
              AuthFailure('Profil pharmacien introuvable dans la session.'),
            ),
          ),
        );
      });
    });

    group('signOut', () {
      test('returns Right(null) when signOut succeeds', () async {
        when(() => mockDataSource.signOut()).thenAnswer((_) async {});

        final result = await repository.signOut();

        expect(result, equals(const Right<Failure, void>(null)));
        verify(() => mockDataSource.signOut()).called(1);
      });

      test('returns Left(ServerFailure) when signOut throws', () async {
        when(() => mockDataSource.signOut()).thenThrow(Exception('Fail'));

        final result = await repository.signOut();

        expect(result.isLeft(), isTrue);
      });
    });

    group('getOrCreatePatientSession', () {
      test('returns Right(PatientSession) on success', () async {
        when(() => mockDataSource.getOrCreatePatientSession(phoneNumber: any(named: 'phoneNumber')))
            .thenAnswer((_) async => testPatientModel);

        final result = await repository.getOrCreatePatientSession(
          phoneNumber: '+237699112233',
        );

        expect(result, equals(Right<Failure, PatientSession>(testPatientModel)));
        verify(() => mockDataSource.getOrCreatePatientSession(phoneNumber: '+237699112233'))
            .called(1);
      });

      test('returns Left(ServerFailure) on exception', () async {
        when(() => mockDataSource.getOrCreatePatientSession(phoneNumber: any(named: 'phoneNumber')))
            .thenThrow(Exception('Storage error'));

        final result = await repository.getOrCreatePatientSession();

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
