import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/pharmacy.dart';

/// Fiche détaillée de l'officine sélectionnée sur la carte OpenStreetMap
class PharmacyMapBottomCard extends StatelessWidget {
  const PharmacyMapBottomCard({
    required this.pharmacy,
    required this.onClose,
    required this.onCall,
    required this.onSolicit,
    super.key,
  });

  final Pharmacy pharmacy;
  final VoidCallback onClose;
  final VoidCallback onCall;
  final VoidCallback onSolicit;

  @override
  Widget build(BuildContext context) {
    final partner = pharmacy.isPartner;
    return BentoCard(
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  pharmacy.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: onClose,
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _badge(
                partner ? '✓ PARTENAIRE AFYA SANTÉ' : 'NON PARTENAIRE (RECENSÉE)',
                partner ? AppColors.primary : const Color(0xFF64748B),
                partner ? AppColors.primarySoft : const Color(0xFFF1F5F9),
              ),
              if (pharmacy.estDeGarde)
                _badge('DE GARDE', AppColors.secondary, AppColors.secondarySoft),
            ],
          ),
          if (!partner) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFF64748B)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cette officine est recensée à titre d’information. Elle n’est pas partenaire et ne reçoit pas de requêtes directes via l’application.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.navigation_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '~${pharmacy.distanceMetres?.toStringAsFixed(0)} m du repère sélectionné',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                pharmacy.licenceOnpc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (partner)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.phone_rounded, size: 18),
                    label: const Text(
                      'Appel Officine',
                      overflow: TextOverflow.ellipsis,
                    ),
                    onPressed: onCall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.flash_on_rounded, size: 18),
                    label: const Text('Solliciter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onSolicit,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.phone_rounded, size: 18),
                label: const Text('Appeler l’officine directement'),
                onPressed: onCall,
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
