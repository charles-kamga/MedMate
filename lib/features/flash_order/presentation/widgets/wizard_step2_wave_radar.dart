import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/flash_order.dart';
import '../cubit/flash_order_cubit.dart';

/// Étape 2 du wizard V2 : radar de recherche en vagues (2 pharmacies / 2 min).
class WizardStep2WaveRadar extends StatelessWidget {
  const WizardStep2WaveRadar({required this.order, super.key});

  final FlashOrder order;

  @override
  Widget build(BuildContext context) {
    final minutes =
        (order.waveTimeRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds =
        (order.waveTimeRemainingSeconds % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoCard(
          backgroundColor: AppColors.primarySoft,
          borderColor: AppColors.primary.withValues(alpha: 0.3),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'VAGUE ${order.currentWave} / 2',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sollicitation des pharmacies partenaires',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Demande transmise aux 2 officines les plus proches de ${order.quarter}.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  context.read<FlashOrderCubit>().accelerateWave();
                },
                icon: const Icon(Icons.fast_forward_rounded, size: 16),
                label: const Text(
                  'Accélérer l’escalade (Démo 2 min)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Officines contactées dans cette vague :',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ...order.targets.map((target) {
          final isWaiting = target.status == PharmacistReplyType.waiting;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isWaiting
                        ? AppColors.surfaceVariant
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    target.waveIndex == 1 ? '①' : '②',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isWaiting
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        target.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${target.quarter} · ${target.distanceKm} km',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isWaiting
                        ? const Color(0xFFF1F5F9)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isWaiting ? 'En attente...' : 'Réponse prête',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isWaiting
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              context.read<FlashOrderCubit>().resetOrder();
            },
            child: const Text(
              'Annuler la recherche',
              style: TextStyle(color: AppColors.alert),
            ),
          ),
        ),
      ],
    );
  }
}
