import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import '../cubit/flash_order_cubit.dart';

/// Carte de traitement d'une demande patient entrante (ancien portail V2).
class FlashOrderIncomingRequestCard extends StatefulWidget {
  const FlashOrderIncomingRequestCard({
    required this.order,
    required this.activePharmacyId,
    this.existingOffer,
    super.key,
  });

  final FlashOrder order;
  final String activePharmacyId;
  final PharmacyOffer? existingOffer;

  @override
  State<FlashOrderIncomingRequestCard> createState() =>
      _FlashOrderIncomingRequestCardState();
}

class _FlashOrderIncomingRequestCardState
    extends State<FlashOrderIncomingRequestCard> {
  final _priceController = TextEditingController(text: '2800');
  final _conditionNoteController = TextEditingController();
  final _deliveryFeeController = TextEditingController(text: '1000');
  final _deliveryMinutesController = TextEditingController(text: '30');

  PharmacyAvailabilityType _selectedAvailability =
      PharmacyAvailabilityType.fullyAvailable;
  bool _requirePrescription = true;
  bool _requirePhysicalPresence = false;
  bool _requireAgeCheck = false;
  bool _proposesDelivery = false;

  @override
  void dispose() {
    _priceController.dispose();
    _conditionNoteController.dispose();
    _deliveryFeeController.dispose();
    _deliveryMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final existingOffer = widget.existingOffer;

    return BentoCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Demande #${order.id}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Text(
                'Secteur : ${order.quarter}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Panier demandé par le patient :',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          ...order.items.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text('💊', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${item.medication.nomCommercial} (Quantité: ${item.quantity})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (item.hasPrescription)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Ordonnance jointe',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          if (existingOffer != null)
            _buildOfferSubmittedBox(existingOffer)
          else
            _buildReplyForm(context),
        ],
      ),
    );
  }

  Widget _buildOfferSubmittedBox(PharmacyOffer existingOffer) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Offre transmise au patient',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'Montant communiqué : ${existingOffer.grandTotalCfa} FCFA (${existingOffer.availabilityType.name})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Votre réponse de disponibilité :',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
        const SizedBox(height: 8),
        SegmentedButton<PharmacyAvailabilityType>(
          segments: const [
            ButtonSegment(
              value: PharmacyAvailabilityType.fullyAvailable,
              label: Text('Disponible', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.check, size: 14),
            ),
            ButtonSegment(
              value: PharmacyAvailabilityType.conditional,
              label: Text('Sous conditions', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.info_outline, size: 14),
            ),
            ButtonSegment(
              value: PharmacyAvailabilityType.unavailable,
              label: Text('Indisponible', style: TextStyle(fontSize: 11)),
              icon: Icon(Icons.close, size: 14),
            ),
          ],
          selected: {_selectedAvailability},
          onSelectionChanged: (val) {
            setState(() => _selectedAvailability = val.first);
          },
        ),
        if (_selectedAvailability == PharmacyAvailabilityType.conditional) ...[
          const SizedBox(height: 14),
          const Text(
            'Conditions de délivrance requises :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text(
              'Présentation de l’ordonnance originale obligatoire',
              style: TextStyle(fontSize: 12),
            ),
            value: _requirePrescription,
            onChanged: (val) =>
                setState(() => _requirePrescription = val ?? false),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text(
              'Présence physique du patient au comptoir',
              style: TextStyle(fontSize: 12),
            ),
            value: _requirePhysicalPresence,
            onChanged: (val) =>
                setState(() => _requirePhysicalPresence = val ?? false),
          ),
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.primary,
            title: const Text(
              'Vérification d’âge ou pièce d’identité',
              style: TextStyle(fontSize: 12),
            ),
            value: _requireAgeCheck,
            onChanged: (val) => setState(() => _requireAgeCheck = val ?? false),
          ),
          TextField(
            controller: _conditionNoteController,
            decoration: InputDecoration(
              labelText: 'Précisions / conseil pharmaceutique (optionnel)',
              labelStyle: const TextStyle(fontSize: 12),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
        if (_selectedAvailability != PharmacyAvailabilityType.unavailable) ...[
          const SizedBox(height: 16),
          const Text(
            'Montant total officiel des médicaments (FCFA) :',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: 'FCFA',
              hintText: 'ex: 2800',
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.primary,
            title: const Text(
              'Proposer une option de livraison',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            value: _proposesDelivery,
            onChanged: (val) => setState(() => _proposesDelivery = val),
          ),
          if (_proposesDelivery)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _deliveryFeeController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Frais livraison (FCFA)',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _deliveryMinutesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Délai estimé (min)',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            onPressed: () {
              final price = int.tryParse(_priceController.text) ?? 2800;
              final conditions = <String>[];
              if (_requirePrescription) {
                conditions.add('Ordonnance originale requise');
              }
              if (_requirePhysicalPresence) {
                conditions.add('Présence physique du patient');
              }
              if (_requireAgeCheck) conditions.add('Vérification d’âge');

              context.read<FlashOrderCubit>().submitPharmacistQuote(
                    pharmacyId: widget.activePharmacyId,
                    availability: _selectedAvailability,
                    quotedPriceCfa: _selectedAvailability ==
                            PharmacyAvailabilityType.unavailable
                        ? 0
                        : price,
                    conditionRequirements: conditions,
                    conditionNote: _conditionNoteController.text.isNotEmpty
                        ? _conditionNoteController.text
                        : null,
                    proposesDelivery: _proposesDelivery,
                    deliveryFeeCfa:
                        int.tryParse(_deliveryFeeController.text) ?? 1000,
                    estimatedDeliveryMinutes:
                        int.tryParse(_deliveryMinutesController.text) ?? 30,
                  );
            },
            child: Text(
              _selectedAvailability == PharmacyAvailabilityType.unavailable
                  ? 'Signaler l’indisponibilité'
                  : 'Transmettre notre offre chiffrée →',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
