import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/user_session.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Vue d'authentification et gestion du profil (Patient ou Pharmacien Partenaire)
class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _phoneController = TextEditingController(text: '699112233');
  final _otpController = TextEditingController();

  UserRole _selectedRole = UserRole.patient;
  int _selectedPharmacyIndex = 0;

  // Profils officines de référence (Section 5 du CDC)
  static const List<PharmacyStaffProfile> _partnerPharmacies = [
    PharmacyStaffProfile(
      pharmacyId: 'pharma-soleil',
      pharmacyName: 'Pharmacie du Soleil',
      licenceOnpc: 'ONPC-YDE-0105',
      responsable: 'Dr. Aïcha Bello (Titulaire)',
      quarter: 'Carrefour Warda',
      telephone: '+237 677 12 34 56',
      estDeGarde: false,
    ),
    PharmacyStaffProfile(
      pharmacyId: 'pharma-centre',
      pharmacyName: 'Grande Pharmacie du Centre',
      licenceOnpc: 'ONPC-YDE-0042',
      responsable: 'Dr. Jean Mballa (Titulaire)',
      quarter: 'Poste Centrale',
      telephone: '+237 699 88 77 66',
      estDeGarde: true,
    ),
    PharmacyStaffProfile(
      pharmacyId: 'pharma-obili',
      pharmacyName: "Pharmacie d'Obili",
      licenceOnpc: 'ONPC-YDE-0211',
      responsable: 'Dr. Paul Biye (Titulaire)',
      quarter: 'Carrefour Obili',
      telephone: '+237 655 44 33 22',
      estDeGarde: true,
    ),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.alert,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Compte & Authentification'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (state is AuthAuthenticated || state is AuthGuest) ...[
                _buildConnectedProfileCard(context, state),
              ] else ...[
                _buildRoleSelector(),
                const SizedBox(height: 20),
                if (_selectedRole == UserRole.patient) ...[
                  _buildHeaderCard(
                    title: 'Espace Patient Afya Santé',
                    subtitle: 'Recherchez sans engagement. Vos données de santé restent anonymes et chiffrées.',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),
                  if (state is AuthOtpSent) ...[
                    _buildOtpInputCard(context, state.telephone),
                  ] else ...[
                    _buildPhoneInputCard(context, state is AuthLoading),
                  ],
                  const SizedBox(height: 16),
                  _buildGuestAccessCard(context),
                ] else ...[
                  _buildHeaderCard(
                    title: 'Accès Réservé Pharmacies Partenaires',
                    subtitle: 'Espace officiel sécurisé pour officines enregistrées à l’ONPC.',
                    icon: Icons.local_pharmacy_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildPharmacistLoginCard(context, state is AuthLoading),
                ],
              ],
              const SizedBox(height: 24),
              _buildComplianceFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoleSelector() {
    return SegmentedButton<UserRole>(
      segments: const [
        ButtonSegment(
          value: UserRole.patient,
          label: Text('Patient'),
          icon: Icon(Icons.person_rounded),
        ),
        ButtonSegment(
          value: UserRole.pharmacist,
          label: Text('Pharmacien Partenaire'),
          icon: Icon(Icons.medical_services_rounded),
        ),
      ],
      selected: {_selectedRole},
      onSelectionChanged: (val) {
        setState(() => _selectedRole = val.first);
      },
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return BentoCard(
      backgroundColor: AppColors.primarySoft.withValues(alpha: 0.5),
      borderColor: AppColors.primaryLight.withValues(alpha: 0.3),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInputCard(BuildContext context, bool isLoading) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Numéro de téléphone mobile (+237)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixText: '+237 ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              hintText: '699112233',
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isLoading
                  ? null
                  : () {
                      context.read<AuthBloc>().add(
                            SendOtpTriggered(_phoneController.text),
                          );
                    },
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Recevoir le code SMS →', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpInputCard(BuildContext context, String phone) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Code de Validation SMS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                '+237 $phone',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '• • • • • •',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<AuthBloc>().add(
                      VerifyOtpTriggered(
                        telephone: phone,
                        codeOtp: _otpController.text,
                      ),
                    );
              },
              child: const Text('Valider & Accéder à l’Espace Patient', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestAccessCard(BuildContext context) {
    return BentoCard(
      borderColor: AppColors.secondary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recherche Express sans Inscription',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Formulez vos demandes et consultez les disponibilités déclarées sans fournir aucune coordonnée préalable.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.secondary,
                side: const BorderSide(color: AppColors.secondary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<AuthBloc>().add(const ContinueAsGuestTriggered());
              },
              child: const Text('Continuer en Mode Invité (Zéro Friction)', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacistLoginCard(BuildContext context, bool isLoading) {
    final selectedProfile = _partnerPharmacies[_selectedPharmacyIndex];

    return BentoCard(
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sélectionner votre Officine Partenaire :',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ..._partnerPharmacies.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final isChosen = idx == _selectedPharmacyIndex;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isChosen ? AppColors.primary : AppColors.border),
              ),
              color: isChosen ? AppColors.primarySoft : Colors.white,
              child: ListTile(
                dense: true,
                leading: Icon(
                  isChosen ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: isChosen ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(p.pharmacyName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text('${p.responsable} · ${p.quarter}', style: const TextStyle(fontSize: 11)),
                onTap: () {
                  setState(() => _selectedPharmacyIndex = idx);
                },
              ),
            );
          }),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<AuthBloc>().add(
                      SignInPharmacistTriggered(
                        telephone: selectedProfile.telephone,
                        profile: selectedProfile,
                      ),
                    );
              },
              child: Text(
                'Se connecter en tant que ${selectedProfile.pharmacyName} →',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedProfileCard(BuildContext context, AuthState state) {
    final isGuest = state is AuthGuest;
    final isPharmacist = state is AuthAuthenticated && state.session.isPharmacist;
    final session = state is AuthAuthenticated ? state.session : null;

    final title = isGuest
        ? 'Session Invité (Patient)'
        : (isPharmacist
            ? 'Espace Officine Partenaire'
            : 'Patient Identifié');

    final subtitle = isGuest
        ? 'Consultation libre sans profil sauvegardé.'
        : (isPharmacist
            ? '${session?.pharmacyProfile?.pharmacyName} (${session?.pharmacyProfile?.quarter})'
            : 'Numéro : ${session?.telephone}');

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: isPharmacist ? AppColors.primarySoft : (isGuest ? AppColors.secondarySoft : AppColors.primarySoft),
                child: Icon(
                  isPharmacist
                      ? Icons.medical_services_rounded
                      : (isGuest ? Icons.person_outline_rounded : Icons.verified_user_rounded),
                  color: isPharmacist ? AppColors.primary : (isGuest ? AppColors.secondary : AppColors.primary),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),

          if (isPharmacist && session?.pharmacyProfile != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Titulaire : ${session!.pharmacyProfile!.responsable}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Licence ONPC : ${session.pharmacyProfile!.licenceOnpc}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.alert,
                side: const BorderSide(color: AppColors.alert),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                context.read<AuthBloc>().add(const SignOutTriggered());
              },
              child: const Text('Se déconnecter / Changer de rôle', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplianceFooter() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_clock_outlined, size: 16, color: AppColors.textTertiary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conformité Loi n° 2024/017 du 23 décembre 2024 sur la protection des données personnelles au Cameroun (ANTIC). Purge automatique des historiques de requêtes à 30 jours.',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
