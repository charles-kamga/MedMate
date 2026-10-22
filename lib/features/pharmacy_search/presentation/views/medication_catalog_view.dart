import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/medication.dart';

/// Vue du catalogue national homologué et recherche tolérante aux fautes
class MedicationCatalogView extends StatefulWidget {
  const MedicationCatalogView({super.key});

  @override
  State<MedicationCatalogView> createState() => _MedicationCatalogViewState();
}

class _MedicationCatalogViewState extends State<MedicationCatalogView> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'Tous';

  // Échantillon fidèle au catalogue national homologué (Cameroun)
  static const List<Medication> _allMedications = [
    Medication(
      id: 'med-doliprane',
      nomCommercial: 'Doliprane 1000mg',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '1000 mg',
      classeTherapeutique: 'Antalgique / Antipyrétique',
      prixHomologueCfa: 1500,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-efferalgan',
      nomCommercial: 'Efferalgan 500mg',
      dci: 'Paracétamol',
      forme: 'Comprimé',
      dosage: '500 mg',
      classeTherapeutique: 'Antalgique / Antipyrétique',
      prixHomologueCfa: 1200,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-coartem',
      nomCommercial: 'Coartem 20/120',
      dci: 'Artéméther + Luméfantrine',
      forme: 'Comprimé',
      dosage: '20 mg / 120 mg',
      classeTherapeutique: 'Antipaludique (CTA)',
      prixHomologueCfa: 2800,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-clamoxyl',
      nomCommercial: 'Clamoxyl 500mg',
      dci: 'Amoxicilline',
      forme: 'Gélule',
      dosage: '500 mg',
      classeTherapeutique: 'Antibiotique Bêta-lactamine',
      prixHomologueCfa: 3200,
      necessiteOrdonnance: true,
    ),
    Medication(
      id: 'med-advil',
      nomCommercial: 'Advil 400mg',
      dci: 'Ibuprofène',
      forme: 'Capsule molle',
      dosage: '400 mg',
      classeTherapeutique: 'Anti-inflammatoire (AINS)',
      prixHomologueCfa: 2400,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-sro',
      nomCommercial: 'Oralyte (SRO)',
      dci: 'Sels de Réhydratation Orale',
      forme: 'Sachet pour solution',
      dosage: 'Sachet 20.5 g',
      classeTherapeutique: 'Réhydratation',
      prixHomologueCfa: 400,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-ciflox',
      nomCommercial: 'Ciflox 500mg',
      dci: 'Ciprofloxacine',
      forme: 'Comprimé pelliculé',
      dosage: '500 mg',
      classeTherapeutique: 'Antibiotique Fluoroquinolone',
      prixHomologueCfa: 4500,
      necessiteOrdonnance: true,
    ),
    Medication(
      id: 'med-mopral',
      nomCommercial: 'Mopral 20mg',
      dci: 'Oméprazole',
      forme: 'Gélule gastro-résistante',
      dosage: '20 mg',
      classeTherapeutique: 'Antiulcéreux / IPP',
      prixHomologueCfa: 3800,
      necessiteOrdonnance: false,
    ),
  ];

  List<Medication> get _filteredMedications {
    final query = _searchController.text.toLowerCase().trim();
    return _allMedications.where((med) {
      final matchesQuery = query.isEmpty ||
          med.nomCommercial.toLowerCase().contains(query) ||
          med.dci.toLowerCase().contains(query) ||
          med.classeTherapeutique.toLowerCase().contains(query);

      final matchesCategory = _selectedCategory == 'Tous' ||
          (_selectedCategory == 'Sans ordonnance' && !med.necessiteOrdonnance) ||
          (_selectedCategory == 'Paludisme' && med.classeTherapeutique.contains('Antipaludique')) ||
          (_selectedCategory == 'Antalgiques' && med.classeTherapeutique.contains('Antalgique')) ||
          (_selectedCategory == 'Antibiotiques' && med.classeTherapeutique.contains('Antibiotique'));

      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final medications = _filteredMedications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue & Disponibilité'),
      ),
      body: Column(
        children: [
          // 1. Barre de Recherche Tolérante
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher (ex: Paracétamol, Coartem, DCI...)',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Filtres Rapides en Puces
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip('Tous'),
                _buildFilterChip('Sans ordonnance'),
                _buildFilterChip('Paludisme'),
                _buildFilterChip('Antalgiques'),
                _buildFilterChip('Antibiotiques'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 3. Liste des Médicaments (Cartes Bento)
          Expanded(
            child: medications.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: medications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final medication = medications[index];
                      return _buildMedicationCard(context, medication);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedCategory == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        selectedColor: AppColors.primary,
        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
        showCheckmark: false,
        onSelected: (_) {
          setState(() {
            _selectedCategory = label;
          });
        },
      ),
    );
  }

  Widget _buildMedicationCard(BuildContext context, Medication medication) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.nomCommercial,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DCI : ${medication.dci}',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${medication.prixHomologueCfa} FCFA',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${medication.forme} • ${medication.dosage}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              if (medication.necessiteOrdonnance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Ordonnance requise',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.successSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Vente libre',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Demande Flash Proximité (Ping 3-5 min)'),
              onPressed: () => _showFlashRequestModal(context, medication),
            ),
          ),
        ],
      ),
    );
  }

  void _showFlashRequestModal(BuildContext context, Medication medication) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Demande Flash de Disponibilité',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Votre demande pour "${medication.nomCommercial}" va être diffusée équitablement (Round-Robin ONPC) aux 3 pharmacies les plus proches de votre repère à Yaoundé.',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Temps de réponse garanti : moins de 5 minutes. Une notification vous préviendra dès qu’un pharmacien confirme le produit en rayon.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Demande flash transmise pour ${medication.nomCommercial} !'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Text('Confirmer & Lancer la Demande Flash'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 64, color: AppColors.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'Aucun médicament trouvé',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Vérifiez l’orthographe ou effectuez une recherche par DCI (ex: Paracétamol).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
