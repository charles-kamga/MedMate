import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';

/// Étape 1 du wizard V2 : composition du panier et localisation à Yaoundé.
class WizardStep1Basket extends StatelessWidget {
  const WizardStep1Basket({
    required this.state,
    required this.catalog,
    super.key,
  });

  final FlashOrderState state;
  final List<Medication> catalog;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recherche sans pharmacie imposée',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Formulez votre besoin. Afya Santé sollicite les officines à votre place.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        BentoCard(
          backgroundColor: Colors.white,
          borderColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Votre zone de recherche (Yaoundé)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: state.selectedQuarter,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                ),
                items: YaoundeLandmarks.list.map((lm) {
                  return DropdownMenuItem<String>(
                    value: '${lm.nom}, ${lm.quartier}',
                    child: Text(
                      '${lm.nom} (${lm.quartier})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    context.read<FlashOrderCubit>().selectQuarter(val);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Médicaments recherchés (${state.basketItems.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (state.basketItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Votre panier est vide.\nAjoutez au moins un médicament ci-dessous.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...state.basketItems.map((item) {
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text('💊', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.medication.nomCommercial,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${item.medication.dci} · ${item.medication.dosage}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (item.medication.necessiteOrdonnance)
                            Row(
                              children: [
                                Checkbox(
                                  value: item.hasPrescription,
                                  activeColor: AppColors.primary,
                                  onChanged: (_) {
                                    context
                                        .read<FlashOrderCubit>()
                                        .togglePrescription(item.id);
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'Ordonnance disponible',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            context
                                .read<FlashOrderCubit>()
                                .updateBasketItemQuantity(
                                  item.id,
                                  item.quantity - 1,
                                );
                          },
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            context
                                .read<FlashOrderCubit>()
                                .updateBasketItemQuantity(
                                  item.id,
                                  item.quantity + 1,
                                );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        const Text(
          'Ajouter un autre médicament :',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: catalog.map((med) {
            final isInBasket =
                state.basketItems.any((i) => i.medication.id == med.id);
            return ActionChip(
              backgroundColor:
                  isInBasket ? AppColors.primarySoft : Colors.white,
              side: BorderSide(
                color: isInBasket ? AppColors.primary : AppColors.border,
              ),
              label: Text(
                '${med.nomCommercial} ${isInBasket ? '✓' : '+'}',
                style: TextStyle(
                  color: isInBasket ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                context.read<FlashOrderCubit>().addBasketItem(med);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondarySoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Afya Santé ne fixe aucun tarif à l’avance. Les officines sollicitées vous communiqueront leurs prix officiels en direct.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: state.basketItems.isEmpty
                ? null
                : () {
                    context.read<FlashOrderCubit>().launchFlashOrder();
                  },
            child: const Text(
              'Lancer la recherche auprès des partenaires →',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
