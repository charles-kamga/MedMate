import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/features/auth/data/models/patient_session_model.dart';
import 'package:medmate/features/auth/data/models/pharmacist_profile_model.dart';
import 'package:medmate/features/auth/data/models/user_session_model.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:uuid/uuid.dart';

/// Contrat de la source de données locale pour l'authentification et les sessions.
abstract class AuthLocalDataSource {
  /// Récupère la session courante en mémoire (ou en crée une anonyme si vide).
  Future<UserSessionModel> getCurrentSession();

  /// Authentifie un pharmacien d'officine avec email et mot de passe.
  Future<UserSessionModel> signInPharmacist(String email, String password);

  /// Révoque la session active en cours.
  Future<void> signOut();

  /// Récupère ou crée une session patient (anonyme ou avec téléphone).
  Future<PatientSessionModel> getOrCreatePatientSession({String? phoneNumber});
}

/// Implémentation en mémoire de la source de données locale d'authentification.
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final Uuid _uuid;
  UserSessionModel? _currentSession;

  /// Comptes de référence homologués par l'ONPC pour les officines de Yaoundé.
  static final Map<String, _PharmacistCredential> _seededCredentials = {
    'pharmacist@afya.cm': const _PharmacistCredential(
      password: 'Afya2026!',
      profile: PharmacistProfileModel(
        userId: 'usr-pharma-042',
        pharmacyId: 'pharma-bastos-01',
        licenceOnpc: 'ONPC-2024-CMR-042',
        role: PharmacistRole.titulaire,
        fullName: 'Dr. Charles Kamga',
        email: 'pharmacist@afya.cm',
        telephone: '+237699001122',
        isVerified: true,
      ),
    ),
    'adjoint.bastos@afya.cm': const _PharmacistCredential(
      password: 'Afya2026!',
      profile: PharmacistProfileModel(
        userId: 'usr-pharma-043',
        pharmacyId: 'pharma-bastos-01',
        licenceOnpc: 'ONPC-2024-CMR-043',
        role: PharmacistRole.adjoint,
        fullName: 'Dr. Madeleine Ngu',
        email: 'adjoint.bastos@afya.cm',
        telephone: '+237677334455',
        isVerified: true,
      ),
    ),
  };

  @override
  Future<UserSessionModel> getCurrentSession() async {
    if (_currentSession != null && _currentSession!.isActive) {
      return _currentSession!;
    }

    final now = DateTime.now();
    final patientSession = PatientSessionModel(
      sessionId: _uuid.v4(),
      createdAt: now,
      lastActiveAt: now,
    );

    _currentSession = UserSessionModel(
      sessionId: _uuid.v4(),
      createdAt: now,
      patientSession: patientSession,
      isActive: true,
    );

    return _currentSession!;
  }

  @override
  Future<UserSessionModel> signInPharmacist(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = _seededCredentials[normalizedEmail];

    if (credential == null || credential.password != password) {
      throw const AuthException('Identifiants invalides ou mot de passe incorrect.');
    }

    final now = DateTime.now();
    final session = UserSessionModel(
      sessionId: _uuid.v4(),
      createdAt: now,
      pharmacistProfile: credential.profile,
      isActive: true,
    );

    _currentSession = session;
    return session;
  }

  @override
  Future<void> signOut() async {
    _currentSession = null;
  }

  @override
  Future<PatientSessionModel> getOrCreatePatientSession({String? phoneNumber}) async {
    final now = DateTime.now();
    final current = _currentSession;

    if (current != null && current.patientSession != null && current.isActive) {
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
        final updatedPatient = PatientSessionModel(
          sessionId: current.patientSession!.sessionId,
          phoneNumber: phoneNumber.trim(),
          createdAt: current.patientSession!.createdAt,
          lastActiveAt: now,
        );

        _currentSession = current.copyWith(
          patientSession: updatedPatient,
        );

        return updatedPatient;
      }
      return PatientSessionModel.fromDomain(current.patientSession!);
    }

    final newPatient = PatientSessionModel(
      sessionId: _uuid.v4(),
      phoneNumber: (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          ? phoneNumber.trim()
          : null,
      createdAt: now,
      lastActiveAt: now,
    );

    _currentSession = UserSessionModel(
      sessionId: _uuid.v4(),
      createdAt: now,
      patientSession: newPatient,
      isActive: true,
    );

    return newPatient;
  }
}

class _PharmacistCredential {
  const _PharmacistCredential({
    required this.password,
    required this.profile,
  });

  final String password;
  final PharmacistProfileModel profile;
}
