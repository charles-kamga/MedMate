import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../../pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import '../../../pharmacy_search/presentation/controllers/medication_catalog_state.dart';

/// Résultats de recherche du catalogue et option de saisie libre d'un médicament.
class PatientBasketSearchResults extends StatelessWidget {
  const PatientBasketSearchResults({
    required this.query,
    required this.catalogCubit,
    required this.requiresPrescription,
    required this.onTogglePrescription,
    required this.onAddCatalogMedication,
    required this.onAddCustomMedication,
    super.key,
  });

  final String query;
  final MedicationCatalogCubit? catalogCubit;
  final bool requiresPrescription;
  final VoidCallback onTogglePrescription;
  final ValueChanged<Medication> onAddCatalogMedication;
  final VoidCallback onAddCustomMedication;

  @override
  Widget build(BuildContext context) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const SizedBox.shrink();

    if (catalogCubit == null) {
      return _buildCustomMedicationTile(trimmed);
    }

    return BlocBuilder<MedicationCatalogCubit, MedicationCatalogState>(
      bloc: catalogCubit,
      builder: (context, state) {
        if (state.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final hasMatches =
            state is MedicationCatalogLoaded && state.medications.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasMatches)
              Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: state.medications.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.borderSubtle),
                    itemBuilder: (context, index) {
                      final med = state.medications[index];
                      return ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.medication_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        title: Text(
                          med.nomCommercial,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          '${med.dci} • ${med.forme} (${med.dosage})',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        onTap: () => onAddCatalogMedication(med),
                      );
                    },
                  ),
                ),
              )
            else if (state is MedicationCatalogLoaded)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Aucun médicament homologué trouvé.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            _buildCustomMedicationTile(trimmed),
          ],
        );
      },
    );
  }

  Widget _buildCustomMedicationTile(String trimmedQuery) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTogglePrescription,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: Checkbox(
                    value: requiresPrescription,
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (_) => onTogglePrescription(),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Ordonnance à présenter au comptoir',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            key: const ValueKey('btn_add_custom_medication'),
            onPressed: onAddCustomMedication,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              'Ajouter « $trimmedQuery » à ma demande',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
