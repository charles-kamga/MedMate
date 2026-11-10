import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medmate/features/auth/domain/repositories/auth_repository.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_state.dart';

/// Contrôleur BLoC (Cubit) pour la gestion d'état d'authentification Afya Santé.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial());

  final AuthRepository _authRepository;

  /// Vérifie la session active actuelle au démarrage ou au focus de l'application.
  Future<void> checkCurrentSession() async {
    emit(const AuthLoading());
    final result = await _authRepository.getCurrentSession();
    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (session) {
        if (session.isPharmacist && session.pharmacistProfile != null) {
          emit(AuthenticatedPharmacist(session.pharmacistProfile!));
        } else if (session.isPatient && session.patientSession != null) {
          emit(AuthenticatedPatient(session.patientSession!));
        } else {
          emit(const AuthUnauthenticated());
        }
      },
    );
  }

  /// Authentifie un pharmacien d'officine auprès de l'ONPC avec email et mot de passe.
  Future<void> signInPharmacist(String email, String password) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      emit(const AuthError('Veuillez renseigner votre adresse email professionnelle.'));
      return;
    }
    if (!trimmedEmail.contains('@')) {
      emit(const AuthError('Adresse email invalide.'));
      return;
    }
    if (password.isEmpty) {
      emit(const AuthError('Veuillez renseigner votre mot de passe.'));
      return;
    }

    emit(const AuthLoading());
    final result = await _authRepository.signInPharmacist(
      email: trimmedEmail,
      password: password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (pharmacist) => emit(AuthenticatedPharmacist(pharmacist)),
    );
  }

  /// Déconnecte l'utilisateur en cours et révoque sa session locale.
  Future<void> signOut() async {
    emit(const AuthLoading());
    final result = await _authRepository.signOut();
    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  /// Initialise ou bascule vers une session patient éphémère.
  Future<void> initPatientSession({String? phoneNumber}) async {
    emit(const AuthLoading());
    final result = await _authRepository.getOrCreatePatientSession(
      phoneNumber: phoneNumber,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message, code: failure.code)),
      (patientSession) => emit(AuthenticatedPatient(patientSession)),
    );
  }
}
