import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modèle pour les données de pharmacie de démonstration de la maquette HTML
class PharmacyDemoData {
  const PharmacyDemoData({
    required this.name,
    required this.distance,
    required this.phone,
    required this.stock,
    required this.prices,
  });

  final String name;
  final String distance;
  final String phone;
  final List<int> stock;
  final List<int?> prices;
}

/// Vue principale interactive du parcours patient (Étapes 0 à 4)
class PatientHomeFlowView extends StatefulWidget {
  const PatientHomeFlowView({
    super.key,
    this.onOpenReminders,
  });

  final VoidCallback? onOpenReminders;

  @override
  State<PatientHomeFlowView> createState() => _PatientHomeFlowViewState();
}

class _PatientHomeFlowViewState extends State<PatientHomeFlowView> {
  // Liste des médicaments officiels de la maquette
  static const List<String> medicines = [
    'Paracétamol 500 mg',
    'Amoxicilline 500 mg',
    'Vitamine C 1000 mg',
    'Ibuprofène 400 mg',
    'Sérum physiologique',
  ];

  // Pharmacies de démonstration officielles de la maquette
  static const List<PharmacyDemoData> pharmacies = [
    PharmacyDemoData(
      name: 'Pharmacie du Centre',
      distance: '1,2 km',
      phone: '+237600000001',
      stock: [0, 1, 2, 3, 4],
      prices: [500, 1800, 1200, 900, 700],
    ),
    PharmacyDemoData(
      name: 'Pharmacie Santé Plus',
      distance: '2,4 km',
      phone: '+237600000002',
      stock: [0, 2, 3, 4],
      prices: [600, null, 1100, 850, 650],
    ),
    PharmacyDemoData(
      name: 'Pharmacie de la Paix',
      distance: '3,1 km',
      phone: '+237600000003',
      stock: [0, 1, 2, 4],
      prices: [550, 2000, 1300, null, 750],
    ),
  ];

  static const List<String> cities = [
    'Yaoundé',
    'Douala',
    'Bertoua',
    'Bafoussam',
  ];

