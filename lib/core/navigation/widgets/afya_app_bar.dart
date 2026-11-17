import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';

/// En-tête unifié Afya-Health avec badge Yaoundé et raccourci urgence.
class AfyaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AfyaAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 16,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: const Text(
              '✚',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Flexible(
            child: Text(
              AppConfig.appName,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Yaoundé',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: Tooltip(
            message: 'Urgence secours Yaoundé',
            child: TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Numéro d'urgence Yaoundé : ${AppConfig.emergencyPhone}",
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: const Icon(
                Icons.emergency_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              label: const Text(
                AppConfig.emergencyPhone,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primarySoft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
