import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pharmacy_search/domain/entities/medication.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';
import '../widgets/wizard_step1_basket.dart';
import '../widgets/wizard_step2_wave_radar.dart';
import '../widgets/wizard_step3_offers.dart';
import '../widgets/wizard_step4_confirmation.dart';

/// Vue interactive complète du parcours patient Afya Santé V2 :
/// 1. Panier intelligent multi-médicaments & Localisation (sans pharmacie imposée)
/// 2. Radar de recherche en vagues (2 pharmacies / 2 minutes)
/// 3. Comparateur d'offres reçues (prix fixé par pharmacien, conditions, livraison)
/// 4. Réservation, Choix paiement & Code OTP de retrait
class PatientRequestWizardView extends StatefulWidget {
  const PatientRequestWizardView({super.key});

  @override
  State<PatientRequestWizardView> createState() =>
      _PatientRequestWizardViewState();
}

class _PatientRequestWizardViewState extends State<PatientRequestWizardView> {
  final _phoneController = TextEditingController(text: '699112233');
  FlashPaymentMethod _paymentMethod = FlashPaymentMethod.cashCounter;

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
              WizardStep1Basket(state: state, catalog: _catalog)
            else if (order.status == FlashOrderStatus.dispatchingWave &&
                !state.hasOffers)
              WizardStep2WaveRadar(order: order)
            else if (order.status == FlashOrderStatus.dispatchingWave ||
                order.status == FlashOrderStatus.offersReceived)
              WizardStep3Offers(order: order)
            else
              WizardStep4Confirmation(
                order: order,
                selectedPaymentMethod: _paymentMethod,
                onPaymentMethodChanged: (m) =>
                    setState(() => _paymentMethod = m),
                phoneNumber: _phoneController.text,
              ),
          ],
        );
      },
    );
  }
}
