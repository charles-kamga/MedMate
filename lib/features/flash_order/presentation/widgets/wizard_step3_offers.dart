import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import '../cubit/flash_order_cubit.dart';

/// Étape 3 du wizard V2 : comparateur d'offres reçues par le patient.
class WizardStep3Offers extends StatelessWidget {
  const WizardStep3Offers({required this.order, super.key});

  final FlashOrder order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offres reçues (${order.offers.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Comparez et retenez l’offre de votre choix.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              tooltip: 'Rafraîchir',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (order.offers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'En attente de la transmission des offres par les pharmaciens...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...order.offers.map((offer) => _buildOfferCard(context, offer)),
        const SizedBox(height: 12),
        if (order.offers.length < 2)
          Center(
            child: TextButton.icon(
              onPressed: () {
                context.read<FlashOrderCubit>().accelerateWave();
              },
              icon: const Icon(
                Icons.radar_rounded,
                size: 16,
                color: AppColors.secondary,
              ),
              label: const Text(
                'Élargir la recherche aux pharmacies suivantes',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOfferCard(BuildContext context, PharmacyOffer offer) {
    final isPartial =
        offer.availabilityType == PharmacyAvailabilityType.partiallyAvailable;
    final isConditional =
        offer.availabilityType == PharmacyAvailabilityType.conditional;

    return BentoCard(
      margin: const EdgeInsets.only(bottom: 14),
      backgroundColor: Colors.white,
      borderColor: offer.isAccepted ? AppColors.primary : AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.pharmacyName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📍 ${offer.quarter} · ${offer.distanceKm} km',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${offer.grandTotalCfa} FCFA',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                  const Text(
                    'Prix fixé par l’officine',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPartial)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ Disponibilité partielle (${offer.availableItemIds.length}/${order.items.length} produits disponibles)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            )
          else if (isConditional)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ℹ️ Disponible sous conditions : ${offer.conditionRequirements.join(', ')}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '✓ Panier 100% disponible en stock',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          if (offer.proposesDelivery) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.delivery_dining_rounded,
                  size: 16,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Livraison proposée : +${offer.deliveryFeeCfa} FCFA (~${offer.estimatedDeliveryMinutes ?? 30} min)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                context.read<FlashOrderCubit>().selectOffer(offer.id);
              },
              child: const Text(
                'Choisir cette pharmacie →',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
