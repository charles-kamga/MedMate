import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Composant Carte Bento conforme aux standards UI/UX Pro Max
class BentoCard extends StatelessWidget {
  const BentoCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AppColors.surface,
    this.borderColor = AppColors.border,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Color borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
