import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';
import 'patient_request_wizard_view.dart';
import 'pharmacist_portal_view.dart';

/// Écran complet de démonstration interactive Afya Santé V2 :
/// Permet de basculer instantanément entre la Vue Patient et la Vue Pharmacien
class FlashOrderScreen extends StatelessWidget {
  const FlashOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FlashOrderCubit, FlashOrderState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Afya Santé V2 Démo'),
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
                      label: Text('Vue Patient (Demande & Vagues)'),
                      icon: Icon(Icons.person_outline_rounded),
                    ),
                    ButtonSegment<UserRole>(
                      value: UserRole.pharmacist,
                      label: Text('Vue Officine (Devis & OTP)'),
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
                ? const PatientRequestWizardView(key: ValueKey('demo_patient'))
                : const PharmacistPortalView(key: ValueKey('demo_pharmacist')),
          ),
        );
      },
    );
  }
}
