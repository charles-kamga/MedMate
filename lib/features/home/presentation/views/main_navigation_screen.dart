import 'package:flutter/material.dart';
import '../../../auth/presentation/views/auth_view.dart';
import '../../../pharmacy_search/presentation/views/medication_catalog_view.dart';
import '../../../pharmacy_search/presentation/views/pharmacy_map_view.dart';

/// Écran principal intégrant la barre de navigation Material 3 (UI/UX Pro Max)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.enableNetworkTiles = true});

  final bool enableNetworkTiles;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    PharmacyMapView(enableNetworkTiles: widget.enableNetworkTiles),
    const MedicationCatalogView(),
    const AuthView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Pharmacies',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication_rounded),
            label: 'Médicaments',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_circle_outlined),
            selectedIcon: Icon(Icons.account_circle_rounded),
            label: 'Mon Espace',
          ),
        ],
      ),
    );
  }
}
