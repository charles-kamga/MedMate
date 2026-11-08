import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../auth/domain/entities/user_session.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';

/// Espace Professionnel dédié aux Pharmaciens partenaires Afya Santé V2 :
/// - Notifications et traitement des demandes entrantes en temps réel
/// - Formulaire standardisé des 3 réponses : Disponible, Indisponible, Disponible sous conditions
/// - Fixation libre et souveraine du prix en FCFA par le pharmacien
/// - Proposition de livraison facultative (tarif et délai)
/// - Contrôle et validation du code unique de retrait (OTP) au comptoir
class PharmacistPortalView extends StatefulWidget {
  const PharmacistPortalView({
    super.key,
    this.initialPharmacyId = 'pharma-soleil',
  });

  final String initialPharmacyId;

  @override
  State<PharmacistPortalView> createState() => _PharmacistPortalViewState();
}

class _PharmacistPortalViewState extends State<PharmacistPortalView> {
  late String _activePharmacyId;
  final _priceController = TextEditingController(text: '2800');
  final _conditionNoteController = TextEditingController();
  final _otpInputController = TextEditingController();

  PharmacyAvailabilityType _selectedAvailability = PharmacyAvailabilityType.fullyAvailable;
  bool _requirePrescription = true;
  bool _requirePhysicalPresence = false;
  bool _requireAgeCheck = false;
  bool _proposesDelivery = false;
  final _deliveryFeeController = TextEditingController(text: '1000');
  final _deliveryMinutesController = TextEditingController(text: '30');

