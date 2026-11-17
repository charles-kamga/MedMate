import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/user_session.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Carte de connexion rapide pour les officines partenaires.
class AuthPharmacistLoginCard extends StatelessWidget {
  const AuthPharmacistLoginCard({
    required this.partnerPharmacies,
    required this.selectedPharmacyIndex,
    required this.onSelectPharmacy,
    super.key,
  });

  final List<PharmacyStaffProfile> partnerPharmacies;
  final int selectedPharmacyIndex;
  final ValueChanged<int> onSelectPharmacy;

  @override
  Widget build(BuildContext context) {
    final selectedProfile = partnerPharmacies[selectedPharmacyIndex];

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
          ...partnerPharmacies.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            final isChosen = idx == selectedPharmacyIndex;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isChosen ? AppColors.primary : AppColors.border,
                ),
              ),
              color: isChosen ? AppColors.primarySoft : Colors.white,
              child: ListTile(
                dense: true,
                leading: Icon(
                  isChosen
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isChosen ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(
                  p.pharmacyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${p.responsable} · ${p.quarter}',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () => onSelectPharmacy(idx),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte affichant le profil connecté (Patient, Invité ou Officine).
class AuthConnectedProfileCard extends StatelessWidget {
  const AuthConnectedProfileCard({required this.state, super.key});

  final AuthState state;

  @override
  Widget build(BuildContext context) {
    final isGuest = state is AuthGuest;
    final currentState = state;
    final isPharmacist =
        currentState is AuthAuthenticated && currentState.session.isPharmacist;
    final session =
        currentState is AuthAuthenticated ? currentState.session : null;

    final title = isGuest
        ? 'Session Invité (Patient)'
        : (isPharmacist ? 'Espace Officine Partenaire' : 'Patient Identifié');

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
                backgroundColor: isPharmacist
                    ? AppColors.primarySoft
                    : (isGuest
                        ? AppColors.secondarySoft
                        : AppColors.primarySoft),
                child: Icon(
                  isPharmacist
                      ? Icons.medical_services_rounded
                      : (isGuest
                          ? Icons.person_outline_rounded
                          : Icons.verified_user_rounded),
                  color: isPharmacist
                      ? AppColors.primary
                      : (isGuest ? AppColors.secondary : AppColors.primary),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Licence ONPC : ${session.pharmacyProfile!.licenceOnpc}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                context.read<AuthBloc>().add(const SignOutTriggered());
              },
              child: const Text(
                'Se déconnecter / Changer de rôle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pied de page de conformité Loi n° 2024/017 (ANTIC).
class AuthComplianceFooter extends StatelessWidget {
  const AuthComplianceFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 16,
            color: AppColors.textTertiary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Conformité Loi n° 2024/017 du 23 décembre 2024 sur la protection des données personnelles au Cameroun (ANTIC). Purge automatique des historiques de requêtes à 30 jours.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
