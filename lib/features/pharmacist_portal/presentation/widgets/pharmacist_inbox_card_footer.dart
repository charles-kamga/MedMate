import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';

/// Pied de carte de la boîte de réception pharmacien avec statut de devis et actions rapides
class PharmacistInboxCardFooter extends StatelessWidget {
  const PharmacistInboxCardFooter({
    required this.order,
    required this.hasSubmittedQuote,
    super.key,
    this.onQuotePressed,
    this.onValidateOtpPressed,
  });

  final FlashOrder order;
  final bool hasSubmittedQuote;
  final VoidCallback? onQuotePressed;
  final VoidCallback? onValidateOtpPressed;

  static const Color _emerald = Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    final canValidateOtp = order.status == FlashOrderStatus.readyForPickup ||
        order.status == FlashOrderStatus.accepted;
    final isDelivered = order.status == FlashOrderStatus.delivered;

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        if (hasSubmittedQuote)
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 14, color: _emerald),
              SizedBox(width: 4),
              Text(
                'Devis transmis',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _emerald,
                ),
              ),
            ],
          )
        else
          Text(
            isDelivered ? 'Retrait effectué' : 'Action requise',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            if (!isDelivered && onQuotePressed != null)
              TextButton.icon(
                key: ValueKey('btn_quote_${order.id}'),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onQuotePressed,
                icon: const Icon(Icons.request_quote_outlined, size: 15),
                label: Text(
                  hasSubmittedQuote ? 'Modifier devis' : 'Émettre un devis',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (canValidateOtp && onValidateOtpPressed != null)
              ElevatedButton.icon(
                key: ValueKey('btn_otp_${order.id}'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: _emerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: onValidateOtpPressed,
                icon: const Icon(Icons.dialpad_rounded, size: 15),
                label: const Text(
                  'Valider retrait OTP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
