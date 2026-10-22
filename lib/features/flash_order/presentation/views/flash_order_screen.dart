import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../../domain/entities/flash_order.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';

/// Écran complet de démonstration du flux Commande Flash & Dispatch Multi-Pharmacies
class FlashOrderScreen extends StatefulWidget {
  const FlashOrderScreen({super.key});

  @override
  State<FlashOrderScreen> createState() => _FlashOrderScreenState();
}

class _FlashOrderScreenState extends State<FlashOrderScreen> {
  final _phoneController = TextEditingController(text: '699123456');
  FlashPaymentMethod _selectedPaymentMethod = FlashPaymentMethod.cashCounter;

  // Catalogue homologué pour le sélecteur rapide de médicament
  static const List<Medication> _availableMedications = [
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
    Medication(
      id: 'med-doliprane',
      nomCommercial: 'Doliprane 1000mg',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '1000 mg',
      classeTherapeutique: 'Antalgique / Antipyrétique',
      prixHomologueCfa: 1500,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-clamoxyl',
      nomCommercial: 'Clamoxyl 500mg',
      dci: 'Amoxicilline',
      forme: 'Gélule',
      dosage: '500 mg',
      classeTherapeutique: 'Antibiotique Bêta-lactamine',
      prixHomologueCfa: 3200,
      necessiteOrdonnance: true,
    ),
    Medication(
      id: 'med-advil',
      nomCommercial: 'Advil 400mg',
      dci: 'Ibuprofène',
      forme: 'Capsule molle',
      dosage: '400 mg',
      classeTherapeutique: 'Anti-inflammatoire',
      prixHomologueCfa: 2400,
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
        return Scaffold(
          appBar: AppBar(
            title: const Text('Commande Flash Démo'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Réinitialiser la démo',
                onPressed: () => context.read<FlashOrderCubit>().resetOrder(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment<UserRole>(
                      value: UserRole.patient,
                      label: Text('Vue Patient'),
                      icon: Icon(Icons.person_outline_rounded),
                    ),
                    ButtonSegment<UserRole>(
                      value: UserRole.pharmacist,
                      label: Text('Vue Pharmacien'),
                      icon: Icon(Icons.local_pharmacy_outlined),
                    ),
                  ],
                  selected: {state.userRole},
                  onSelectionChanged: (newSelection) {
                    context.read<FlashOrderCubit>().setRole(newSelection.first);
                  },
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: state.userRole == UserRole.patient
                ? _buildPatientView(context, state)
                : _buildPharmacistView(context, state),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // 1. VUE PATIENT
  // ===========================================================================

  Widget _buildPatientView(BuildContext context, FlashOrderState state) {
    final order = state.activeOrder;

    return SingleChildScrollView(
      key: const ValueKey('patient_view'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1.1 Si aucune commande lancée : formulaire de saisie
          if (order == null) ...[
            _buildMedicationSelectionCard(context, state),
            const SizedBox(height: 14),
            _buildLocationSelectionCard(context, state),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.bolt_rounded, size: 22),
              label: const Text(
                'Lancer la commande flash (2 à 3 pharmacies)',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => context.read<FlashOrderCubit>().launchFlashOrder(),
            ),
          ],

          // 1.2 Si commande en cours de dispatch (attente de réponse pharmacien)
          if (order != null && order.status == FlashOrderStatus.dispatching) ...[
            _buildDispatchingRadarCard(context, order),
            const SizedBox(height: 14),
            _buildPresenterTipCard(
              'Basculer en Vue Pharmacien',
              'Pour la démonstration, sélectionnez "Vue Pharmacien" ci-dessus pour simuler la réponse de l\'un des 3 officines.',
            ),
          ],

          // 1.3 Si une pharmacie a répondu et gagné la commande
          if (order != null && order.winnerPharmacy != null && order.status != FlashOrderStatus.confirmed) ...[
            _buildWinnerNotificationCard(context, order),
            const SizedBox(height: 14),
            _buildPaymentSelectionCard(context, order),
          ],

          // 1.4 Si la commande / réservation est confirmée
          if (order != null && order.status == FlashOrderStatus.confirmed) ...[
            _buildConfirmationSuccessCard(context, order),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Recommencer une nouvelle démo'),
              onPressed: () => context.read<FlashOrderCubit>().resetOrder(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationSelectionCard(BuildContext context, FlashOrderState state) {
    final med = state.selectedMedication ?? FlashOrderCubit.defaultSampleMedication;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1. Médicament demandé',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => _showMedicationPicker(context),
                child: const Text('Changer'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.medication_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.nomCommercial,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'DCI : ${med.dci}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      Text(
                        'Prix homologué : ${med.prixHomologueCfa} FCFA',
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Quantité :',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.remove, size: 18),
                    onPressed: state.quantity > 1
                        ? () => context.read<FlashOrderCubit>().setQuantity(state.quantity - 1)
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '${state.quantity}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.add, size: 18),
                    onPressed: () => context.read<FlashOrderCubit>().setQuantity(state.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelectionCard(BuildContext context, FlashOrderState state) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '2. Quartier / Repère à Yaoundé',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: state.selectedQuarter,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.primary),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: YaoundeLandmarks.list.map((YaoundeLandmark landmark) {
              final label = '${landmark.nom}, ${landmark.quartier}';
              return DropdownMenuItem<String>(
                value: label,
                child: Text(label, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                context.read<FlashOrderCubit>().selectQuarter(val);
              }
            },
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dispatch équitable Round-Robin vers 3 pharmacies certifiées ONPC.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchingRadarCard(BuildContext context, FlashOrder order) {
    return BentoCard(
      borderColor: AppColors.primary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sensors_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispatch MedMate en cours...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Transmis à 3 pharmacies partenaires',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
          const Divider(height: 24),
          const Text(
            'Pharmacies consultées (Premier répondant gagne) :',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...order.targets.map((pharma) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    pharma.status == PharmacistReplyType.unavailable
                        ? Icons.cancel_outlined
                        : Icons.radio_button_unchecked_rounded,
                    size: 16,
                    color: pharma.status == PharmacistReplyType.unavailable
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pharma.name} (${pharma.quarter})',
                      style: TextStyle(
                        fontSize: 13,
                        decoration: pharma.status == PharmacistReplyType.unavailable
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    pharma.status == PharmacistReplyType.unavailable
                        ? 'Indisponible'
                        : '${pharma.distanceKm} km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pharma.status == PharmacistReplyType.unavailable
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWinnerNotificationCard(BuildContext context, FlashOrder order) {
    final winner = order.winnerPharmacy!;
    final isConditional = order.winnerReplyType == PharmacistReplyType.conditional;

    return BentoCard(
      borderColor: isConditional ? AppColors.warning : AppColors.success,
      backgroundColor: isConditional ? AppColors.warningSoft.withValues(alpha: 0.3) : AppColors.successSoft.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: isConditional ? AppColors.warning : AppColors.success,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pharmacie trouvée !',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${winner.name} a répondu en premier',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      winner.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${winner.distanceKm} km',
                      style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Text(
                  winner.quarter,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      winner.phone,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isConditional && order.conditionNote != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Condition du pharmacien : ${order.conditionNote}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total à régler (${order.quantity} boîte) :',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${order.totalAmountCfa} FCFA',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSelectionCard(BuildContext context, FlashOrder order) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mode d'acquisition & Paiement",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPaymentOptionTile(
            title: 'Paiement en espèces au comptoir',
            subtitle: 'Génère un code OTP de mise de côté (garantie 2h)',
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.primary,
            value: FlashPaymentMethod.cashCounter,
          ),
          _buildPaymentOptionTile(
            title: 'Orange Money Cameroun',
            subtitle: 'Paiement direct sécurisé par push USSD (#150#)',
            icon: Icons.phone_android_rounded,
            iconColor: Colors.deepOrange,
            value: FlashPaymentMethod.orangeMoney,
          ),
          _buildPaymentOptionTile(
            title: 'MTN Mobile Money',
            subtitle: 'Paiement direct sécurisé (*126#)',
            icon: Icons.payment_rounded,
            iconColor: Colors.amber.shade800,
            value: FlashPaymentMethod.mtnMoMo,
          ),
          if (_selectedPaymentMethod != FlashPaymentMethod.cashCounter) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro de téléphone de paiement',
                prefixText: '+237 ',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              context.read<FlashOrderCubit>().confirmPayment(
                    method: _selectedPaymentMethod,
                    phoneNumber: _phoneController.text,
                  );
            },
            child: Text(
              _selectedPaymentMethod == FlashPaymentMethod.cashCounter
                  ? 'Générer mon Code de Réservation au Comptoir'
                  : 'Payer ${order.totalAmountCfa} FCFA par Mobile Money',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required FlashPaymentMethod value,
  }) {
    final isSelected = _selectedPaymentMethod == value;
    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySoft.withValues(alpha: 0.35) : AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSuccessCard(BuildContext context, FlashOrder order) {
    final isCash = order.paymentMethod == FlashPaymentMethod.cashCounter;

    return BentoCard(
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            isCash ? 'Réservation au Comptoir Confirmée !' : 'Paiement Mobile Money Validé !',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Médicament mis de côté à la ${order.winnerPharmacy?.name}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),

          // Code OTP Haute Visibilité
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Text(
                  'CODE DE RETRAIT COMPTOIR (OTP)',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.reservationOtpCode ?? 'RET-892410',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: AppColors.warning),
                      SizedBox(width: 4),
                      Text(
                        'Valable pendant 02h 00m (Garantie de stock)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),
          Text(
            'Présentez ce code directement au guichet de ${order.winnerPharmacy?.name} (${order.winnerPharmacy?.quarter}).',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenterTipCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicationPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _availableMedications.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final med = _availableMedications[index];
            return ListTile(
              leading: const Icon(Icons.medication_outlined, color: AppColors.primary),
              title: Text(med.nomCommercial, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${med.dci} • ${med.prixHomologueCfa} FCFA'),
              onTap: () {
                context.read<FlashOrderCubit>().selectMedication(med);
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // 2. VUE PHARMACIEN (POSTE DE TRAVAIL OFFICINE)
  // ===========================================================================

  Widget _buildPharmacistView(BuildContext context, FlashOrderState state) {
    final order = state.activeOrder;
    final pharmacies = FlashOrderCubit.defaultTargetPharmacies;
    final currentPharmaIndex = state.activePharmacistIndex;
    final activePharma = pharmacies[currentPharmaIndex];

    return SingleChildScrollView(
      key: const ValueKey('pharmacist_view'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 2.1 Sélecteur de compte officine
          const Text(
            "Sélectionnez l'officine connectée :",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: pharmacies.length,
              itemBuilder: (context, index) {
                final pharma = pharmacies[index];
                final isSelected = index == currentPharmaIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(pharma.name),
                    selected: isSelected,
                    onSelected: (_) {
                      context.read<FlashOrderCubit>().setActivePharmacistIndex(index);
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2.2 Si aucune commande active
          if (order == null) ...[
            BentoCard(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    const Text(
                      'Aucune commande flash en attente',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Revenez sur la "Vue Patient" pour lancer une recherche.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // 2.3 Détails de la demande reçue par l'officine
            _buildIncomingOrderCard(context, order, activePharma),
            const SizedBox(height: 16),

            // 2.4 Actions du pharmacien (3 boutons officiels demandés par le client)
            _buildPharmacistActionControls(context, order, activePharma),
          ],
        ],
      ),
    );
  }

  Widget _buildIncomingOrderCard(BuildContext context, FlashOrder order, DispatchedPharmacy pharma) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Demande #${order.id}',
                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('Reçue il y a 10s', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${order.quantity}x ${order.medication.nomCommercial}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'DCI : ${order.medication.dci}',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Patient situé à : ${order.quarter}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Montant homologué : ${order.totalAmountCfa} FCFA',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacistActionControls(
    BuildContext context,
    FlashOrder order,
    DispatchedPharmacy activePharma,
  ) {
    // Si la commande est déjà remportée
    if (order.winnerPharmacy != null) {
      final isThisWinner = order.winnerPharmacy!.id == activePharma.id;
      if (isThisWinner) {
        return BentoCard(
          borderColor: AppColors.success,
          backgroundColor: AppColors.successSoft.withValues(alpha: 0.3),
          child: const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: AppColors.success, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Félicitations ! Vous avez remporté cette commande.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Le patient a été notifié et procède à la réservation.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      } else {
        return BentoCard(
          borderColor: AppColors.border,
          child: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: AppColors.textSecondary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Commande déjà attribuée',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      'Remportée par ${order.winnerPharmacy?.name} (Règle du premier répondant).',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    }

    // Si cette pharmacie a déjà répondu indisponible
    final thisPharmacyTarget = order.targets.firstWhere((p) => p.id == activePharma.id);
    if (thisPharmacyTarget.status == PharmacistReplyType.unavailable) {
      return const BentoCard(
        borderColor: AppColors.error,
        child: Text(
          'Vous avez signalé ce produit comme indisponible dans votre officine.',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
      );
    }

    // Les 3 boutons officiels exigés par le cahier des charges client
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Répondre à la commande (La 1ère pharmacie gagne) :',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // Bouton 1 : DISPONIBLE
        ElevatedButton.icon(
          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
          label: const Text('1. Disponible (En Stock)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            context.read<FlashOrderCubit>().submitPharmacistResponse(
                  pharmacyId: activePharma.id,
                  reply: PharmacistReplyType.available,
                );
          },
        ),
        const SizedBox(height: 10),

        // Bouton 2 : DISPONIBLE SOUS CONDITIONS
        ElevatedButton.icon(
          icon: const Icon(Icons.rule_rounded, color: Colors.white),
          label: const Text('2. Disponible sous conditions...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () => _showConditionalReplyModal(context, activePharma.id),
        ),
        const SizedBox(height: 10),

        // Bouton 3 : INDISPONIBLE
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
          label: const Text('3. Indisponible (Rupture)', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed: () {
            context.read<FlashOrderCubit>().submitPharmacistResponse(
                  pharmacyId: activePharma.id,
                  reply: PharmacistReplyType.unavailable,
                );
          },
        ),
      ],
    );
  }

  void _showConditionalReplyModal(BuildContext context, String pharmacyId) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final conditions = [
          "Nécessite présentation de l'ordonnance originale papier",
          'Générique équivalent DCI en stock (même molécule & dosage)',
          'Stock partiel restant (1 boîte disponible immédiatement)',
          'Forme buvable disponible au lieu des comprimés',
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Préciser la condition pour le patient :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...conditions.map((condition) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chevron_right_rounded, color: AppColors.warning),
                  title: Text(condition, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<FlashOrderCubit>().submitPharmacistResponse(
                          pharmacyId: pharmacyId,
                          reply: PharmacistReplyType.conditional,
                          conditionNote: condition,
                        );
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
