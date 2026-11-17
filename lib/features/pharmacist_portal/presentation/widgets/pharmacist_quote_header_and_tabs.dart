import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';

/// En-tête et onglets de disponibilité du formulaire de devis officine.
class PharmacistQuoteHeaderAndTabs extends StatelessWidget {
  const PharmacistQuoteHeaderAndTabs({
    required this.order,
    required this.selectedAvailability,
    required this.onAvailabilityChanged,
    super.key,
  });

  final FlashOrder order;
  final PharmacyAvailabilityType selectedAvailability;
  final ValueChanged<PharmacyAvailabilityType> onAvailabilityChanged;

  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Devis Officine — #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Secteur : ${order.quarter}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _tabItem(
              PharmacyAvailabilityType.fullyAvailable,
              'Disponible',
              emerald,
              Icons.check_circle_outline,
            ),
            const SizedBox(width: 8),
            _tabItem(
              PharmacyAvailabilityType.conditional,
              'Sous conditions',
              amber,
              Icons.info_outline,
            ),
            const SizedBox(width: 8),
            _tabItem(
              PharmacyAvailabilityType.unavailable,
              'Indisponible',
              AppColors.textSecondary,
              Icons.cancel_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _tabItem(
    PharmacyAvailabilityType type,
    String label,
    Color color,
    IconData icon,
  ) {
    final sel = selectedAvailability == type;
    return Expanded(
      child: InkWell(
        onTap: () => onAvailabilityChanged(type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                sel ? color.withValues(alpha: 0.12) : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: sel ? color : AppColors.border,
              width: sel ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 16,
                color: sel ? color : AppColors.textSecondary,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: sel ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
