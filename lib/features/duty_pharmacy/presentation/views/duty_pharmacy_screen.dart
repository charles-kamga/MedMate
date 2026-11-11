import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/duty_pharmacy_item.dart';
import '../controllers/duty_pharmacy_cubit.dart';
import '../controllers/duty_pharmacy_state.dart';
import '../widgets/duty_pharmacy_card.dart';
import '../widgets/duty_schedule_header_card.dart';

export '../../domain/entities/duty_pharmacy_item.dart';

/// Écran Officiel « Pharmacies de garde » (Clean Architecture + Cubit)
class DutyPharmacyScreen extends StatelessWidget {
  const DutyPharmacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DutyPharmacyCubit>(
      create: (_) => DutyPharmacyCubit(),
      child: const _DutyPharmacyBody(),
    );
  }
}

class _DutyPharmacyBody extends StatelessWidget {
  const _DutyPharmacyBody();

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Contact Pharmacie de Garde'),
          content: Text(
            'Numéro d’urgence de garde : $phone\n\nAppel direct non pris en charge sur cet appareil.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openRoute(
    BuildContext context,
    DutyPharmacyItem pharmacy,
  ) async {
    final uri = Uri.parse(
      AppConfig.buildOsmSearchUrl(
        latitude: pharmacy.latitude,
        longitude: pharmacy.longitude,
        label: pharmacy.name,
      ),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d’ouvrir la carte pour ${pharmacy.name}'),
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              '✚',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
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
        ],
      ),
    );
  }

  Widget _buildSearchField(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        onChanged: context.read<DutyPharmacyCubit>().updateSearchQuery,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Filtrer par quartier (ex: Bastos, Melen)...',
          hintStyle: const TextStyle(color: Color(0xFF9EABA5), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: const Color(0xFFFAFDFA),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDBE9E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4EEE7)),
      ),
      child: const Text(
        'Avant de vous déplacer, appelez la pharmacie pour confirmer la disponibilité des équipes de garde et des produits nécessaires.',
        style: TextStyle(
          fontSize: 12,
          height: 1.45,
          color: Color(0xFF557165),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<DutyPharmacyCubit>();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: BlocBuilder<DutyPharmacyCubit, DutyPharmacyState>(
        builder: (context, state) {
          final items = state.displayedPharmacies;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DutyScheduleHeaderCard(
                  cities: state.cities,
                  selectedCity: state.selectedCity,
                  activeSegment: state.activeSegment,
                  onCityChanged: cubit.selectCity,
                  onSegmentChanged: cubit.selectSegment,
                ),
                const SizedBox(height: 16),
                if (state.activeSegment == 1) _buildSearchField(context),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text(
                        'Aucune pharmacie de garde trouvée pour ce critère.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                else
                  ...items.map(
                    (p) => DutyPharmacyCard(
                      pharmacy: p,
                      onCall: () => _makePhoneCall(context, p.phone),
                      onRoute: () => _openRoute(context, p),
                    ),
                  ),
                const SizedBox(height: 10),
                _buildSafetyNotice(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