  // Profils de pharmacies partenaires de démonstration
  static const List<PharmacyStaffProfile> _demoProfiles = [
    PharmacyStaffProfile(
      pharmacyId: 'pharma-soleil',
      pharmacyName: 'Pharmacie du Soleil',
      licenceOnpc: 'ONPC-YDE-0105',
      responsable: 'Dr. Aïcha Bello (Titulaire)',
      quarter: 'Carrefour Warda',
      telephone: '+237 677 12 34 56',
      estDeGarde: false,
    ),
    PharmacyStaffProfile(
      pharmacyId: 'pharma-centre',
      pharmacyName: 'Grande Pharmacie du Centre',
      licenceOnpc: 'ONPC-YDE-0042',
      responsable: 'Dr. Jean Mballa (Titulaire)',
      quarter: 'Poste Centrale',
      telephone: '+237 699 88 77 66',
      estDeGarde: true,
    ),
    PharmacyStaffProfile(
      pharmacyId: 'pharma-obili',
      pharmacyName: "Pharmacie d'Obili",
      licenceOnpc: 'ONPC-YDE-0211',
      responsable: 'Dr. Paul Biye (Titulaire)',
      quarter: 'Carrefour Obili',
      telephone: '+237 655 44 33 22',
      estDeGarde: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activePharmacyId = widget.initialPharmacyId;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _conditionNoteController.dispose();
    _otpInputController.dispose();
    _deliveryFeeController.dispose();
    _deliveryMinutesController.dispose();
    super.dispose();
  }

  PharmacyStaffProfile get _currentProfile {
    return _demoProfiles.firstWhere(
      (p) => p.pharmacyId == _activePharmacyId,
      orElse: () => _demoProfiles.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashOrderCubit, FlashOrderState>(
      builder: (context, state) {
        final order = state.activeOrder;
        final target = order?.targets.cast<DispatchedPharmacy?>().firstWhere(
              (t) => t?.id == _activePharmacyId,
              orElse: () => null,
            );
        final offer = order?.offers.cast<PharmacyOffer?>().firstWhere(
              (o) => o?.pharmacyId == _activePharmacyId,
              orElse: () => null,
            );

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Sélecteur d'officine (outil de démo pour basculer entre pharmacies de la vague)
            _buildPharmacySwitcher(),
            const SizedBox(height: 16),

            // En-tête officiel de l'officine
            _buildOfficineHeaderCard(),
            const SizedBox(height: 20),

            // Section 1 : Demande patient entrante
            Text(
              'Demande patient en cours (${order != null ? "1" : "0"})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),

            if (order == null || target == null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.notifications_none_rounded, size: 36, color: AppColors.textSecondary),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucune demande en attente pour votre officine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre officine sera notifiée dès qu’un patient lancera une recherche dans votre secteur (${_currentProfile.quarter}).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              _buildIncomingRequestCard(context, order, target, offer),

            const SizedBox(height: 24),

            // Section 2 : Contrôle du retrait au comptoir (Validation OTP)
            _buildOtpVerificationSection(context, state),
          ],
        );
      },
    );
  }

  Widget _buildPharmacySwitcher() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_horiz_rounded, color: AppColors.secondary, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Incarner l’officine :',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _activePharmacyId,
                isExpanded: true,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                items: _demoProfiles.map((p) {
                  return DropdownMenuItem<String>(
                    value: p.pharmacyId,
                    child: Text('${p.pharmacyName} (${p.quarter})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _activePharmacyId = val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficineHeaderCard() {
    return BentoCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.primaryLight.withValues(alpha: 0.3),
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
                child: const Text(
                  'PARTENAIRE OFFICIEL AFYA SANTÉ',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.primary),
                ),
              ),
              if (_currentProfile.estDeGarde)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🌙 DE GARDE CE SOIR',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.secondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _currentProfile.pharmacyName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentProfile.responsable} · Licence ${_currentProfile.licenceOnpc}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            '📍 ${_currentProfile.quarter} · Tél : ${_currentProfile.telephone}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingRequestCard(
    BuildContext context,
    FlashOrder order,
    DispatchedPharmacy target,
    PharmacyOffer? existingOffer,
  ) {
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
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ),
              Text(
                'Secteur : ${order.quarter}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Liste des médicaments du panier
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
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (item.hasPrescription)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Ordonnance jointe', style: TextStyle(fontSize: 10, color: AppColors.secondary, fontWeight: FontWeight.w700)),
                    ),
                ],
              ),
            );
          }),

          const Divider(height: 24),

          if (existingOffer != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Offre transmise au patient',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                        ),
                        Text(
                          'Montant communiqué : ${existingOffer.grandTotalCfa} FCFA (${existingOffer.availabilityType.name})',
                          style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Formulaire des 3 réponses
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
                title: const Text('Présentation de l’ordonnance originale obligatoire', style: TextStyle(fontSize: 12)),
                value: _requirePrescription,
                onChanged: (val) => setState(() => _requirePrescription = val ?? false),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text('Présence physique du patient au comptoir', style: TextStyle(fontSize: 12)),
                value: _requirePhysicalPresence,
                onChanged: (val) => setState(() => _requirePhysicalPresence = val ?? false),
              ),
              CheckboxListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
                title: const Text('Vérification d’âge ou pièce d’identité', style: TextStyle(fontSize: 12)),
                value: _requireAgeCheck,
                onChanged: (val) => setState(() => _requireAgeCheck = val ?? false),
              ),
              TextField(
                controller: _conditionNoteController,
                decoration: InputDecoration(
                  labelText: 'Précisions / conseil pharmaceutique (optionnel)',
                  labelStyle: const TextStyle(fontSize: 12),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 14),
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.primary,
                title: const Text('Proposer une option de livraison', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: () {
                  final price = int.tryParse(_priceController.text) ?? 2800;
                  final conditions = <String>[];
                  if (_requirePrescription) conditions.add('Ordonnance originale requise');
                  if (_requirePhysicalPresence) conditions.add('Présence physique du patient');
                  if (_requireAgeCheck) conditions.add('Vérification d’âge');

                  context.read<FlashOrderCubit>().submitPharmacistQuote(
                        pharmacyId: _activePharmacyId,
                        availability: _selectedAvailability,
                        quotedPriceCfa: _selectedAvailability == PharmacyAvailabilityType.unavailable ? 0 : price,
                        conditionRequirements: conditions,
                        conditionNote: _conditionNoteController.text.isNotEmpty ? _conditionNoteController.text : null,
                        proposesDelivery: _proposesDelivery,
                        deliveryFeeCfa: int.tryParse(_deliveryFeeController.text) ?? 1000,
                        estimatedDeliveryMinutes: int.tryParse(_deliveryMinutesController.text) ?? 30,
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
        ],
      ),
    );
  }

  Widget _buildOtpVerificationSection(BuildContext context, FlashOrderState state) {
    return BentoCard(
      backgroundColor: Colors.white,
      borderColor: AppColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Contrôle du retrait au comptoir (Code OTP)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Saisissez le code de retrait présenté par le patient pour valider la délivrance :',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _otpInputController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'ex: RET-842915',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  context.read<FlashOrderCubit>().validateOtpAtCounter(
                        enteredOtp: _otpInputController.text,
                        pharmacyId: _activePharmacyId,
                      );
                },
                child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),

          if (state.otpValidationSuccess ?? false) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Retrait validé avec succès ! Médicaments délivrés au patient.',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!(state.otpValidationSuccess ?? true) && state.otpValidationError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.alertSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.alert),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.alert, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.otpValidationError!,
                      style: const TextStyle(color: AppColors.alert, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
