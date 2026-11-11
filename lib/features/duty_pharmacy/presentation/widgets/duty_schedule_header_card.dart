import 'package:flutter/material.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/theme/app_colors.dart';

/// En-tête : titre, sélecteur de ville, onglets et bandeau « Programme de garde »
class DutyScheduleHeaderCard extends StatelessWidget {
  const DutyScheduleHeaderCard({
    required this.cities,
    required this.selectedCity,
    required this.activeSegment,
    required this.onCityChanged,
    required this.onSegmentChanged,
    super.key,
  });

  final List<String> cities;
  final String selectedCity;
  final int activeSegment;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<int> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pharmacies de garde',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Trouvez une pharmacie de garde près de vous',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text(
              'Votre ville : ',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCity,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                items: cities
                    .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) onCityChanged(val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _segment('Plus proches', 0)),
            const SizedBox(width: 10),
            Expanded(child: _segment('Toutes les gardes', 1)),
          ],
        ),
        const SizedBox(height: 18),
        _buildBanner(),
      ],
    );
  }

  Widget _segment(String label, int index) {
    final active = activeSegment == index;
    return GestureDetector(
      onTap: () => onSegmentChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AppColors.primary : const Color(0xFFCFE5D6),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDBE9E0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('⏰', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Programme de garde',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppConfig.appName} affiche automatiquement les pharmacies positionnées pour la garde ce soir dans $selectedCity.',
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: Color(0xFF4A6559),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
