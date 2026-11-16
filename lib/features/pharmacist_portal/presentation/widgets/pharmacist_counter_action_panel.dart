import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import 'counter_otp_validation_keypad.dart';
import 'pharmacist_quote_reply_sheet.dart';

/// Panneau latéral ou onglet de traitement d'une commande sélectionnée au comptoir
class PharmacistCounterActionPanel extends StatelessWidget {
  const PharmacistCounterActionPanel({
    required this.activePharmacyId,
    super.key,
    this.order,
  });

  final FlashOrder? order;
  final String activePharmacyId;

  @override
  Widget build(BuildContext context) {
    final currentOrder = order;
    if (currentOrder == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 48,
                color: AppColors.textTertiary,
              ),
              SizedBox(height: 12),
              Text(
                'Sélectionnez une commande dans la file',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Vous pourrez émettre votre offre chiffrée ou valider le retrait OTP.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (currentOrder.status == FlashOrderStatus.cancelled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cancel_outlined, size: 48, color: AppColors.alert),
              SizedBox(height: 12),
              Text(
                'Cette commande a été annulée par le patient.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.alert,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isReadyOrAccepted =
        currentOrder.status == FlashOrderStatus.readyForPickup ||
            currentOrder.status == FlashOrderStatus.accepted;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (isReadyOrAccepted)
            CounterOtpValidationKeypad(
              orderId: currentOrder.id,
              pharmacyId: activePharmacyId,
            )
          else
            PharmacistQuoteReplySheet(
              order: currentOrder,
              pharmacyId: activePharmacyId,
              isEmbedded: true,
            ),
        ],
      ),
    );
  }
}
