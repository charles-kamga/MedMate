import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../../auth/domain/entities/user_session.dart';
import '../../domain/entities/flash_order.dart';
import '../../domain/entities/pharmacy_offer.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';
import '../widgets/flash_order_incoming_request_card.dart';
import '../widgets/flash_order_otp_section.dart';

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
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
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
                    const Icon(
                      Icons.notifications_none_rounded,
                      size: 36,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Aucune demande en attente pour votre officine.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Votre officine sera notifiée dès qu’un patient lancera une recherche dans votre secteur (${_currentProfile.quarter}).',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              FlashOrderIncomingRequestCard(
                order: order,
                activePharmacyId: _activePharmacyId,
                existingOffer: offer,
              ),

            const SizedBox(height: 24),

            // Section 2 : Contrôle du retrait au comptoir (Validation OTP)
            FlashOrderOtpSection(
              state: state,
              activePharmacyId: _activePharmacyId,
            ),
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
          const Icon(
            Icons.swap_horiz_rounded,
            color: AppColors.secondary,
            size: 20,
          ),
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'PARTENAIRE OFFICIEL AFYA SANTÉ',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (_currentProfile.estDeGarde)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🌙 DE GARDE CE SOIR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _currentProfile.pharmacyName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_currentProfile.responsable} · Licence ${_currentProfile.licenceOnpc}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            '📍 ${_currentProfile.quarter} · Tél : ${_currentProfile.telephone}',
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
