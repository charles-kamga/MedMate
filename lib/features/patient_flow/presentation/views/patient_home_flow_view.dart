import 'package:flutter/material.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/theme/app_colors.dart';
import 'package:medmate/features/patient_flow/presentation/widgets/patient_home_shared_widgets.dart';
import 'package:medmate/features/patient_flow/presentation/widgets/patient_home_step0_view.dart';
import 'package:medmate/features/patient_flow/presentation/widgets/patient_home_step1_choose_view.dart';
import 'package:medmate/features/patient_flow/presentation/widgets/patient_home_step2_find_view.dart';
import 'package:medmate/features/patient_flow/presentation/widgets/patient_home_step3_detail_view.dart';
import 'package:medmate/features/patient_flow/presentation/widgets/patient_home_step4_route_view.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:medmate/features/patient_flow/presentation/widgets/patient_home_shared_widgets.dart'
    show PharmacyDemoData;

/// Vue principale interactive du parcours patient (Étapes 0 à 4).
class PatientHomeFlowView extends StatefulWidget {
  const PatientHomeFlowView({
    super.key,
    this.onOpenReminders,
  });

  final VoidCallback? onOpenReminders;

  @override
  State<PatientHomeFlowView> createState() => _PatientHomeFlowViewState();
}

class _PatientHomeFlowViewState extends State<PatientHomeFlowView> {
  static const List<String> medicines = [
    'Paracétamol 500 mg',
    'Amoxicilline 500 mg',
    'Vitamine C 1000 mg',
    'Ibuprofène 400 mg',
    'Sérum physiologique',
  ];

  // DÉMO — données fictives (maquette historique)
  static const List<PharmacyDemoData> pharmacies = [
    PharmacyDemoData(
      name: 'Pharmacie du Centre',
      distance: '1,2 km',
      phone: '+237600000001',
      stock: [0, 1, 2, 3, 4],
    ),
    PharmacyDemoData(
      name: 'Pharmacie Santé Plus',
      distance: '2,4 km',
      phone: '+237600000002',
      stock: [0, 2, 3, 4],
    ),
    PharmacyDemoData(
      name: 'Pharmacie de la Paix',
      distance: '3,1 km',
      phone: '+237600000003',
      stock: [0, 1, 2, 4],
    ),
  ];

  static const List<String> cities = [
    'Yaoundé',
    'Douala',
    'Bertoua',
    'Bafoussam',
  ];

  int _step = 0;
  List<int> _selected = [];
  int _chosen = 0;
  String _query = '';
  String _city = 'Yaoundé';
  bool _availabilityOnly = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _back() {
    setState(() {
      _step = _step > 1 ? _step - 1 : 0;
    });
  }

  void _quick(int index) {
    setState(() {
      _selected = [index];
      _query = '';
      _searchController.clear();
      _step = 1;
    });
  }

  void _add(int index) {
    setState(() {
      if (!_selected.contains(index)) {
        _selected.add(index);
      }
      _query = '';
      _searchController.clear();
    });
  }

  void _remove(int index) {
    setState(() {
      _selected.remove(index);
    });
  }

  bool _isMatch(PharmacyDemoData p) => _selected.every(p.stock.contains);

  Future<void> _openOsmMap(String pharmacyName) async {
    final uri = Uri.parse(
      AppConfig.buildOsmQueryUrl('$pharmacyName $_city Cameroun'),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Impossible d'ouvrir Maps pour $pharmacyName"),
        ),
      );
    }
  }

  void _showNoticeDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Information Démonstration',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_step > 0) PatientHomeWizardHeader(step: _step, onBack: _back),
          if (_step == 0)
            PatientHomeStep0View(
              city: _city,
              cities: cities,
              searchController: _searchController,
              query: _query,
              onCityChanged: (c) => setState(() => _city = c),
              onQueryChanged: (q) => setState(() => _query = q),
              onStartSearch: () => setState(() => _step = 1),
              onQuickPick: _quick,
              onOpenReminders: widget.onOpenReminders,
            ),
          if (_step == 1)
            PatientHomeStep1ChooseView(
              medicines: medicines,
              selectedIndices: _selected,
              query: _query,
              searchController: _searchController,
              onQueryChanged: (q) => setState(() => _query = q),
              onAdd: _add,
              onRemove: _remove,
              onContinue: () => setState(() => _step = 2),
            ),
          if (_step == 2)
            PatientHomeStep2FindView(
              pharmacies: pharmacies,
              city: _city,
              cities: cities,
              availabilityOnly: _availabilityOnly,
              isMatch: _isMatch,
              onCityChanged: (c) => setState(() => _city = c),
              onAvailabilityChanged: (v) =>
                  setState(() => _availabilityOnly = v),
              onSelectPharmacy: (i) => setState(() {
                _chosen = i;
                _step = 3;
              }),
            ),
          if (_step == 3)
            PatientHomeStep3DetailView(
              pharmacy: pharmacies[_chosen],
              city: _city,
              medicines: medicines,
              selectedIndices: _selected,
              onSeeRoute: () => setState(() => _step = 4),
              onShowNotice: _showNoticeDialog,
            ),
          if (_step == 4)
            PatientHomeStep4RouteView(
              pharmacy: pharmacies[_chosen],
              city: _city,
              medicines: medicines,
              selectedIndices: _selected,
              onOpenMaps: () => _openOsmMap(pharmacies[_chosen].name),
              onFinish: () => setState(() => _step = 0),
            ),
        ],
      ),
    );
  }
}
