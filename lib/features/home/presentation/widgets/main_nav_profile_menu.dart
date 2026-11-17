import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:medmate/features/auth/presentation/views/auth_view.dart';
import 'package:medmate/features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart';
import 'package:medmate/features/pharmacy_search/presentation/views/pharmacy_map_view.dart';

/// Colonne des raccourcis du profil sur l'écran de navigation historique.
class MainNavProfileMenu extends StatelessWidget {
  const MainNavProfileMenu({
    required this.enableNetworkTiles,
    super.key,
  });

  final bool enableNetworkTiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _MenuTile(
          icon: Icons.storefront_rounded,
          title: 'Portail Officine Partenaire (Pharmacien)',
          subtitle:
              'Traiter les demandes entrantes et valider les retraits OTP',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar:
                    AppBar(title: const Text('Portail Officine Partenaire')),
                body: const PharmacistPortalView(),
              ),
            ),
          ),
        ),
        const Divider(color: Color(0xFFEDF2EE)),
        _MenuTile(
          icon: Icons.map_outlined,
          title: 'Carte interactive des pharmacies',
          subtitle: 'Consulter la géolocalisation OpenStreetMap',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Carte des pharmacies')),
                body: PharmacyMapView(enableNetworkTiles: enableNetworkTiles),
              ),
            ),
          ),
        ),
        const Divider(color: Color(0xFFEDF2EE)),
        _MenuTile(
          icon: Icons.lock_outline,
          title: 'Espace Professionnel & Sécurité',
          subtitle: 'Authentification praticien / pharmacie',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AuthView()),
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing:
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}
