import 'package:flutter/material.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Données d'une pharmacie de garde officielle
class DutyPharmacyItem {
  const DutyPharmacyItem({
    required this.name,
    required this.quarter,
    required this.activity,
    required this.hours,
    required this.distance,
    required this.phone,
    required this.city,
  });

  final String name;
  final String quarter;
  final String activity;
  final String hours;
  final String distance;
  final String phone;
  final String city;
}

/// Écran Officiel « Pharmacies de garde » conforme à la maquette de Miguel
class DutyPharmacyScreen extends StatefulWidget {
  const DutyPharmacyScreen({super.key});

  @override
  State<DutyPharmacyScreen> createState() => _DutyPharmacyScreenState();
}

class _DutyPharmacyScreenState extends State<DutyPharmacyScreen> {
  static const List<String> cities = [
    'Yaoundé',
    'Douala',
    'Bertoua',
    'Bafoussam',
  ];

  static const List<DutyPharmacyItem> allDutyPharmacies = [
    DutyPharmacyItem(
      name: 'Grande Pharmacie du Centre',
      quarter: 'Poste Centrale',
      activity: 'Service d’Urgence',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '0,6 km',
      phone: '+237677112233',
      city: 'Yaoundé',
    ),
    DutyPharmacyItem(
      name: 'Pharmacie du Soleil',
      quarter: 'Warda',
      activity: 'Officine Centrale',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '1,1 km',
      phone: '+237699223344',
      city: 'Yaoundé',
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de Bastos',
      quarter: 'Bastos',
      activity: 'Garde Nocturne',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '2,3 km',
      phone: '+237677334455',
      city: 'Yaoundé',
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de Melen',
      quarter: 'Melen / CHU',
      activity: 'Proximité Hôpital',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '2,8 km',
      phone: '+237655445566',
      city: 'Yaoundé',
    ),
    DutyPharmacyItem(
      name: 'Pharmacie d’Obili',
      quarter: 'Obili',
      activity: 'Garde de Nuit',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '3,4 km',
      phone: '+237699556677',
      city: 'Yaoundé',
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de Biyem-Assi',
      quarter: 'Rond-Point Express',
      activity: 'Zone Résidentielle',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '4,2 km',
      phone: '+237677667788',
      city: 'Yaoundé',
    ),
    DutyPharmacyItem(
      name: 'Pharmacie de l’Émergence',
      quarter: 'Omnisports',
      activity: 'Garde Principale',
      hours: 'Ouverte 24h/24 · Garde de nuit',
      distance: '4,7 km',
      phone: '+237699778899',
      city: 'Yaoundé',
    ),
  ];

  String _selectedCity = 'Yaoundé';
  int _activeSegment = 0; // 0 = Plus proches, 1 = Toutes les gardes
  String _searchFilter = '';

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Contact Pharmacie de Garde'),
          content: Text(
            'Numéro d’urgence de garde : $phoneNumber\n\nAppel direct non pris en charge sur cet appareil.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openMaps(DutyPharmacyItem pharmacy) async {
    final query = Uri.encodeComponent('${pharmacy.name} ${pharmacy.quarter} $_selectedCity Cameroun');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’ouvrir Maps pour ${pharmacy.name}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var items = allDutyPharmacies.where((p) => p.city == _selectedCity).toList();

    if (_activeSegment == 0) {
      // Plus proches : triées par distance (déjà ordonnées)
      items = items.take(4).toList();
    } else if (_searchFilter.trim().isNotEmpty) {
      final q = _searchFilter.toLowerCase().trim();
      items = items
          .where(
            (p) =>
                p.name.toLowerCase().contains(q) ||
                p.quarter.toLowerCase().contains(q),
          )
          .toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: const Text(
                '✚',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre & Sous-titre officiels de la maquette
            const Text(
              'Pharmacies de garde',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Trouvez une pharmacie de garde près de vous',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // Sélecteur de Ville (Votre ville)
            Row(
              children: [
                const Text(
                  'Votre ville : ',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCity,
                    icon: const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
                    ),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    items: cities.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCity = val;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Puces de sélection [ Plus proches ] | [ Toutes les gardes ]
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeSegment = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeSegment == 0 ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _activeSegment == 0 ? AppColors.primary : const Color(0xFFCFE5D6),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Plus proches',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _activeSegment == 0 ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeSegment = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeSegment == 1 ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _activeSegment == 1 ? AppColors.primary : const Color(0xFFCFE5D6),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Toutes les gardes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _activeSegment == 1 ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bannière officielle Programme de garde
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F8F4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDBE9E0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('⏰', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Programme de garde',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${AppConfig.appName} affiche automatiquement les pharmacies positionnées pour la garde ce soir dans $_selectedCity.',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: Color(0xFF4A6559),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Recherche par quartier si "Toutes les gardes"
            if (_activeSegment == 1) ...[
              TextField(
                onChanged: (val) => setState(() => _searchFilter = val),
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Filtrer par quartier (ex: Bastos, Melen)...',
                  hintStyle: const TextStyle(color: Color(0xFF9EABA5), fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: const Color(0xFFFAFDFA),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDBE9E0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Liste des pharmacies de garde
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Aucune pharmacie de garde trouvée pour ce critère.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ...items.map((pharmacy) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x08163E2C),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pharmacy.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${pharmacy.quarter} · ${pharmacy.activity}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pharmacy.hours,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              pharmacy.distance,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Deux boutons d'action 50/50 [ 📞 Appeler ] & [ 🗺 Itinéraire ]
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _makePhoneCall(pharmacy.phone),
                              icon: const Icon(Icons.phone_in_talk, size: 16),
                              label: const Text(
                                'Appeler',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: Color(0xFFCFE5D6)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openMaps(pharmacy),
                              icon: const Icon(Icons.navigation_outlined, size: 16),
                              label: const Text(
                                'Itinéraire',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

            const SizedBox(height: 10),

            // Notice de sécurité
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE4EEE7)),
              ),
              child: const Text(
                'Avant de vous déplacer, appelez la pharmacie pour confirmer la disponibilité des équipes de garde et des produits nécessaires.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: Color(0xFF557165),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
