import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'patient_home_shared_widgets.dart';

/// Étape 1 du parcours patient : choix des médicaments.
class PatientHomeStep1ChooseView extends StatelessWidget {
  const PatientHomeStep1ChooseView({
    required this.medicines,
    required this.selectedIndices,
    required this.query,
    required this.searchController,
    required this.onQueryChanged,
    required this.onAdd,
    required this.onRemove,
    required this.onContinue,
    super.key,
  });

  final List<String> medicines;
  final List<int> selectedIndices;
  final String query;
  final TextEditingController searchController;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<int> onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final hits = medicines
        .asMap()
        .entries
        .where(
          (entry) =>
              entry.value.toLowerCase().contains(query.toLowerCase()) &&
              !selectedIndices.contains(entry.key),
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
        PatientHomeSearchField(
          controller: searchController,
          query: query,
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 16),
        _buildSearchResults(hits),
        const SizedBox(height: 24),
        Text(
          'Ma liste (${selectedIndices.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildSelectedList(),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: selectedIndices.isEmpty ? null : onContinue,
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

  Widget _buildSearchResults(List<MapEntry<int, String>> hits) {
    return Container(
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
                        onPressed: () => onAdd(entry.key),
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
    );
  }

  Widget _buildSelectedList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: selectedIndices.isEmpty
          ? const Text(
              'Votre liste est vide.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          : Column(
              children: selectedIndices.map((index) {
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
                        onPressed: () => onRemove(index),
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
    );
  }
}
