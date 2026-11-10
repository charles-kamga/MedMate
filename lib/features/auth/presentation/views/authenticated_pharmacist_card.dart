import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:medmate/core/widgets/bento_card.dart';
import 'package:medmate/features/auth/domain/entities/pharmacist_profile.dart';
import 'package:medmate/features/auth/presentation/controllers/auth_cubit.dart';

/// Carte de profil affichée lorsqu'un pharmacien d'officine est authentifié.
class AuthenticatedPharmacistCard extends StatelessWidget {
  const AuthenticatedPharmacistCard({required this.profile, super.key});

  final PharmacistProfile profile;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BentoCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.primarySoft,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profile.licenceOnpc,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _row('Officine ID', profile.pharmacyId),
                const SizedBox(height: 8),
                _row('Rôle ONPC', profile.role.name.toUpperCase()),
                const SizedBox(height: 8),
                _row('Email', profile.email),
                const SizedBox(height: 8),
                _row('Téléphone', profile.telephone),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    key: const Key('pharmacist_sign_out_button'),
                    onPressed: () => context.read<AuthCubit>().signOut(),
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Se déconnecter'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      );
}
