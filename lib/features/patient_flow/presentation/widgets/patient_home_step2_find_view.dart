import 'package:flutter/material.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'patient_home_shared_widgets.dart';

/// Étape 2 du parcours patient : liste et filtrage des pharmacies disponibles.
class PatientHomeStep2FindView extends StatelessWidget {
  const PatientHomeStep2FindView({
    required this.pharmacies,
    required this.city,
    required this.cities,
    required this.availabilityOnly,
    required this.isMatch,
    required this.onCityChanged,
    required this.onAvailabilityChanged,
    required this.onSelectPharmacy,
    super.key,
  });

  final List<PharmacyDemoData> pharmacies;
  final String city;
  final List<String> cities;
  final bool availabilityOnly;
  final bool Function(PharmacyDemoData) isMatch;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<bool> onAvailabilityChanged;
  final ValueChanged<int> onSelectPharmacy;

  @override
  Widget build(BuildContext context) {
    final filteredPharmacies = pharmacies.asMap().entries.where((entry) {
      return !availabilityOnly || isMatch(entry.value);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trouvez une pharmacie',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Comparez les disponibilités déclarées par nos partenaires.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        _buildFilterCard(),
        const SizedBox(height: 20),
        if (filteredPharmacies.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Aucune pharmacie ne correspond au filtre.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          )
        else
          ...filteredPharmacies.map(_buildPharmacyCard),
      ],
    );
  }

  Widget _buildFilterCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ville',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: city,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  items: cities
                      .map(
                        (c) =>
                            DropdownMenuItem<String>(value: c, child: Text(c)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) onCityChanged(val);
                  },
                ),
              ),
            ],
          ),
          const Divider(color: Color(0xFFEDF2EE), height: 20),
          InkWell(
            onTap: () => onAvailabilityChanged(!availabilityOnly),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: availabilityOnly,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) => onAvailabilityChanged(val ?? false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tous les médicaments disponibles',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Distance : pharmacies classées de la plus proche à la plus éloignée (données de démonstration).',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(MapEntry<int, PharmacyDemoData> entry) {
    final p = entry.value;
    final isFull = isMatch(p);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '🏥 ${p.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      isFull ? const Color(0xFFE8F6ED) : AppColors.warningSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isFull ? 'Tous disponibles' : 'Stock partiel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isFull ? const Color(0xFF147C54) : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '📍 $city · ${p.distance} · Disponibilité : ${isFull ? 'Tous en stock' : 'Stock partiel'}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => onSelectPharmacy(entry.key),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: Color(0xFFCFE5D6)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Choisir cette pharmacie →',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
