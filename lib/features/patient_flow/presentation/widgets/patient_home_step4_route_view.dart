import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'patient_home_shared_widgets.dart';

/// Étape 4 du parcours patient : itinéraire vers la pharmacie sélectionnée.
class PatientHomeStep4RouteView extends StatelessWidget {
  const PatientHomeStep4RouteView({
    required this.pharmacy,
    required this.city,
    required this.medicines,
    required this.selectedIndices,
    required this.onOpenMaps,
    required this.onFinish,
    super.key,
  });

  final PharmacyDemoData pharmacy;
  final String city;
  final List<String> medicines;
  final List<int> selectedIndices;
  final VoidCallback onOpenMaps;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
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
          '${pharmacy.name} · $city',
          style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
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
              ...selectedIndices.map((index) {
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
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onOpenMaps,
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
        const PatientHomeNoticeBanner(
          text:
              "Vérifiez l'adresse exacte et la disponibilité avec la pharmacie avant votre déplacement.",
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onFinish,
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
}
