import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Vue d'authentification et gestion du profil patient (UI/UX Pro Max)
class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

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
              backgroundColor: AppColors.emergency,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Espace Patient & Sécurité'),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (state is AuthAuthenticated || state is AuthGuest) ...[
                _buildConnectedProfileCard(context, state),
              ] else ...[
                _buildHeaderCard(),
                const SizedBox(height: 20),
                if (state is AuthOtpSent) ...[
                  _buildOtpInputCard(context, state.telephone),
                ] else ...[
                  _buildPhoneInputCard(context, state is AuthLoading),
                ],
                const SizedBox(height: 20),
                _buildGuestAccessCard(context),
              ],
              const SizedBox(height: 24),
              _buildComplianceFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard() {
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
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Accès Sécurisé & Anonymat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Consultez librement. Vos données de santé restent strictement chiffrées.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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
            'Connexion Rapide par SMS OTP',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Entrez votre numéro pour confirmer vos réservations et recevoir votre code de retrait.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.phone_iphone_rounded, color: AppColors.primary),
              prefixText: '+237 ',
              prefixStyle: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 15,
              ),
              hintText: '699 11 22 33',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
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
                  : const Text('Recevoir le code SMS'),
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
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
            child: ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(
                      VerifyOtpTriggered(
                        telephone: phone,
                        codeOtp: _otpController.text,
                      ),
                    );
              },
              child: const Text('Valider & Accéder'),
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
          const Row(
            children: [
              Icon(Icons.flash_on_rounded, color: AppColors.secondary, size: 22),
              SizedBox(width: 8),
              Text(
                'Urgence Médicale Sans Compte',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Accédez immédiatement aux pharmacies de garde et repères de Yaoundé sans fournir aucune coordonnée.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<AuthBloc>().add(const ContinueAsGuestTriggered());
              },
              child: const Text('Continuer en Mode Invité (Zéro Friction)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedProfileCard(BuildContext context, AuthState state) {
    final isGuest = state is AuthGuest;
    final title = isGuest ? 'Session Invité (Anonyme)' : 'Patient Identifié';
    final subtitle = isGuest
        ? 'Recherche et consultation illimitées sans compte.'
        : 'Connecté avec le numéro : ${(state as AuthAuthenticated).session.telephone}';

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isGuest ? AppColors.secondarySoft : AppColors.primarySoft,
                child: Icon(
                  isGuest ? Icons.person_outline_rounded : Icons.verified_user_rounded,
                  color: isGuest ? AppColors.secondary : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          const Text(
            'Réservations actives & Retraits',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Aucune réservation en attente. Vos retraits expirés (TTL 2h) sont automatiquement effacés.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                context.read<AuthBloc>().add(const SignOutTriggered());
              },
              child: const Text('Se déconnecter / Changer de profil'),
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
              'Conformité Loi n° 2024/017 du 23 décembre 2024 sur la protection des données personnelles au Cameroun (ANTIC). Purge automatique des historiques à 30 jours.',
              style: TextStyle(fontSize: 11, color: AppColors.textTertiary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
