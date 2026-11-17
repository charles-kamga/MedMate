import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'patient_home_shared_widgets.dart';

/// Étape 3 du parcours patient : fiche détaillée d'une pharmacie.
class PatientHomeStep3DetailView extends StatelessWidget {
  const PatientHomeStep3DetailView({
    required this.pharmacy,
    required this.city,
    required this.medicines,
    required this.selectedIndices,
    required this.onSeeRoute,
    required this.onShowNotice,
    super.key,
  });

  final PharmacyDemoData pharmacy;
  final String city;
  final List<String> medicines;
  final List<int> selectedIndices;
  final VoidCallback onSeeRoute;
  final ValueChanged<String> onShowNotice;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pharmacy.name,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '📍 $city · ${pharmacy.distance}',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),
        _buildAvailabilityCard(),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSeeRoute,
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => onShowNotice(
                  'Numéro fictif de démonstration (${pharmacy.phone}) : à remplacer par le numéro vérifié de la pharmacie.',
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
                onPressed: () => onShowNotice(
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
        const PatientHomeNoticeBanner(
          text:
              'La disponibilité des stocks est déclarée par les pharmacies partenaires. Le tarif officiel est appliqué directement au comptoir lors de votre passage.',
        ),
      ],
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
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
          ...selectedIndices.map((index) {
            final isAvailable = pharmacy.stock.contains(index);
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? AppColors.primarySoft
                          : AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAvailable ? 'En stock' : 'Sur commande',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isAvailable ? AppColors.primary : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tarification officielle',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Au comptoir',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Prix fixé directement par l’officine selon la réglementation pharmaceutique en vigueur. Aucun paiement direct requis dans cette version.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
