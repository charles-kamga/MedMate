import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bloc de sélection retrait / option livraison mototaxi du formulaire de devis.
class PharmacistQuoteDeliveryBox extends StatelessWidget {
  const PharmacistQuoteDeliveryBox({
    required this.enableDeliveryOption,
    required this.deliveryEnabled,
    required this.feeController,
    required this.minsController,
    required this.onDeliveryChanged,
    super.key,
  });

  final bool enableDeliveryOption;
  final bool deliveryEnabled;
  final TextEditingController feeController;
  final TextEditingController minsController;
  final ValueChanged<bool> onDeliveryChanged;

  @override
  Widget build(BuildContext context) {
    if (!enableDeliveryOption) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: AppColors.primary, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Retrait au comptoir uniquement (V1) · Paiement sur place',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            SwitchListTile(
              key: const ValueKey('switch_mototaxi'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              title: const Text(
                'Option mototaxi partenaire',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
              value: deliveryEnabled,
              onChanged: onDeliveryChanged,
            ),
            if (deliveryEnabled)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('input_delivery_fee'),
                      controller: feeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Frais (FCFA)',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      key: const ValueKey('input_delivery_minutes'),
                      controller: minsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Délai (min)',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
