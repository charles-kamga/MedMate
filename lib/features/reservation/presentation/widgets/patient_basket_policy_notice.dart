import 'package:flutter/material.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';

/// Bannière d'information réglementaire sur l'absence de prix fixes côté patient.
class PatientBasketPolicyNotice extends StatelessWidget {
  const PatientBasketPolicyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              AppConfig.pricePolicyNotice,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.primaryDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
