import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user_session.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthInitial()) {
    on<SendOtpTriggered>(_onSendOtp);
    on<VerifyOtpTriggered>(_onVerifyOtp);
    on<ContinueAsGuestTriggered>(_onContinueAsGuest);
    on<SignOutTriggered>(_onSignOut);
  }

  Future<void> _onSendOtp(SendOtpTriggered event, Emitter<AuthState> emit) async {
    final phone = event.telephone.trim();
    if (phone.length < 9) {
      emit(const AuthError('Veuillez entrer un numéro de téléphone camerounais valide (ex: 699112233).'));
      return;
    }

    emit(const AuthLoading());
    // Simulation / Appel passerelle Supabase OTP Phone
    await Future<void>.delayed(const Duration(milliseconds: 600));
    emit(AuthOtpSent(phone));
  }

  Future<void> _onVerifyOtp(VerifyOtpTriggered event, Emitter<AuthState> emit) async {
    final code = event.codeOtp.trim();
    if (code.length != 6) {
      emit(const AuthError('Le code de vérification SMS doit comporter 6 chiffres.'));
      return;
    }

    emit(const AuthLoading());
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final session = UserSession(
      userId: 'user-${DateTime.now().millisecondsSinceEpoch}',
      telephone: event.telephone,
      estAuthentifie: true,
      nomComplet: 'Patient MedMate (${event.telephone})',
    );
    emit(AuthAuthenticated(session));
  }

  void _onContinueAsGuest(ContinueAsGuestTriggered event, Emitter<AuthState> emit) {
    emit(AuthGuest(UserSession.guest()));
  }

  void _onSignOut(SignOutTriggered event, Emitter<AuthState> emit) {
    emit(const AuthInitial());
  }
}
