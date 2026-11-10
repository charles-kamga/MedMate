import 'package:flutter/material.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:medmate/core/widgets/bento_card.dart';
import 'package:medmate/features/auth/presentation/views/pharmacist_sign_in_view.dart';

/// Coquille de navigation responsive d'Afya Santé.
/// - Mobile (< 600px) : Scaffold avec NavigationBar inférieure à 4 onglets.
/// - Desktop / Tablette (>= 600px) : Scaffold avec NavigationRail latéral et vue étendue.
class AfyaAppShell extends StatefulWidget {
  const AfyaAppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AfyaAppShell> createState() => _AfyaAppShellState();
}

class _AfyaAppShellState extends State<AfyaAppShell> {
  late int _selectedIndex;

  static const _destinations = [
    _NavDestinationInfo(
      icon: Icons.search_outlined,
      selectedIcon: Icons.search_rounded,
      label: 'Recherche',
    ),
    _NavDestinationInfo(
      icon: Icons.shield_outlined,
      selectedIcon: Icons.shield_rounded,
      label: 'Gardes',
    ),
    _NavDestinationInfo(
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long_rounded,
      label: 'Réservation',
    ),
    _NavDestinationInfo(
      icon: Icons.local_pharmacy_outlined,
      selectedIcon: Icons.local_pharmacy_rounded,
      label: 'Espace Pro',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < AppConfig.compactBreakpoint;
    final isExpanded = screenSize.width >= AppConfig.expandedBreakpoint;
    final currentView = _buildTabContent(_selectedIndex, isExpanded);

    if (isMobile) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(child: currentView),
        bottomNavigationBar: NavigationBar(
          key: const Key('afya_bottom_navigation_bar'),
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: _destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon, color: AppColors.primary),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Row(
          children: [
            NavigationRail(
              key: const Key('afya_navigation_rail'),
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              minWidth: 72,
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon:
                          Icon(d.selectedIcon, color: AppColors.primary),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: currentView),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
        titleSpacing: 16,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.local_pharmacy_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Flexible(
              child: Text(AppConfig.appName, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );

  Widget _buildTabContent(int index, bool isExpanded) {
    switch (index) {
      case 0:
        return _buildSearchTab(isExpanded);
      case 1:
        return _buildInfoTab(
          icon: Icons.shield_rounded,
          iconColor: AppColors.dutyAmber,
          title: 'Pharmacies de Garde à Yaoundé',
          description:
              'Consultez les officines ouvertes 24h/24 selon le tableau de garde officiel de l’Ordre National des Pharmaciens du Cameroun (ONPC).',
          chipIcon: Icons.emergency_outlined,
          chipLabel: 'Urgences médicales : ${AppConfig.emergencyPhone}',
        );
      case 2:
        return _buildInfoTab(
          icon: Icons.receipt_long_rounded,
          iconColor: AppColors.primary,
          title: 'Commande Flash & Réservation',
          description:
              'Transmettez votre ordonnance ou liste de médicaments. Les officines partenaires de votre secteur émettent un devis avec prix comptoir. Retrait sécurisé par code OTP.',
          chipIcon: Icons.timer_outlined,
          chipLabel:
              'Délai de retrait : ${AppConfig.reservationTtl.inHours}h max',
        );
      case 3:
        return const PharmacistSignInView();
      default:
        return _buildSearchTab(isExpanded);
    }
  }

  Widget _buildSearchTab(bool isExpanded) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isExpanded ? 1040 : 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: BentoCard(
              backgroundColor: AppColors.surface,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dutyAmberSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Yaoundé · Disponibilité & Gardes',
                      style: TextStyle(
                        color: AppColors.dutyAmberDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    AppConfig.appTagline,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    AppConfig.pricePolicyNotice,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      (Icons.map_outlined, AppConfig.mapProviderName),
                      (Icons.verified_user_outlined, 'ONPC Round-Robin'),
                      (
                        Icons.location_city_outlined,
                        '${YaoundeLandmarks.list.length} repères'
                      ),
                      (
                        Icons.devices_outlined,
                        isExpanded
                            ? 'Mode Desktop Comptoir'
                            : 'Mode Mobile Patient'
                      ),
                    ]
                        .map((e) => _buildChip(icon: e.$1, label: e.$2))
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildInfoTab({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required IconData chipIcon,
    required String chipLabel,
  }) =>
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: BentoCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: iconColor, size: 24),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildChip(icon: chipIcon, label: chipLabel),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _buildChip({required IconData icon, required String label}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _NavDestinationInfo {
  const _NavDestinationInfo({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
