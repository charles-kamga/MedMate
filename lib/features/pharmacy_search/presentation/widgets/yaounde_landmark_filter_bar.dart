import 'package:flutter/material.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';

/// En-tête flottant : carrousel des carrefours de Yaoundé + légende partenaires
class YaoundeLandmarkFilterBar extends StatelessWidget {
  const YaoundeLandmarkFilterBar({
    required this.selectedLandmark,
    required this.partnerCount,
    required this.nonPartnerCount,
    required this.onSelect,
    super.key,
  });

  final YaoundeLandmark? selectedLandmark;
  final int partnerCount;
  final int nonPartnerCount;
  final ValueChanged<YaoundeLandmark> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: BentoCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              backgroundColor: Colors.white.withValues(alpha: 0.95),
              child: const Row(
                children: [
                  Icon(Icons.explore_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Repères & Carrefours de Yaoundé',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: YaoundeLandmarks.list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final landmark = YaoundeLandmarks.list[index];
                final isSelected = selectedLandmark?.id == landmark.id;
                return ActionChip(
                  elevation: isSelected ? 2 : 0,
                  backgroundColor: isSelected ? AppColors.primary : Colors.white,
                  label: Text(
                    landmark.nom,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  avatar: Icon(
                    Icons.place_rounded,
                    size: 16,
                    color: isSelected ? Colors.white : AppColors.secondary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  onPressed: () => onSelect(landmark),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _legend(
                  'Partenaires in-app ($partnerCount)',
                  AppColors.primary,
                  AppColors.primarySoft,
                ),
                _legend(
                  'Non-partenaires ($nonPartnerCount)',
                  const Color(0xFF64748B),
                  const Color(0xFFF1F5F9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legend(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
