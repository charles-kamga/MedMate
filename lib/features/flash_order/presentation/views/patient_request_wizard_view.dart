import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';

/// Vue interactive complète du parcours patient Afya Santé V2 :
/// 1. Panier intelligent multi-médicaments & Localisation (sans pharmacie imposée)
/// 2. Radar de recherche en vagues (2 pharmacies / 2 minutes)
/// 3. Comparateur d'offres reçues (prix fixé par pharmacien, conditions, livraison)
/// 4. Réservation, Choix paiement & Code OTP de retrait
class PatientRequestWizardView extends StatefulWidget {
  const PatientRequestWizardView({super.key});

  @override
  State<PatientRequestWizardView> createState() => _PatientRequestWizardViewState();
}

class _PatientRequestWizardViewState extends State<PatientRequestWizardView> {
  final _phoneController = TextEditingController(text: '699112233');
  FlashPaymentMethod _paymentMethod = FlashPaymentMethod.cashCounter;

  // Catalogue pour ajout rapide au panier
  static const List<Medication> _catalog = [
    Medication(
      id: 'med-paracetamol',
      nomCommercial: 'Paracétamol 500 mg',
      dci: 'Paracétamol',
      forme: 'Comprimé',
      dosage: '500 mg',
      classeTherapeutique: 'Antalgique / Antipyrétique',
      prixHomologueCfa: 1500,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-vitaminc',
      nomCommercial: 'Vitamine C 1000 mg',
      dci: 'Acide ascorbique',
      forme: 'Comprimé effervescent',
      dosage: '1000 mg',
      classeTherapeutique: 'Vitamines',
      prixHomologueCfa: 2000,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-amox',
      nomCommercial: 'Amoxicilline 500 mg',
      dci: 'Amoxicilline',
      forme: 'Gélule',
      dosage: '500 mg',
      classeTherapeutique: 'Antibiotique Bêta-lactamine',
      prixHomologueCfa: 3200,
      necessiteOrdonnance: true,
    ),
    Medication(
      id: 'med-coartem',
      nomCommercial: 'Coartem 20/120',
      dci: 'Artéméther + Luméfantrine',
      forme: 'Comprimé',
      dosage: '20 mg / 120 mg',
      classeTherapeutique: 'Antipaludique (CTA)',
      prixHomologueCfa: 2800,
      necessiteOrdonnance: false,
    ),
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashOrderCubit, FlashOrderState>(
      builder: (context, state) {
        final order = state.activeOrder;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            if (order == null)
              _buildStep1Basket(context, state)
            else if (order.status == FlashOrderStatus.dispatchingWave && !state.hasOffers)
              _buildStep2WaveRadar(context, state, order)
            else if (order.status == FlashOrderStatus.dispatchingWave || order.status == FlashOrderStatus.offersReceived)
              _buildStep3OffersComparison(context, state, order)
            else
              _buildStep4Confirmation(context, state, order),
          ],
        );
      },
    );
  }

  // ===========================================================================
  // ÉTAPE 1 : PANIER MULTI-MÉDICAMENTS & LOCALISATION
  // ===========================================================================
  Widget _buildStep1Basket(BuildContext context, FlashOrderState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête Afya Santé
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 24),
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
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Sélecteur de localisation
        BentoCard(
          backgroundColor: Colors.white,
          borderColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 20),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    child: Text('${lm.nom} (${lm.quartier})', style: const TextStyle(fontSize: 14)),
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

        // Contenu du panier
        Text(
          'Médicaments recherchés (${state.basketItems.length})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                          Text(
                            '${item.medication.dci} · ${item.medication.dosage}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (item.medication.necessiteOrdonnance)
                            Row(
                              children: [
                                Checkbox(
                                  value: item.hasPrescription,
                                  activeColor: AppColors.primary,
                                  onChanged: (_) {
                                    context.read<FlashOrderCubit>().togglePrescription(item.id);
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'Ordonnance disponible',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
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
                          icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textSecondary),
                          onPressed: () {
                            context.read<FlashOrderCubit>().updateBasketItemQuantity(item.id, item.quantity - 1);
                          },
                        ),
                        Text(
                          '${item.quantity}',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                          onPressed: () {
                            context.read<FlashOrderCubit>().updateBasketItemQuantity(item.id, item.quantity + 1);
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

        // Ajout rapide depuis le catalogue
        const Text(
          'Ajouter un autre médicament :',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _catalog.map((med) {
            final isInBasket = state.basketItems.any((i) => i.medication.id == med.id);
            return ActionChip(
              backgroundColor: isInBasket ? AppColors.primarySoft : Colors.white,
              side: BorderSide(color: isInBasket ? AppColors.primary : AppColors.border),
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

        // Mention légale de non-fixation des prix
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.secondarySoft.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Afya Santé ne fixe aucun tarif à l’avance. Les officines sollicitées vous communiqueront leurs prix officiels en direct.',
                  style: TextStyle(fontSize: 12, color: AppColors.textPrimary, height: 1.3),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Bouton de lancement
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  // ===========================================================================
  // ÉTAPE 2 : RADAR DE RECHERCHE EN VAGUES (2 PHARMA / 2 MINUTES)
  // ===========================================================================
  Widget _buildStep2WaveRadar(BuildContext context, FlashOrderState state, FlashOrder order) {
    final minutes = (order.waveTimeRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (order.waveTimeRemainingSeconds % 60).toString().padLeft(2, '0');

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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'VAGUE ${order.currentWave} / 2',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '$minutes:$seconds',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
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
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Demande transmise aux 2 officines les plus proches de ${order.quarter}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              // Bouton accélérateur de démo
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: isWaiting ? AppColors.surfaceVariant : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    target.waveIndex == 1 ? '①' : '②',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: isWaiting ? AppColors.textSecondary : AppColors.primary,
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
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      Text(
                        '${target.quarter} · ${target.distanceKm} km',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isWaiting ? const Color(0xFFF1F5F9) : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isWaiting ? 'En attente...' : 'Réponse prête',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isWaiting ? AppColors.textSecondary : AppColors.primary,
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
            child: const Text('Annuler la recherche', style: TextStyle(color: AppColors.alert)),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // ÉTAPE 3 : COMPARATEUR D'OFFRES REÇUES (LE PATIENT CHOISIT LIBREMENT)
  // ===========================================================================
  Widget _buildStep3OffersComparison(BuildContext context, FlashOrderState state, FlashOrder order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Offres reçues (${order.offers.length})',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Comparez et retenez l’offre de votre choix.',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
              tooltip: 'Rafraîchir',
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (order.offers.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'En attente de la transmission des offres par les pharmaciens...',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        else
          ...order.offers.map((offer) {
            final isPartial = offer.availabilityType == PharmacyAvailabilityType.partiallyAvailable;
            final isConditional = offer.availabilityType == PharmacyAvailabilityType.conditional;

            return BentoCard(
              margin: const EdgeInsets.only(bottom: 14),
              backgroundColor: Colors.white,
              borderColor: offer.isAccepted ? AppColors.primary : AppColors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.pharmacyName,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '📍 ${offer.quarter} · ${offer.distanceKm} km',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${offer.grandTotalCfa} FCFA',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            'Prix fixé par l’officine',
                            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Statut disponibilité
                  if (isPartial)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '⚠️ Disponibilité partielle (${offer.availableItemIds.length}/${order.items.length} produits disponibles)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                      ),
                    )
                  else if (isConditional)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ℹ️ Disponible sous conditions : ${offer.conditionRequirements.join(', ')}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.secondary),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '✓ Panier 100% disponible en stock',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),

                  if (offer.proposesDelivery) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded, size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          'Livraison proposée : +${offer.deliveryFeeCfa} FCFA (~${offer.estimatedDeliveryMinutes ?? 30} min)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.read<FlashOrderCubit>().selectOffer(offer.id);
                      },
                      child: const Text(
                        'Choisir cette pharmacie →',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 12),
        // Accélérateur pour démo si moins de 2 offres
        if (order.offers.length < 2)
          Center(
            child: TextButton.icon(
              onPressed: () {
                context.read<FlashOrderCubit>().accelerateWave();
              },
              icon: const Icon(Icons.radar_rounded, size: 16, color: AppColors.secondary),
              label: const Text(
                'Élargir la recherche aux pharmacies suivantes',
                style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // ÉTAPE 4 : CONFIRMATION, RÈGLEMENT & CODE OTP DE RETRAIT
  // ===========================================================================
  Widget _buildStep4Confirmation(BuildContext context, FlashOrderState state, FlashOrder order) {
    final offer = order.selectedOffer;
    final isReady = order.status == FlashOrderStatus.readyForPickup || order.status == FlashOrderStatus.delivered;

    if (!isReady) {
      // Écran de finalisation du choix de paiement
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validation de votre réservation',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Officine sélectionnée : ${offer?.pharmacyName ?? "Pharmacie"}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Récapitulatif montant
          BentoCard(
            backgroundColor: AppColors.primarySoft,
            borderColor: AppColors.primary.withValues(alpha: 0.3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Montant à régler',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Devis pharmacien validé',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  '${offer?.grandTotalCfa ?? 0} FCFA',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Choix du mode de règlement
          const Text(
            'Mode de règlement :',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 10),

          ...FlashPaymentMethod.values.map((method) {
            final isSelected = _paymentMethod == method;
            String title;
            String subtitle;
            IconData icon;
            switch (method) {
              case FlashPaymentMethod.cashCounter:
                title = 'Paiement au comptoir (Espèces ou Mobile Money sur place)';
                subtitle = 'Réservation bloquée 2h avec code de retrait OTP officiel';
                icon = Icons.storefront_rounded;
              case FlashPaymentMethod.orangeMoney:
                title = 'Orange Money Cameroun (+237)';
                subtitle = 'Règlement direct in-app sécurisé';
                icon = Icons.phone_android_rounded;
              case FlashPaymentMethod.mtnMoMo:
                title = 'MTN Mobile Money (+237)';
                subtitle = 'Règlement direct in-app sécurisé';
                icon = Icons.account_balance_wallet_rounded;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              color: isSelected ? AppColors.primarySoft : Colors.white,
              child: ListTile(
                leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
                trailing: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
                onTap: () {
                  setState(() => _paymentMethod = method);
                },
              ),
            );
          }),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () {
                context.read<FlashOrderCubit>().confirmPayment(
                      method: _paymentMethod,
                      phoneNumber: _phoneController.text,
                    );
              },
              child: const Text(
                'Confirmer la réservation & Obtenir le code OTP →',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      );
    }

    // Écran avec Code OTP généré
    final isDelivered = order.status == FlashOrderStatus.delivered || order.isPickedUp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: isDelivered ? AppColors.primary : AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isDelivered ? Icons.check_circle : Icons.qr_code_scanner_rounded,
            color: isDelivered ? Colors.white : AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          isDelivered ? 'Médicaments retirés avec succès !' : 'Réservation confirmée !',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          isDelivered
              ? 'Délivrance effectuée par ${offer?.pharmacyName ?? "la pharmacie"}.'
              : 'Présentez ce code unique au comptoir de ${offer?.pharmacyName ?? "la pharmacie"}.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),

        // Carte OTP
        BentoCard(
          backgroundColor: isDelivered ? AppColors.primarySoft : Colors.white,
          borderColor: isDelivered ? AppColors.primary : AppColors.border,
          child: Column(
            children: [
              const Text(
                'CODE DE RETRAIT UNIQUE (OTP)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  order.reservationOtpCode ?? 'RET-000000',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    isDelivered ? 'Retrait validé au comptoir' : 'Validité : 2 heures au comptoir',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Récapitulatif
        BentoCard(
          backgroundColor: Colors.white,
          borderColor: AppColors.border,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Détails de la réservation',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pharmacie :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(offer?.pharmacyName ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Localisation :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(offer?.quarter ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Téléphone :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text(offer?.phone ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Montant total :', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text('${offer?.grandTotalCfa ?? 0} FCFA', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () {
              context.read<FlashOrderCubit>().resetOrder();
            },
            child: const Text('Nouvelle recherche', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}
