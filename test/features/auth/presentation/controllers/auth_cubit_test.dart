import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/domain/entities/user_session.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_cubit.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late AuthCubit cubit;

  final tDate = DateTime(2026, 4, 17, 10);

  const tPharmacist = PharmacistProfile(
    userId: 'usr-pharma-042',
    pharmacyId: 'pharma-bastos-01',
    licenceOnpc: 'ONPC-2024-CMR-042',
    role: PharmacistRole.titulaire,
    fullName: 'Dr. Charles Kamga',
    email: 'pharmacist@afya.cm',
    telephone: '+237699001122',
    isVerified: true,
  );

  final tPatient = PatientSession(
    sessionId: 'session-patient-001',
    createdAt: tDate,
    lastActiveAt: tDate,
  );

  final tPharmacistSession = UserSession(
    sessionId: 'sess-001',
    createdAt: tDate,
    pharmacistProfile: tPharmacist,
  );

  final tPatientSession = UserSession(
    sessionId: 'sess-002',
    createdAt: tDate,
    patientSession: tPatient,
  );

  final tEmptySession = UserSession(
    sessionId: 'sess-003',
    createdAt: tDate,
  );

  setUp(() {
    mockRepository = MockAuthRepository();
    cubit = AuthCubit(authRepository: mockRepository);
  });

  tearDown(() {
    cubit.close();
  });

  group('AuthCubit Initial State', () {
    test('l’état initial doit être AuthInitial()', () {
      expect(cubit.state, equals(const AuthInitial()));
    });
  });

  group('checkCurrentSession', () {
    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthenticatedPharmacist] quand la session active est un pharmacien',
      build: () {
        when(() => mockRepository.getCurrentSession()).thenAnswer(
          (_) async => Right(tPharmacistSession),
        );
        return cubit;
      },
      act: (c) => c.checkCurrentSession(),
      expect: () => [
        const AuthLoading(),
        const AuthenticatedPharmacist(tPharmacist),
      ],
      verify: (_) {
        verify(() => mockRepository.getCurrentSession()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthenticatedPatient] quand la session active est un patient',
      build: () {
        when(() => mockRepository.getCurrentSession()).thenAnswer(
          (_) async => Right(tPatientSession),
        );
        return cubit;
      },
      act: (c) => c.checkCurrentSession(),
      expect: () => [
        const AuthLoading(),
        AuthenticatedPatient(tPatient),
      ],
      verify: (_) {
        verify(() => mockRepository.getCurrentSession()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthUnauthenticated] quand la session n’a ni profil pharmacien ni session patient',
      build: () {
        when(() => mockRepository.getCurrentSession()).thenAnswer(
          (_) async => Right(tEmptySession),
        );
        return cubit;
      },
      act: (c) => c.checkCurrentSession(),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthError] quand getCurrentSession échoue',
      build: () {
        when(() => mockRepository.getCurrentSession()).thenAnswer(
          (_) async => const Left(AuthFailure('Erreur de session')),
        );
        return cubit;
      },
      act: (c) => c.checkCurrentSession(),
      expect: () => [
        const AuthLoading(),
        const AuthError('Erreur de session', code: 'AUTH_ERROR'),
      ],
    );
  });

  group('signInPharmacist', () {
    blocTest<AuthCubit, AuthState>(
      'émet [AuthError] si l’email est vide sans appeler le repository',
      build: () => cubit,
      act: (c) => c.signInPharmacist('', 'Afya2026!'),
      expect: () => [
        const AuthError(
          'Veuillez renseigner votre adresse email professionnelle.',
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepository.signInPharmacist(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthError] si l’email est invalide sans appeler le repository',
      build: () => cubit,
      act: (c) => c.signInPharmacist('invalid-email', 'Afya2026!'),
      expect: () => [
        const AuthError('Adresse email invalide.'),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepository.signInPharmacist(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthError] si le mot de passe est vide sans appeler le repository',
      build: () => cubit,
      act: (c) => c.signInPharmacist('pharmacist@afya.cm', ''),
      expect: () => [
        const AuthError('Veuillez renseigner votre mot de passe.'),
      ],
      verify: (_) {
        verifyNever(
          () => mockRepository.signInPharmacist(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthenticatedPharmacist] lors d’une connexion réussie',
      build: () {
        when(
          () => mockRepository.signInPharmacist(
            email: 'pharmacist@afya.cm',
            password: 'password123',
          ),
        ).thenAnswer((_) async => const Right(tPharmacist));
        return cubit;
      },
      act: (c) => c.signInPharmacist('  pharmacist@afya.cm  ', 'password123'),
      expect: () => [
        const AuthLoading(),
        const AuthenticatedPharmacist(tPharmacist),
      ],
      verify: (_) {
        verify(
          () => mockRepository.signInPharmacist(
            email: 'pharmacist@afya.cm',
            password: 'password123',
          ),
        ).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthError] lors d’un mot de passe ou email incorrect',
      build: () {
        when(
          () => mockRepository.signInPharmacist(
            email: 'pharmacist@afya.cm',
            password: 'wrong',
          ),
        ).thenAnswer(
          (_) async => const Left(AuthFailure('Identifiants invalides')),
        );
        return cubit;
      },
      act: (c) => c.signInPharmacist('pharmacist@afya.cm', 'wrong'),
      expect: () => [
        const AuthLoading(),
        const AuthError('Identifiants invalides', code: 'AUTH_ERROR'),
      ],
    );
  });

  group('signOut', () {
    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthUnauthenticated] lors d’une déconnexion réussie',
      build: () {
        when(() => mockRepository.signOut())
            .thenAnswer((_) async => const Right(null));
        return cubit;
      },
      act: (c) => c.signOut(),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
      verify: (_) {
        verify(() => mockRepository.signOut()).called(1);
      },
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthError] en cas d’échec de déconnexion',
      build: () {
        when(() => mockRepository.signOut()).thenAnswer(
          (_) async => const Left(ServerFailure('Erreur serveur déconnexion')),
        );
        return cubit;
      },
      act: (c) => c.signOut(),
      expect: () => [
        const AuthLoading(),
        const AuthError('Erreur serveur déconnexion', code: 'SERVER_ERROR'),
      ],
    );
  });

  group('initPatientSession', () {
    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthenticatedPatient] lors de l’initialisation de session patient',
      build: () {
        when(
          () => mockRepository.getOrCreatePatientSession(
            phoneNumber: any(named: 'phoneNumber'),
          ),
        ).thenAnswer((_) async => Right(tPatient));
        return cubit;
      },
      act: (c) => c.initPatientSession(phoneNumber: '+237699112233'),
      expect: () => [
        const AuthLoading(),
        AuthenticatedPatient(tPatient),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'émet [AuthLoading, AuthError] lors d’un échec d’initialisation de session patient',
      build: () {
        when(
          () => mockRepository.getOrCreatePatientSession(
            phoneNumber: any(named: 'phoneNumber'),
          ),
        ).thenAnswer(
          (_) async => const Left(ServerFailure('Impossible d’initialiser')),
        );
        return cubit;
      },
      act: (c) => c.initPatientSession(),
      expect: () => [
        const AuthLoading(),
        const AuthError('Impossible d’initialiser', code: 'SERVER_ERROR'),
      ],
    );
  });
}
