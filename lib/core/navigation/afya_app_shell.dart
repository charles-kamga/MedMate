import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart';
import '../../features/patient_flow/presentation/views/auxiliary_tabs_views.dart';
import '../../features/patient_flow/presentation/views/patient_home_flow_view.dart';
import '../../features/pharmacist_portal/presentation/views/pharmacist_portal_view.dart';
import '../../features/pharmacy_search/presentation/views/pharmacy_map_view.dart';
import '../../features/reservation/presentation/views/patient_flash_flow_view.dart';
import 'widgets/afya_app_bar.dart';

/// Navigation Shell souverain d'Afya-Health (< 400 lignes).
/// Intègre harmonieusement le parcours Flash inversé « Style Yango ».
class AfyaAppShell extends StatefulWidget {
  const AfyaAppShell({
    super.key,
    this.initialIndex = 0,
    this.enableNetworkTiles = true,
  });

  final int initialIndex;
  final bool enableNetworkTiles;

  @override
  State<AfyaAppShell> createState() => _AfyaAppShellState();
}

class _AfyaAppShellState extends State<AfyaAppShell> {
  late int _currentIndex;
  int _dutyViewMode = 0; // 0 = Pharmacies de garde (liste), 1 = Carte OSM

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onSelectTab(int index) {
    if (_currentIndex == index) return;
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return PatientHomeFlowView(
          key: const ValueKey('tab_home'),
          onOpenReminders: () => _onSelectTab(1),
        );
      case 1:
        return const PatientFlashFlowView(
          key: ValueKey('tab_flash_yango'),
        );
      case 2:
        return _buildDutyAndMapTab();
      case 3:
      default:
        return _buildProfileTab();
    }
  }

  Widget _buildDutyAndMapTab() {
    return Column(
      key: const ValueKey('tab_map_duty'),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildSubTabButton(
                  title: 'Pharmacies de garde',
                  icon: Icons.nightlight_round,
                  isSelected: _dutyViewMode == 0,
                  onTap: () => setState(() => _dutyViewMode = 0),
                  key: const ValueKey('btn_switch_duty_list'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSubTabButton(
                  title: 'Carte OSM',
                  icon: Icons.map_rounded,
                  isSelected: _dutyViewMode == 1,
                  onTap: () => setState(() => _dutyViewMode = 1),
                  key: const ValueKey('btn_switch_map_view'),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.borderSubtle),
        Expanded(
          child: _dutyViewMode == 0
              ? const DutyPharmacyScreen(key: ValueKey('view_duty_list'))
              : PharmacyMapView(
                  key: const ValueKey('view_osm_map'),
                  enableNetworkTiles: widget.enableNetworkTiles,
                ),
        ),
      ],
    );
  }

  Widget _buildSubTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    Key? key,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return AuxiliaryTabView(
      key: const ValueKey('tab_profile'),
      title: 'Mon profil ${AppConfig.appName}',
      description:
          'Espace patient et accès réservé aux officines partenaires de Yaoundé.',
      buttonLabel: 'Lancer une recherche Flash',
      icon: Icons.person_rounded,
      onActionPressed: () => _onSelectTab(1),
      extraWidget: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.borderSubtle),
                ),
                tileColor: AppColors.surface,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Portail Officine Partenaire',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Gérer les demandes de garde et valider les retraits OTP',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Portail Officine Partenaire'),
                        ),
                        body: const PharmacistPortalView(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        if (isDesktop) {
          return Scaffold(
            appBar: const AfyaAppBar(),
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: Colors.white,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onSelectTab,
                  labelType: NavigationRailLabelType.all,
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  indicatorColor: AppColors.primarySoft,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon:
                          Icon(Icons.home_rounded, color: AppColors.primary),
                      label: Text('Accueil'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.bolt_outlined),
                      selectedIcon:
                          Icon(Icons.bolt_rounded, color: AppColors.primary),
                      label: Text('Flash Yango'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.local_pharmacy_outlined),
                      selectedIcon: Icon(
                        Icons.local_pharmacy_rounded,
                        color: AppColors.primary,
                      ),
                      label: Text('Gardes & Carte'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon:
                          Icon(Icons.person_rounded, color: AppColors.primary),
                      label: Text('Profil'),
                    ),
                  ],
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppColors.borderSubtle,
                ),
                Expanded(child: _buildBody()),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: const AfyaAppBar(),
          body: _buildBody(),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: NavigationBar(
              backgroundColor: Colors.white,
              elevation: 0,
              indicatorColor: AppColors.primarySoft,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onSelectTab,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon:
                      Icon(Icons.home_rounded, color: AppColors.primary),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bolt_outlined),
                  selectedIcon:
                      Icon(Icons.bolt_rounded, color: AppColors.primary),
                  label: 'Flash Yango',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_pharmacy_outlined),
                  selectedIcon: Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppColors.primary,
                  ),
                  label: 'Gardes',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon:
                      Icon(Icons.person_rounded, color: AppColors.primary),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