  int _step = 0;
  List<int> _selected = [];
  int _chosen = 0;
  String _query = '';
  String _city = 'Yaoundé';
  bool _availabilityOnly = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _step = 1;
    });
  }

  void _back() {
    setState(() {
      if (_step > 1) {
        _step--;
      } else {
        _step = 0;
      }
    });
  }

  void _quick(int index) {
    setState(() {
      _selected = [index];
      _query = '';
      _searchController.clear();
      _step = 1;
    });
  }

  void _add(int index) {
    setState(() {
      if (!_selected.contains(index)) {
        _selected.add(index);
      }
      _query = '';
      _searchController.clear();
    });
  }

  void _remove(int index) {
    setState(() {
      _selected.remove(index);
    });
  }

  bool _isMatch(PharmacyDemoData p) {
    return _selected.every(p.stock.contains);
  }

  int _totalPrice(PharmacyDemoData p) {
    return _selected.fold(0, (sum, i) => sum + (p.prices[i] ?? 0));
  }

  bool _allPricesKnown(PharmacyDemoData p) {
    return _selected.every((i) => p.prices[i] != null);
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  Future<void> _openGoogleMaps(String pharmacyName) async {
    final query = Uri.encodeComponent('$pharmacyName $_city Cameroun');
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Impossible d'ouvrir Maps pour $pharmacyName"),
        ),
      );
    }
  }

  void _showNoticeDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Information Démonstration',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step > 0) _buildWizardHeader(),
          if (_step == 0) _buildStep0Home(),
          if (_step == 1) _buildStep1Choose(),
          if (_step == 2) _buildStep2Find(),
          if (_step == 3) _buildStep3Detail(),
          if (_step == 4) _buildStep4Route(),
        ],
      ),
    );
  }

  Widget _buildWizardHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _back,
              icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.primary),
              label: const Text(
                'Retour',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
            Text(
              'Étape $_step sur 4',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFFE8F2EB),
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 250),
              widthFactor: _step * 0.25,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // ÉTAPE 0 : ACCUEIL
  // ==========================================
  Widget _buildStep0Home() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Location Dropdown
        const Text(
          'Bonjour 👋 · Votre localisation',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _city,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('📍', style: TextStyle(fontSize: 14)),
                ),
                style: const TextStyle(
                  fontSize: 16,
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
                      _city = val;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Headline & Subtitle
        const Text(
          'De quels médicaments avez-vous besoin ?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Trouvez-les dans les pharmacies près de vous.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Champ de recherche
        _buildSearchField(
          onChanged: (val) {
            setState(() {
              _query = val;
            });
          },
        ),
        const SizedBox(height: 16),

        // Bouton principal
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _start,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Trouver mes médicaments →',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Section Mes recherches récentes
        const Text(
          'Mes recherches récentes',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Accès rapide',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('Paracétamol 500 mg ↗'),
                    backgroundColor: AppColors.primarySoft,
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide.none,
                    ),
                    onPressed: () => _quick(0),
                  ),
                  ActionChip(
                    label: const Text('Vitamine C ↗'),
                    backgroundColor: AppColors.primarySoft,
                    labelStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: BorderSide.none,
                    ),
                    onPressed: () => _quick(2),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Section Pharmacies à proximité
        const Text(
          'Pharmacies à proximité',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏥 Pharmacies partenaires',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consultez les disponibilités déclarées',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: _start,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFCFE5D6)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                child: const Text('Voir →', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Raccourci Mes rappels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              '⏰ Mes rappels',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: widget.onOpenReminders,
              child: const Text(
                'Ouvrir →',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Legal Notice Banner
        _buildNoticeBanner(
          'MedMate vous met en relation avec des pharmacies. Aucun achat ni livraison dans cette version.',
        ),
      ],
    );
  }

  // ==========================================
  // ÉTAPE 1 : CHOISISSEZ VOS MÉDICAMENTS
  // ==========================================
  Widget _buildStep1Choose() {
    final hits = medicines
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.value.toLowerCase().contains(_query.toLowerCase()) &&
              !_selected.contains(entry.key),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez vos médicaments',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ajoutez un ou plusieurs médicaments à votre liste.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Champ de recherche
        _buildSearchField(
          onChanged: (val) {
            setState(() {
              _query = val;
            });
          },
        ),
        const SizedBox(height: 16),

        // Résultats de recherche
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: hits.isEmpty
              ? const Text(
                  'Aucun autre médicament trouvé.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                )
              : Column(
                  children: hits.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEDF2EE)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _add(entry.key),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: Color(0xFFCFE5D6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              '+ Ajouter',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 24),

        // Ma liste
        Text(
          'Ma liste (${_selected.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: _selected.isEmpty
              ? const Text(
                  'Votre liste est vide.',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                )
              : Column(
                  children: _selected.map((index) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFEDF2EE)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              medicines[index],
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _remove(index),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade700,
                              side: BorderSide(color: Colors.red.shade200),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Retirer',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 24),

        // Bouton Continuer
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selected.isEmpty
                ? null
                : () {
                    setState(() {
                      _step = 2;
                    });
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Continuer →',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ÉTAPE 2 : TROUVEZ UNE PHARMACIE
  // ==========================================
  Widget _buildStep2Find() {
    final filteredPharmacies = pharmacies.asMap().entries.where((entry) {
      if (_availabilityOnly) {
        return _isMatch(entry.value);
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trouvez une pharmacie',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Comparez les disponibilités déclarées par nos partenaires.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // Carte Filtres
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ville',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _city,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
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
                            _city = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFEDF2EE), height: 20),
              InkWell(
                onTap: () {
                  setState(() {
                    _availabilityOnly = !_availabilityOnly;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _availabilityOnly,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _availabilityOnly = val ?? false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Tous les médicaments disponibles',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Distance : pharmacies classées de la plus proche à la plus éloignée (données de démonstration).',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Cartes de pharmacies
        if (filteredPharmacies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aucune pharmacie ne correspond au filtre.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          )
        else
          ...filteredPharmacies.map((entry) {
            final p = entry.value;
            final isFull = _isMatch(p);
            final allKnown = _allPricesKnown(p);
            final priceStr = allKnown
                ? '${_formatPrice(_totalPrice(p))} FCFA'
                : 'Incomplet';

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '🏥 ${p.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFull
                              ? const Color(0xFFE8F6ED)
                              : AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isFull ? 'Tous disponibles' : 'Stock partiel',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isFull
                                ? const Color(0xFF147C54)
                                : AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '📍 $_city · ${p.distance} · Prix indicatif : $priceStr',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _chosen = entry.key;
                          _step = 3;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: Color(0xFFCFE5D6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Choisir cette pharmacie →',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ==========================================
  // ÉTAPE 3 : FICHE DÉTAILLÉE PHARMACIE
  // ==========================================
  Widget _buildStep3Detail() {
    final p = pharmacies[_chosen];
    final allKnown = _allPricesKnown(p);
    final totalStr = allKnown
        ? '${_formatPrice(_totalPrice(p))} FCFA'
        : 'Non calculable';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          p.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '📍 $_city · ${p.distance}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Carte Liste et Tarifs
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre liste',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ..._selected.map((index) {
                final isAvailable = p.stock.contains(index);
                final price = p.prices[index];
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFEDF2EE)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              medicines[index],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAvailable
                                  ? 'Disponibilité déclarée'
                                  : 'Disponibilité non confirmée',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAvailable
                                    ? AppColors.primary
                                    : AppColors.warning,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        price != null ? '${_formatPrice(price)} F' : 'Prix inconnu',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total indicatif',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    totalStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bouton Voir l'itinéraire
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _step = 4;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Voir l’itinéraire →',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Actions secondaires (Appeler & Confirmer)
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showNoticeDialog(
                  'Numéro fictif de démonstration (${p.phone}) : à remplacer par le numéro vérifié de la pharmacie.',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFCFE5D6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '☎ Appeler la pharmacie',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _showNoticeDialog(
                  'Démonstration : contactez directement la pharmacie pour confirmer la disponibilité avant de vous déplacer.',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: Color(0xFFCFE5D6)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '✓ Confirmer la dispo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Legal Notice Banner
        _buildNoticeBanner(
          'Les prix et stocks sont fictifs dans cette démonstration. Ils doivent être confirmés directement auprès de la pharmacie.',
        ),
      ],
    );
  }

  // ==========================================
  // ÉTAPE 4 : RENDEZ-VOUS À LA PHARMACIE
  // ==========================================
  Widget _buildStep4Route() {
    final p = pharmacies[_chosen];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: Text('📍', style: TextStyle(fontSize: 34)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Rendez-vous à la pharmacie',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${p.name} · $_city',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Carte Liste de médicaments
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Votre liste de médicaments',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              ..._selected.map((index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Text(
                        '✓ ',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          medicines[index],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Bouton Google Maps
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _openGoogleMaps(p.name),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Ouvrir dans Google Maps ↗',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Notice Banner
        _buildNoticeBanner(
          "Vérifiez l'adresse exacte et la disponibilité avec la pharmacie avant votre déplacement.",
        ),
        const SizedBox(height: 16),

        // Bouton Terminer
        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _step = 0;
              });
            },
            child: const Text(
              'Terminer',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper champ de recherche
  Widget _buildSearchField({required ValueChanged<String> onChanged}) {
    return TextField(
      controller: _searchController,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher un médicament…',
        hintStyle: const TextStyle(color: Color(0xFF9EABA5)),
        filled: true,
        fillColor: const Color(0xFFFAFDFA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20, color: AppColors.textSecondary),
                onPressed: () {
                  _searchController.clear();
                  onChanged('');
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDBE9E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  // Helper bannière notice
  Widget _buildNoticeBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Color(0xFF557165),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
