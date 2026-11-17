import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';

/// Modèle pour les données de pharmacie de démonstration de la maquette HTML.
class PharmacyDemoData {
  const PharmacyDemoData({
    required this.name,
    required this.distance,
    required this.phone,
    required this.stock,
  });

  final String name;
  final String distance;
  final String phone;
  final List<int> stock;
}

/// En-tête de progression du parcours patient en 4 étapes.
class PatientHomeWizardHeader extends StatelessWidget {
  const PatientHomeWizardHeader({
    required this.step,
    required this.onBack,
    super.key,
  });

  final int step;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                'Retour',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
            Text(
              'Étape $step sur 4',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 6,
            width: double.infinity,
            color: const Color(0xFFE8F2EB),
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 250),
              widthFactor: step * 0.25,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Champ de recherche médicament commun aux étapes 0 et 1.
class PatientHomeSearchField extends StatelessWidget {
  const PatientHomeSearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Rechercher un médicament…',
        hintStyle: const TextStyle(color: Color(0xFF9EABA5)),
        filled: true,
        fillColor: const Color(0xFFFAFDFA),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
        ),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(
                  Icons.clear,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDBE9E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}

/// Bannière d'information légale / démonstration.
class PatientHomeNoticeBanner extends StatelessWidget {
  const PatientHomeNoticeBanner({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8F4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Color(0xFF557165),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
