import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';

/// Carte de commande Flash pour la boîte de réception comptoir du pharmacien (< 400 lignes).
/// Affiche la liste des médicaments, quantités, mentions d'ordonnance, repère Yaoundé,
/// et le compte à rebours de vague respectueux de TickerMode.
class PharmacistRequestInboxCard extends StatelessWidget {
  const PharmacistRequestInboxCard({
    required this.order,
    super.key,
    this.isSelected = false,
    this.remainingSeconds,
    this.currentPharmacyId,
    this.onSelect,
    this.onQuotePressed,
    this.onValidateOtpPressed,
  });

  final FlashOrder order;
  final bool isSelected;
  final int? remainingSeconds;
  final String? currentPharmacyId;
  final VoidCallback? onSelect;
  final VoidCallback? onQuotePressed;
  final VoidCallback? onValidateOtpPressed;

  static const Color _emerald = Color(0xFF10B981);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _amberSoft = Color(0xFFFEF3C7);

  int get _effectiveSeconds => remainingSeconds ?? order.waveTimeRemainingSeconds;

  bool get _hasSubmittedQuote {
    if (currentPharmacyId == null) return false;
    return order.offers.any((o) => o.pharmacyId == currentPharmacyId);
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return 'Expiré';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tickerEnabled = TickerMode.valuesOf(context).enabled;
    final displaySeconds = tickerEnabled ? _effectiveSeconds : order.waveTimeRemainingSeconds;

    return Semantics(
      label: 'Demande flash #${order.id}',
      button: true,
      selected: isSelected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderRow(displaySeconds),
                const SizedBox(height: 10),
                _buildLandmarkRow(),
                const SizedBox(height: 10),
                _buildItemsList(),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                _buildFooterRow(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(int seconds) {
    final isExpired = seconds <= 0 || order.isExpired;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '#${order.id}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _buildStatusBadge(),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isExpired ? AppColors.alertSoft : const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isExpired ? AppColors.alert.withValues(alpha: 0.3) : _emerald.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer_outlined,
                size: 13,
                color: isExpired ? AppColors.alert : _emerald,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDuration(seconds),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isExpired ? AppColors.alert : _emerald,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color bg;
    Color fg;
    String label;

    switch (order.status) {
      case FlashOrderStatus.dispatchingWave:
        bg = const Color(0xFFEFF6FF);
        fg = AppColors.secondary;
        label = 'Vague ${order.currentWave} active';
        break;
      case FlashOrderStatus.offersReceived:
        bg = const Color(0xFFEFF6FF);
        fg = AppColors.secondary;
        label = 'Offres reçues';
        break;
      case FlashOrderStatus.accepted:
        bg = _amberSoft;
        fg = const Color(0xFFB45309);
        label = 'Offre retenue';
        break;
      case FlashOrderStatus.readyForPickup:
        bg = const Color(0xFFEAF7F0);
        fg = _emerald;
        label = 'Prêt pour retrait';
        break;
      case FlashOrderStatus.delivered:
        bg = const Color(0xFFEAF7F0);
        fg = AppColors.primary;
        label = 'Délivré au comptoir';
        break;
      case FlashOrderStatus.expired:
        bg = AppColors.alertSoft;
        fg = AppColors.alert;
        label = 'Expiré';
        break;
      case FlashOrderStatus.idle:
        bg = AppColors.surfaceVariant;
        fg = AppColors.textSecondary;
        label = 'En attente';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildLandmarkRow() {
    return Row(
      children: [
        const Icon(Icons.location_on_rounded, size: 15, color: AppColors.secondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            order.quarter,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '${order.items.length} produit(s)',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: order.items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${item.medication.nomCommercial} (Qté : ${item.quantity})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (item.hasPrescription)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: _amberSoft,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _amber.withValues(alpha: 0.4)),
                  ),
                  child: const Text(
                    'Ordonnance',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooterRow(BuildContext context) {
    final canValidateOtp = order.status == FlashOrderStatus.readyForPickup ||
        order.status == FlashOrderStatus.accepted;
    final isDelivered = order.status == FlashOrderStatus.delivered;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_hasSubmittedQuote)
          Row(
            children: const [
              Icon(Icons.check_circle_rounded, size: 14, color: _emerald),
              SizedBox(width: 4),
              Text(
                'Devis transmis',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _emerald),
              ),
            ],
          )
        else
          Text(
            isDelivered ? 'Retrait effectué' : 'Action requise',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isDelivered && onQuotePressed != null)
              TextButton.icon(
                key: ValueKey('btn_quote_${order.id}'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onQuotePressed,
                icon: const Icon(Icons.request_quote_outlined, size: 15),
                label: Text(
                  _hasSubmittedQuote ? 'Modifier devis' : 'Émettre un devis',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            if (canValidateOtp && onValidateOtpPressed != null) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                key: ValueKey('btn_otp_${order.id}'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  backgroundColor: _emerald,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onValidateOtpPressed,
                icon: const Icon(Icons.dialpad_rounded, size: 15),
                label: const Text(
                  'Valider retrait OTP',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
