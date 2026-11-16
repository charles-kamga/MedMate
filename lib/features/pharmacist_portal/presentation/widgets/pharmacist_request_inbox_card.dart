import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import 'pharmacist_inbox_card_footer.dart';

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

  int get _effectiveSeconds =>
      remainingSeconds ?? order.waveTimeRemainingSeconds;

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
    final displaySeconds =
        tickerEnabled ? _effectiveSeconds : order.waveTimeRemainingSeconds;

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
                  color:
                      Colors.black.withValues(alpha: isSelected ? 0.06 : 0.02),
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
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.divider,
                ),
                const SizedBox(height: 10),
                PharmacistInboxCardFooter(
                  order: order,
                  hasSubmittedQuote: _hasSubmittedQuote,
                  onQuotePressed: onQuotePressed,
                  onValidateOtpPressed: onValidateOtpPressed,
                ),
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
              Flexible(child: _buildStatusBadge()),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isExpired ? AppColors.alertSoft : const Color(0xFFEAF7F0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isExpired
                  ? AppColors.alert.withValues(alpha: 0.3)
                  : _emerald.withValues(alpha: 0.4),
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
    final (bg, fg, label) = switch (order.status) {
      FlashOrderStatus.dispatchingWave => (
          const Color(0xFFEFF6FF),
          AppColors.secondary,
          'Vague ${order.currentWave} active'
        ),
      FlashOrderStatus.offersReceived => (
          const Color(0xFFEFF6FF),
          AppColors.secondary,
          'Offres reçues'
        ),
      FlashOrderStatus.accepted => (
          _amberSoft,
          const Color(0xFFB45309),
          'Offre retenue'
        ),
      FlashOrderStatus.readyForPickup => (
          const Color(0xFFEAF7F0),
          _emerald,
          'Prêt pour retrait'
        ),
      FlashOrderStatus.delivered => (
          const Color(0xFFEAF7F0),
          AppColors.primary,
          'Délivré au comptoir'
        ),
      FlashOrderStatus.expired => (
          AppColors.alertSoft,
          AppColors.alert,
          'Expiré'
        ),
      FlashOrderStatus.cancelled => (
          AppColors.alertSoft,
          AppColors.alert,
          'Annulée'
        ),
      FlashOrderStatus.idle => (
          AppColors.surfaceVariant,
          AppColors.textSecondary,
          'En attente'
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildLandmarkRow() {
    final phone = order.phoneNumber?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 15,
              color: AppColors.secondary,
            ),
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
        ),
        if (order.phoneNumber != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.phone_outlined,
                size: 13,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                phone == null || phone.isEmpty
                    ? 'Numéro non communiqué'
                    : phone,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: phone == null || phone.isEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
                  color: phone == null || phone.isEmpty
                      ? AppColors.textTertiary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
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
}
