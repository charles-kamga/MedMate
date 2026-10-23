import 'package:flutter/material.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:medmate/features/auth/presentation/views/auth_view.dart';
import 'package:medmate/features/patient_flow/presentation/views/auxiliary_tabs_views.dart';
import 'package:medmate/features/patient_flow/presentation/views/patient_home_flow_view.dart';
import 'package:medmate/features/pharmacy_search/presentation/views/pharmacy_map_view.dart';

/// Écran principal MedMate aligné sur la maquette HTML du maître d'œuvre
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.enableNetworkTiles = true,
  });

  final bool enableNetworkTiles;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  String _currentTab = 'home';

  void _setTab(String tab) {
    setState(() {
      _currentTab = tab;
    });
  }

  int get _navIndex {
    switch (_currentTab) {
      case 'home':
        return 0;
      case 'history':
        return 1;
      case 'reminders':
        return 2;
      case 'profile':
        return 3;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                '✚',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              AppConfig.appName,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 22,
                letterSpacing: -0.6,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              tooltip: 'Notifications',
              onPressed: () => _setTab('notifications'),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7F3),
              borderRadius: BorderRadius.circular(13),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              tooltip: 'Profil',
              onPressed: () => _setTab('profile'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _buildCurrentTabContent(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE5EDE7)),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: AppColors.primarySoft,
          selectedIndex: _navIndex,
          onDestinationSelected: (index) {
            switch (index) {
              case 0:
                _setTab('home');
              case 1:
                _setTab('history');
              case 2:
                _setTab('reminders');
              case 3:
                _setTab('profile');
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_rounded),
              selectedIcon: Icon(Icons.search_rounded, color: AppColors.primary),
              label: 'Mes recherches',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_time_rounded),
              selectedIcon: Icon(Icons.access_time_filled_rounded, color: AppColors.primary),
              label: 'Rappels',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentTab) {
      case 'history':
        return AuxiliaryTabView(
          key: const ValueKey('tab_history'),
          title: 'Mes recherches',
          description: 'Retrouvez vos médicaments rapidement.',
          buttonLabel: 'Rechercher maintenant',
          icon: Icons.search_rounded,
          onActionPressed: () => _setTab('home'),
        );

      case 'reminders':
        return AuxiliaryTabView(
          key: const ValueKey('tab_reminders'),
          title: 'Mes rappels',
          description: 'Vos rappels de prise de médicaments apparaîtront ici.',
          buttonLabel: 'Commencer une recherche',
          icon: Icons.alarm_rounded,
          onActionPressed: () => _setTab('home'),
        );

      case 'profile':
        return AuxiliaryTabView(
          key: const ValueKey('tab_profile'),
          title: 'Mon profil',
          description: 'Bienvenue dans votre espace patient MedMate.',
          buttonLabel: 'Rechercher un médicament',
          icon: Icons.person_rounded,
          onActionPressed: () => _setTab('home'),
          extraWidget: Column(
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.map_outlined, color: AppColors.primary),
                  ),
                  title: const Text(
                    'Carte interactive des pharmacies',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Consulter la géolocalisation OpenStreetMap',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Carte des pharmacies'),
                          ),
                          body: PharmacyMapView(enableNetworkTiles: widget.enableNetworkTiles),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Color(0xFFEDF2EE)),
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_outline, color: AppColors.primary),
                  ),
                  title: const Text(
                    'Espace Professionnel & Sécurité',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Authentification praticien / pharmacie',
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                            title: const Text('Authentification'),
                          ),
                          body: const AuthView(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );

      case 'notifications':
        return AuxiliaryTabView(
          key: const ValueKey('tab_notifications'),
          title: 'Notifications',
          description: 'Aucune nouvelle notification.',
          buttonLabel: 'Retour à l’accueil',
          icon: Icons.notifications_none_rounded,
          onActionPressed: () => _setTab('home'),
        );

      case 'home':
      default:
        return PatientHomeFlowView(
          key: const ValueKey('tab_home'),
          onOpenReminders: () => _setTab('reminders'),
        );
    }
  }
}
