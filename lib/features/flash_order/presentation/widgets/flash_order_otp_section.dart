import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../cubit/flash_order_cubit.dart';
import '../cubit/flash_order_state.dart';

/// Section de validation du retrait au comptoir (code OTP) de l'ancien portail V2.
class FlashOrderOtpSection extends StatefulWidget {
  const FlashOrderOtpSection({
    required this.state,
    required this.activePharmacyId,
    super.key,
  });

  final FlashOrderState state;
  final String activePharmacyId;

  @override
  State<FlashOrderOtpSection> createState() => _FlashOrderOtpSectionState();
}

class _FlashOrderOtpSectionState extends State<FlashOrderOtpSection> {
  final _otpInputController = TextEditingController();

  @override
  void dispose() {
    _otpInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  context.read<FlashOrderCubit>().validateOtpAtCounter(
                        enteredOtp: _otpInputController.text,
                        pharmacyId: widget.activePharmacyId,
                      );
                },
                child: const Text(
                  'Valider',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
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
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!(state.otpValidationSuccess ?? true) &&
              state.otpValidationError != null) ...[
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
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.alert,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.otpValidationError!,
                      style: const TextStyle(
                        color: AppColors.alert,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
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
