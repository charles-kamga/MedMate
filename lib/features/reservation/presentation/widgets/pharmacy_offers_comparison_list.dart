import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/pharmacy_offer.dart';
import '../controllers/flash_reservation_cubit.dart';

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
        title: const Text('Confirmer la sélection',
            style: TextStyle(fontWeight: FontWeight.w700),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pharmacie : ${offer.pharmacyName}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),),
            const SizedBox(height: 4),
            Text('Montant : ${offer.grandTotalCfa} FCFA',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    fontSize: 14,),),
            const SizedBox(height: 12),
            const Text('Numéro de téléphone pour le retrait :',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),),
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
              child: const Text('Annuler'),),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,),
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

  Widget _buildAvailabilityBadge(PharmacyAvailabilityType type) {
    String label;
    Color textColor;
    Color bgColor;

    switch (type) {
      case PharmacyAvailabilityType.fullyAvailable:
        label = 'Disponible';
        textColor = const Color(0xFF10B981); // Émeraude
        bgColor = const Color(0xFFEAF7F0);
      case PharmacyAvailabilityType.conditional:
      case PharmacyAvailabilityType.partiallyAvailable:
        label = 'Disponible sous conditions';
        textColor = const Color(0xFFF59E0B); // Ambre
        bgColor = const Color(0xFFFEF3C7);
      case PharmacyAvailabilityType.unavailable:
        label = 'Indisponible';
        textColor = AppColors.textSecondary;
        bgColor = AppColors.surfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: textColor,),),
    );
  }

  Widget _buildOfferCard(BuildContext context, PharmacyOffer offer) {
    final hasConditions =
        (offer.conditionNote != null && offer.conditionNote!.isNotEmpty) ||
            offer.conditionRequirements.isNotEmpty;

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
                    borderRadius: BorderRadius.circular(10),),
                child: const Icon(Icons.local_pharmacy_rounded,
                    color: AppColors.primary, size: 22,),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.pharmacyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textPrimary,),),
                    const SizedBox(height: 2),
                    Text(
                        '${offer.quarter} • à ${offer.distanceKm.toStringAsFixed(1)} km',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary,),),
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
                  borderRadius: BorderRadius.circular(8),),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 16, color: Color(0xFFF59E0B),),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      offer.conditionNote ??
                          offer.conditionRequirements.join(', '),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),),
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
                    Text('${offer.quotedPriceCfa} FCFA',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                            color: AppColors.textPrimary,),),
                    const Text('Prix exclusif proposé par le pharmacien',
                        style: TextStyle(
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textTertiary,),
                        overflow: TextOverflow.ellipsis,),
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
                      borderRadius: BorderRadius.circular(8),),
                  child: Text(
                    '+${offer.deliveryFeeCfa} F livr. (~${offer.estimatedDeliveryMinutes ?? 30}m)',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,),
                  ),
                )
              else
                const Text('Retrait en officine',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary,),),
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
                  : () => _promptPhoneAndSelect(context, offer),
              icon: Icon(
                  offer.isAccepted
                      ? Icons.check_circle_rounded
                      : Icons.check_rounded,
                  size: 18,),
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
                    borderRadius: BorderRadius.circular(12),),
                elevation: 0,
              ),
            ),
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
                      color: AppColors.textPrimary,),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F0),
                    borderRadius: BorderRadius.circular(8),),
                child: const Text('Choix libre',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),),),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
              'Comparez les montants réels et disponibilités déclarés par chaque officine.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),),
          const SizedBox(height: 12),
          if (list.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),),
              child: const Column(
                children: [
                  SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary,),),
                  SizedBox(height: 10),
                  Text('En attente des devis des officines contactées...',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,),),
                ],
              ),
            )
          else
            ...list.map((offer) => _buildOfferCard(context, offer)),
        ],
      ),
    );
  }
}
