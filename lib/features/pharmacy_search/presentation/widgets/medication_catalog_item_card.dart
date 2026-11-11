import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/medication.dart';

/// Carte d'un médicament du catalogue (Zéro prix catalogue : tarif au comptoir)
class MedicationCatalogItemCard extends StatelessWidget {
  const MedicationCatalogItemCard({
    required this.medication,
    required this.onFlashRequest,
    super.key,
  });

  final Medication medication;
  final VoidCallback onFlashRequest;

  @override
  Widget build(BuildContext context) {
    return BentoCard(
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
                      medication.nomCommercial,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'DCI : ${medication.dci}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tarif au comptoir',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
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
              _tag(
                '${medication.forme} • ${medication.dosage}',
                AppColors.textSecondary,
                AppColors.surfaceVariant,
                bold: false,
              ),
              if (medication.necessiteOrdonnance)
                _tag('Ordonnance requise', AppColors.warning, AppColors.warningSoft)
              else
                _tag('Vente libre', AppColors.success, AppColors.successSoft),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.bolt_rounded, size: 18),
              label: const Text('Demande Flash Proximité (Ping 3-5 min)'),
              onPressed: onFlashRequest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text, Color color, Color bg, {bool bold = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: color,
        ),
      ),
    );
  }
}
