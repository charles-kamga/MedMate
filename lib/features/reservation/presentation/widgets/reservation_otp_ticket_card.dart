import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../pharmacy_search/domain/entities/reservation.dart';
import '../../domain/entities/flash_order.dart';
import '../controllers/flash_reservation_cubit.dart';

/// Ticket récapitulatif de réservation avec Code OTP à 6 chiffres (< 280 lignes).
class ReservationOtpTicketCard extends StatelessWidget {
  const ReservationOtpTicketCard({
    super.key,
    this.reservation,
    this.order,
    this.onNewSearch,
    this.onOpenOsmRoute,
    this.onCallPharmacy,
    this.cubit,
  });

  final Reservation? reservation;
  final FlashOrder? order;
  final VoidCallback? onNewSearch;
  final void Function(String osmUrl)? onOpenOsmRoute;
  final void Function(String phone)? onCallPharmacy;
  final FlashReservationCubit? cubit;

  FlashReservationCubit? _getCubit(BuildContext context) {
    if (cubit != null) return cubit;
    try {
      return context.read<FlashReservationCubit>();
    } catch (_) {
      return null;
    }
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  void _handleOsm(BuildContext context, Reservation res) {
    final url = AppConfig.buildOsmSearchUrl(
        latitude: 3.8667, longitude: 11.5200, label: res.pharmacyName,);
    onOpenOsmRoute != null
        ? onOpenOsmRoute!(url)
        : ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Itinéraire OSM : $url'),
            backgroundColor: AppColors.primary,),);
  }

  void _handleCall(BuildContext context, String phone) {
    onCallPharmacy != null
        ? onCallPharmacy!(phone)
        : ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Appel officine : $phone'),
            backgroundColor: AppColors.secondary,),);
  }

  void _copyOtp(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Code OTP copié'),
      backgroundColor: Color(0xFF10B981),
      duration: Duration(seconds: 2),
    ),);
  }

  @override
  Widget build(BuildContext context) {
    final fc = _getCubit(context);
    final res = reservation ?? fc?.state.confirmedReservation;
    final resolvedOrder = order ?? fc?.state.currentOrder;

    if (res == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),),
        child: const Center(
            child: Text('Aucune réservation confirmée.',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary),),),
      );
    }

    final isExpired = res.isExpired;
    final phone = resolvedOrder?.selectedOffer?.phone ?? '+237 677 12 34 56';
    final totalAmount = resolvedOrder?.selectedOffer?.grandTotalCfa;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF10B981), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Color(0xFFEAF7F0), shape: BoxShape.circle,),
                child: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF10B981), size: 28,),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Réservation confirmée !',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.textPrimary,),),
                    const SizedBox(height: 2),
                    Text(res.pharmacyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.primary,),),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isExpired ? AppColors.alertSoft : const Color(0xFFEAF7F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpired ? 'Expiré' : 'TTL 2h actif',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isExpired
                          ? AppColors.alert
                          : const Color(0xFF10B981),),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),),
            child: Column(
              children: [
                const Text('CODE DE RETRAIT AU COMPTOIR',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,),),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        res.codeRetraitOtp,
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: AppColors.primaryDark,),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 20, color: AppColors.primary,),
                      tooltip: 'Copier le code OTP',
                      onPressed: () => _copyOtp(context, res.codeRetraitOtp),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                    "Valable jusqu'à ${_formatTime(res.expiresAt)} (2 heures)",
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,),),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Médicaments : ${res.medicationName}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,),),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('Quantité totale : ${res.quantite}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary,),),
                    if (totalAmount != null)
                      Text('Total à régler : $totalAmount FCFA',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.primary,),),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleOsm(context, res),
                  icon: const Icon(Icons.map_rounded, size: 18),
                  label: const Text('Itinéraire OSM'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleCall(context, phone),
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Appeler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => onNewSearch != null
                ? onNewSearch!()
                : _getCubit(context)?.reset(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Effectuer une nouvelle recherche'),
            style:
                TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
