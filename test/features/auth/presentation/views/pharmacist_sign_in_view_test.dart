import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medmate/core/theme/app_theme.dart';
import 'package:medmate/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:medmate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_cubit.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_state.dart';
import 'package:medmate/features/auth/presentation/views/pharmacist_sign_in_view.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

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

  Widget createTestWidget(AuthCubit cubit) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: BlocProvider<AuthCubit>.value(
          value: cubit,
          child: const PharmacistSignInView(),
        ),
      ),
    );
  }

  group('PharmacistSignInView Widget Tests (Mocked Cubit)', () {
    late MockAuthCubit mockCubit;

    setUp(() {
      mockCubit = MockAuthCubit();
    });

    testWidgets(
      'affiche le formulaire initial de connexion avec tous ses champs et labels',
      (tester) async {
        when(() => mockCubit.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createTestWidget(mockCubit));
        await tester.pumpAndSettle();

        expect(find.text('Espace Pro Pharmacien'), findsOneWidget);
        expect(
          find.text('Connexion d’officine homologuée ONPC · Yaoundé'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('pharmacist_email_field')), findsOneWidget);
        expect(
          find.byKey(const Key('pharmacist_password_field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('password_visibility_toggle')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('pharmacist_sign_in_button')),
          findsOneWidget,
        );
        expect(find.text('Se connecter au comptoir'), findsOneWidget);
        expect(
          find.text('Comptes de test : pharmacist@afya.cm / Afya2026!'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'bascule la visibilité du mot de passe lors de l’appui sur l’icône oeil',
      (tester) async {
        when(() => mockCubit.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createTestWidget(mockCubit));
        await tester.pumpAndSettle();

        // Par défaut, le mot de passe est masqué
        final passwordFieldInitial = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('pharmacist_password_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordFieldInitial.obscureText, isTrue);

        // Appui sur le toggle de visibilité
        await tester.tap(find.byKey(const Key('password_visibility_toggle')));
        await tester.pumpAndSettle();

        final passwordFieldVisible = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('pharmacist_password_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordFieldVisible.obscureText, isFalse);

        // Ré-appui pour masquer
        await tester.tap(find.byKey(const Key('password_visibility_toggle')));
        await tester.pumpAndSettle();

        final passwordFieldHiddenAgain = tester.widget<TextField>(
          find.descendant(
            of: find.byKey(const Key('pharmacist_password_field')),
            matching: find.byType(TextField),
          ),
        );
        expect(passwordFieldHiddenAgain.obscureText, isTrue);
      },
    );

    testWidgets(
      'affiche des messages de validation lorsque les champs sont vides',
      (tester) async {
        when(() => mockCubit.state).thenReturn(const AuthInitial());

        await tester.pumpWidget(createTestWidget(mockCubit));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('pharmacist_sign_in_button')));
        await tester.pumpAndSettle();

        expect(
          find.text('Veuillez saisir votre identifiant ou email'),
          findsOneWidget,
        );
        verifyNever(() => mockCubit.signInPharmacist(any(), any()));
      },
    );

    testWidgets(
      'appelle signInPharmacist avec les valeurs saisies',
      (tester) async {
        when(() => mockCubit.state).thenReturn(const AuthInitial());
        when(
          () => mockCubit.signInPharmacist(
            'pharmacist@afya.cm',
            'Afya2026!',
          ),
        ).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget(mockCubit));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('pharmacist_email_field')),
          'pharmacist@afya.cm',
        );
        await tester.enterText(
          find.byKey(const Key('pharmacist_password_field')),
          'Afya2026!',
        );
        await tester.tap(find.byKey(const Key('pharmacist_sign_in_button')));
        await tester.pump();

        verify(
          () => mockCubit.signInPharmacist(
            'pharmacist@afya.cm',
            'Afya2026!',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'affiche l’indicateur de chargement en état AuthLoading',
      (tester) async {
        when(() => mockCubit.state).thenReturn(const AuthLoading());

        await tester.pumpWidget(createTestWidget(mockCubit));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'affiche la bannière d’erreur en état AuthError',
      (tester) async {
        when(() => mockCubit.state).thenReturn(
          const AuthError('Mot de passe erroné'),
        );

        await tester.pumpWidget(createTestWidget(mockCubit));
        await tester.pumpAndSettle();

        expect(find.text('Mot de passe erroné'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      },
    );

    testWidgets(
      'affiche le profil connecté et déclenche signOut lors de l’appui sur déconnexion',
      (tester) async {
        when(() => mockCubit.state).thenReturn(
          const AuthenticatedPharmacist(tPharmacist),
        );
        when(() => mockCubit.signOut()).thenAnswer((_) async {});

        await tester.pumpWidget(createTestWidget(mockCubit));
        await tester.pumpAndSettle();

        expect(find.text('Dr. Charles Kamga'), findsOneWidget);
        expect(find.text('ONPC-2024-CMR-042'), findsOneWidget);
        expect(find.text('pharma-bastos-01'), findsOneWidget);
        expect(find.text('TITULAIRE'), findsOneWidget);
        expect(find.text('pharmacist@afya.cm'), findsOneWidget);
        expect(find.text('+237699001122'), findsOneWidget);

        expect(
          find.byKey(const Key('pharmacist_sign_out_button')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('pharmacist_sign_out_button')));
        await tester.pump();

        verify(() => mockCubit.signOut()).called(1);
      },
    );
  });

  group('PharmacistSignInView Integration with Real Repository', () {
    testWidgets(
      'authentifie avec succès le compte homologué de référence puis se déconnecte',
      (tester) async {
        final realDataSource = AuthLocalDataSourceImpl();
        final realRepo = AuthRepositoryImpl(localDataSource: realDataSource);
        final realCubit = AuthCubit(authRepository: realRepo);

        await tester.pumpWidget(createTestWidget(realCubit));
        await tester.pumpAndSettle();

        // Saisie des identifiants valides de référence
        await tester.enterText(
          find.byKey(const Key('pharmacist_email_field')),
          'pharmacist@afya.cm',
        );
        await tester.enterText(
          find.byKey(const Key('pharmacist_password_field')),
          'Afya2026!',
        );
        await tester.tap(find.byKey(const Key('pharmacist_sign_in_button')));
        await tester.pumpAndSettle();

        // Vérification de l'état authentifié
        expect(find.text('Dr. Charles Kamga'), findsOneWidget);
        expect(find.text('ONPC-2024-CMR-042'), findsOneWidget);

        // Déconnexion
        await tester.tap(find.byKey(const Key('pharmacist_sign_out_button')));
        await tester.pumpAndSettle();

        // Retour au formulaire
        expect(find.text('Espace Pro Pharmacien'), findsOneWidget);
        expect(find.byKey(const Key('pharmacist_sign_in_button')), findsOneWidget);

        await realCubit.close();
      },
    );
  });
}
