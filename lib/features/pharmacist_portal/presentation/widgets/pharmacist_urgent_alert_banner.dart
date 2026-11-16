import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Bandeau visuel d'alerte urgente pour les nouvelles demandes de dispensation
class PharmacistUrgentAlertBanner extends StatelessWidget {
  const PharmacistUrgentAlertBanner({
    required this.onAcknowledge,
    super.key,
  });

  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.alertSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.alert),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.notifications_active_rounded,
            color: AppColors.alert,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Nouvelle demande urgente',
              style: TextStyle(
                color: AppColors.alert,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          ElevatedButton(
            key: const ValueKey('btn_acknowledge_alert'),
            onPressed: onAcknowledge,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alert,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Acquitter',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
