import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pharmacy_offer.dart';

/// Carte individuelle d'une offre officinale dans la liste de comparaison patient
class PharmacyOfferComparisonCard extends StatelessWidget {
  const PharmacyOfferComparisonCard({
    required this.offer,
    required this.isLoading,
    required this.onSelect,
    super.key,
  });

  final PharmacyOffer offer;
  final bool isLoading;
  final VoidCallback onSelect;

  Widget _buildAvailabilityBadge(PharmacyAvailabilityType type) {
    final (label, textColor, bgColor) = switch (type) {
      PharmacyAvailabilityType.fullyAvailable => (
          'Disponible',
          const Color(0xFF10B981),
          const Color(0xFFEAF7F0),
        ),
      PharmacyAvailabilityType.conditional ||
      PharmacyAvailabilityType.partiallyAvailable =>
        (
          'Disponible sous conditions',
          const Color(0xFFF59E0B),
          const Color(0xFFFEF3C7),
        ),
      PharmacyAvailabilityType.unavailable => (
          'Indisponible',
          AppColors.textSecondary,
          AppColors.surfaceVariant,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasConditions =
        (offer.conditionNote != null && offer.conditionNote!.isNotEmpty) ||
            offer.conditionRequirements.isNotEmpty;
    final hasPhone = offer.phone.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: offer.isAccepted ? AppColors.primary : AppColors.border,
          width: offer.isAccepted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.pharmacyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${offer.quarter} • à ${offer.distanceKm.toStringAsFixed(1)} km',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasPhone ? offer.phone : 'Numéro non communiqué',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle:
                            hasPhone ? FontStyle.normal : FontStyle.italic,
                        color: hasPhone
                            ? AppColors.textSecondary
                            : AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildAvailabilityBadge(offer.availabilityType),
          ),
          if (hasConditions) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      offer.conditionNote ??
                          offer.conditionRequirements.join(', '),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${offer.quotedPriceCfa} FCFA',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Text(
                      'Prix exclusif proposé par le pharmacien',
                      style: TextStyle(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (offer.proposesDelivery)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${offer.deliveryFeeCfa} F livr. (~${offer.estimatedDeliveryMinutes ?? 30}m)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                )
              else
                const Text(
                  'Retrait en officine',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: (isLoading ||
                      offer.availabilityType ==
                          PharmacyAvailabilityType.unavailable)
                  ? null
                  : onSelect,
              icon: Icon(
                offer.isAccepted
                    ? Icons.check_circle_rounded
                    : Icons.check_rounded,
                size: 18,
              ),
              label: Text(
                offer.isAccepted
                    ? 'Pharmacie choisie'
                    : 'Choisir cette pharmacie',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: offer.isAccepted
                    ? const Color(0xFF10B981)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
