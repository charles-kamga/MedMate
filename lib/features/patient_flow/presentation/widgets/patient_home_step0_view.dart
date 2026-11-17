import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:medmate/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart';
import 'package:medmate/features/flash_order/presentation/views/patient_request_wizard_view.dart';
import 'patient_home_shared_widgets.dart';
import 'patient_home_step0_sections.dart';

/// Étape 0 de l'accueil patient : sélection ville, recherche, cartes Flash V2 et garde.
class PatientHomeStep0View extends StatelessWidget {
  const PatientHomeStep0View({
    required this.city,
    required this.cities,
    required this.searchController,
    required this.query,
    required this.onCityChanged,
    required this.onQueryChanged,
    required this.onStartSearch,
    required this.onQuickPick,
    this.onOpenReminders,
    super.key,
  });

  final String city;
  final List<String> cities;
  final TextEditingController searchController;
  final String query;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onStartSearch;
  final ValueChanged<int> onQuickPick;
  final VoidCallback? onOpenReminders;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bonjour 👋 · Votre localisation',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: city,
                icon: const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Text('📍', style: TextStyle(fontSize: 14)),
                ),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                items: cities
                    .map(
                      (c) => DropdownMenuItem<String>(value: c, child: Text(c)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) onCityChanged(val);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'De quels médicaments avez-vous besoin ?',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
            height: 1.15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Trouvez-les dans les pharmacies près de vous.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        PatientHomeSearchField(
          controller: searchController,
          query: query,
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onStartSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Trouver mes médicaments →',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildFlashV2Banner(context),
        const SizedBox(height: 20),
        _buildDutyBanner(context),
        const SizedBox(height: 24),
        PatientHomeStep0Sections(
          onQuickPick: onQuickPick,
          onStartSearch: onStartSearch,
          onOpenReminders: onOpenReminders,
        ),
      ],
    );
  }

  Widget _buildFlashV2Banner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7F0), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A163E2C),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'AFYA SANTÉ V2 · PARCOURS CIBLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Text(
                '⚡ Escalade 2 min',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Demande sans sélection de pharmacie',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Créez votre panier multi-médicaments. L’application sollicite les pharmacies par vagues de 2 et vous comparez leurs offres réelles.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Demande en vagues')),
                      body: const PatientRequestWizardView(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.flash_on_rounded, size: 18),
              label: const Text(
                'Tester la demande en vagues →',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF7F0), Color(0xFFF1F8F4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCFE5D6)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A163E2C),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: const Text('🌙', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pharmacies de garde ce soir',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Officines de nuit ouvertes à $city',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const DutyPharmacyScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Voir →',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
