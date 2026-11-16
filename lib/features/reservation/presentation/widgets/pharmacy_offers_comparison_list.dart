import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';
import '../controllers/flash_reservation_cubit.dart';
import 'pharmacy_offer_comparison_card.dart';

/// Comparateur d'offres reçues des officines partenaires (< 300 lignes).
/// Prix exclusivement communiqué par le pharmacien (zéro prix catalogue).
class PharmacyOffersComparisonList extends StatelessWidget {
  const PharmacyOffersComparisonList({
    super.key,
    this.offers,
    this.onSelectOffer,
    this.isLoading = false,
    this.cubit,
  });

  final List<PharmacyOffer>? offers;
  final void Function(PharmacyOffer offer, String phone)? onSelectOffer;
  final bool isLoading;
  final FlashReservationCubit? cubit;

  FlashReservationCubit? _getCubit(BuildContext context) {
    if (cubit != null) return cubit;
    try {
      return context.read<FlashReservationCubit>();
    } catch (_) {
      return null;
    }
  }

  void _promptPhoneAndSelect(BuildContext context, PharmacyOffer offer) {
    final phoneController = TextEditingController(text: '+237 ');
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Confirmer la sélection',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pharmacie : ${offer.pharmacyName}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Montant : ${offer.grandTotalCfa} FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Numéro de téléphone pour le retrait :',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '+237 6XX XX XX XX',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;
              Navigator.of(dialogCtx).pop();
              if (onSelectOffer != null) {
                onSelectOffer!(offer, phone);
              } else {
                _getCubit(context)?.selectOffer(offer, patientPhone: phone);
              }
            },
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = offers ??
        _getCubit(context)?.state.currentOrder?.offers ??
        const <PharmacyOffer>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Offres reçues des pharmacies (${list.length})',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Choix libre',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Comparez les montants réels et disponibilités déclarés par chaque officine.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'En attente des devis des officines contactées...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ...list.map(
              (offer) => PharmacyOfferComparisonCard(
                offer: offer,
                isLoading: isLoading,
                onSelect: () => _promptPhoneAndSelect(context, offer),
              ),
            ),
        ],
      ),
    );
  }
}
