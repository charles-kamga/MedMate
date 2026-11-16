import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/pharmacist_counter_state.dart';

/// Barre supérieure du portail comptoir : sélection de l'officine et filtres de file
class PharmacistPortalTopBar extends StatelessWidget {
  const PharmacistPortalTopBar({
    required this.activePharmacyId,
    required this.onPharmacyChanged,
    required this.onRefresh,
    required this.onFilterChanged,
    required this.state,
    super.key,
  });

  final String activePharmacyId;
  final ValueChanged<String?> onPharmacyChanged;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onFilterChanged;
  final PharmacistCounterState state;

  static const List<Map<String, String>> demoPharmacies = [
    {
      'id': 'pharma-soleil',
      'name': 'Pharmacie du Soleil',
      'quarter': 'Carrefour Warda',
    },
    {
      'id': 'pharma-mandela',
      'name': 'Pharmacie Mandela (Face CHU)',
      'quarter': 'Face CHU (Melen)',
    },
    {
      'id': 'pharma-melen-8',
      'name': 'Pharmacie Melen 8',
      'quarter': 'Melen',
    },
    {
      'id': 'pharma-centre',
      'name': 'Grande Pharmacie du Centre',
      'quarter': 'Poste Centrale',
    },
    {
      'id': 'pharma-obili',
      'name': "Pharmacie d'Obili",
      'quarter': 'Carrefour Obili',
    },
  ];

  static const List<Map<String, String?>> _filters = [
    {'label': 'Toutes', 'status': null},
    {'label': 'Vague active', 'status': 'dispatchingWave'},
    {'label': 'À retirer', 'status': 'readyForPickup'},
    {'label': 'Délivrées', 'status': 'delivered'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.storefront_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: activePharmacyId,
                    isExpanded: true,
                    items: demoPharmacies.map((p) {
                      return DropdownMenuItem(
                        value: p['id'],
                        child: Text(
                          '${p['name']} (${p['quarter']})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: onPharmacyChanged,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Actualiser la file',
                onPressed: onRefresh,
              ),
            ],
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((f) {
                final isSel = state.filterStatus == f['status'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(
                      f['label']!,
                      style: const TextStyle(fontSize: 11),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.primarySoft,
                    labelStyle: TextStyle(
                      color: isSel ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                    ),
                    onSelected: (_) => onFilterChanged(f['status']),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
