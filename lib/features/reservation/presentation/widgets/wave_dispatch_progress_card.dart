import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../controllers/flash_reservation_cubit.dart';

/// Carte de suivi de la diffusion par vagues successives (Round-Robin) (< 250 lignes).
class WaveDispatchProgressCard extends StatelessWidget {
  const WaveDispatchProgressCard({
    super.key,
    this.order,
    this.onEscalate,
    this.isLoading = false,
    this.cubit,
  });

  final FlashOrder? order;
  final VoidCallback? onEscalate;
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

  Widget _buildStatusChip(PharmacistReplyType status) {
    String label;
    Color bg;
    Color text;

    switch (status) {
      case PharmacistReplyType.waiting:
        label = 'En attente...';
        bg = AppColors.secondarySoft;
        text = AppColors.secondary;
      case PharmacistReplyType.available:
        label = 'Offre reçue';
        bg = AppColors.successSoft;
        text = AppColors.success;
      case PharmacistReplyType.conditional:
        label = 'Sous conditions';
        bg = AppColors.warningSoft;
        text = AppColors.warning;
      case PharmacistReplyType.unavailable:
        label = 'Indisponible';
        bg = AppColors.surfaceVariant;
        text = AppColors.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: text,),),
    );
  }

  Widget _buildPharmacyTile(DispatchedPharmacy target) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
                color: AppColors.primarySoft, shape: BoxShape.circle,),
            child: const Icon(Icons.local_pharmacy_outlined,
                size: 18, color: AppColors.primary,),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(target.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary,),),
                const SizedBox(height: 2),
                Text(
                  '${target.quarter} • ${target.distanceKm.toStringAsFixed(1)} km (Vague ${target.waveIndex})',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary,),
                ),
              ],
            ),
          ),
          _buildStatusChip(target.status),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedOrder = order ?? _getCubit(context)?.state.currentOrder;

    if (resolvedOrder == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Aucune recherche flash en cours.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final wave = resolvedOrder.currentWave;
    final remaining = resolvedOrder.waveTimeRemainingSeconds.clamp(0, 120);
    final progress = (120 - remaining) / 120.0;

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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.waves_rounded,
                        size: 16, color: AppColors.primary,),
                    const SizedBox(width: 6),
                    Text('Vague $wave active',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: AppColors.primary,),),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(8),),
                child: const Text('Round-Robin 2 officines',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,),),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Repère urbain : ${resolvedOrder.quarter}',
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textPrimary,),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.borderSubtle,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            remaining > 0
                ? 'Progression de la vague courante ($remaining s restantes)'
                : 'Vague achevée — Vous pouvez escalader vers 2 autres officines',
            style:
                const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            'Officines partenaires consultées (${resolvedOrder.targets.length})',
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,),
          ),
          const SizedBox(height: 8),
          ...resolvedOrder.targets.map(_buildPharmacyTile),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: isLoading
                ? null
                : () {
                    if (onEscalate != null) {
                      onEscalate!();
                    } else {
                      _getCubit(context)?.escalateWave();
                    }
                  },
            icon: isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white,),)
                : const Icon(Icons.speed_rounded, size: 20),
            label: Text('Solliciter 2 pharmacies de plus (Vague ${wave + 1})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),),
              elevation: 0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dispatch éthique Afya Santé : respect du temps des pharmaciens par vagues de 2.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,),
          ),
        ],
      ),
    );
  }
}
