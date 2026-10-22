import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bento_card.dart';
import '../../domain/entities/pharmacy.dart';

/// Vue cartographique interactive de Yaoundé (OpenStreetMap + Repères Urbains)
class PharmacyMapView extends StatefulWidget {
  const PharmacyMapView({super.key, this.enableNetworkTiles = true});

  final bool enableNetworkTiles;

  @override
  State<PharmacyMapView> createState() => _PharmacyMapViewState();
}

class _PharmacyMapViewState extends State<PharmacyMapView> {
  late final MapController _mapController;
  YaoundeLandmark? _selectedLandmark;
  Pharmacy? _selectedPharmacy;

  // Officines témoins réelles de Yaoundé
  static const List<Pharmacy> _samplePharmacies = [
    Pharmacy(
      id: 'pharmacy-centre',
      nom: 'Grande Pharmacie du Centre',
      licenceOnpc: 'ONPC-YDE-0042',
      quartier: 'Poste Centrale',
      carrefourRepere: 'Rond-Point Poste Centrale',
      latitude: 3.8665,
      longitude: 11.5205,
      telephoneGarde: '+237699112233',
      estOuverte: true,
      estDeGarde: true,
      distanceMetres: 350,
    ),
    Pharmacy(
      id: 'pharmacy-soleil',
      nom: 'Pharmacie du Soleil',
      licenceOnpc: 'ONPC-YDE-0105',
      quartier: 'Poste Centrale',
      carrefourRepere: 'Carrefour Warda',
      latitude: 3.8692,
      longitude: 11.5170,
      telephoneGarde: '+237677445566',
      estOuverte: true,
      estDeGarde: false,
      distanceMetres: 800,
    ),
    Pharmacy(
      id: 'pharmacy-obili',
      nom: "Pharmacie d'Obili",
      licenceOnpc: 'ONPC-YDE-0211',
      quartier: 'Obili',
      carrefourRepere: 'Carrefour Obili',
      latitude: 3.8542,
      longitude: 11.4925,
      telephoneGarde: '+237695332211',
      estOuverte: true,
      estDeGarde: true,
      distanceMetres: 1200,
    ),
    Pharmacy(
      id: 'pharmacy-acacia',
      nom: 'Pharmacie Acacia Biyem-Assi',
      licenceOnpc: 'ONPC-YDE-0188',
      quartier: 'Biyem-Assi',
      carrefourRepere: 'Carrefour Acacia',
      latitude: 3.8372,
      longitude: 11.4885,
      telephoneGarde: '+237670998877',
      estOuverte: true,
      estDeGarde: false,
      distanceMetres: 2400,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLandmark = YaoundeLandmarks.list.first;
  }

  void _onSelectLandmark(YaoundeLandmark landmark) {
    setState(() {
      _selectedLandmark = landmark;
      _selectedPharmacy = null;
    });
    _mapController.move(LatLng(landmark.latitude, landmark.longitude), 14.5);
  }

  void _onSelectPharmacy(Pharmacy pharmacy) {
    setState(() {
      _selectedPharmacy = pharmacy;
    });
    _mapController.move(LatLng(pharmacy.latitude, pharmacy.longitude), 15);
  }

  @override
  Widget build(BuildContext context) {
    final centerLatLng = LatLng(
      _selectedLandmark?.latitude ?? 3.8667,
      _selectedLandmark?.longitude ?? 11.5200,
    );

    return Scaffold(
      body: Stack(
        children: [
          // 1. Carte Interactive OpenStreetMap (flutter_map)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: centerLatLng,
              initialZoom: 13.8,
              minZoom: 11,
              maxZoom: 18,
            ),
            children: [
              if (widget.enableNetworkTiles)
                TileLayer(
                  urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'cm.medmate.medmate',
                ),
              MarkerLayer(
                markers: [
                  // Marqueur du repère sélectionné (Carrefour de Yaoundé)
                  if (_selectedLandmark != null)
                    Marker(
                      point: LatLng(_selectedLandmark!.latitude, _selectedLandmark!.longitude),
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.my_location_rounded, color: AppColors.secondary, size: 28),
                        ),
                      ),
                    ),
                  // Marqueurs des pharmacies
                  ..._samplePharmacies.map((pharmacy) {
                    final isSelected = _selectedPharmacy?.id == pharmacy.id;
                    return Marker(
                      point: LatLng(pharmacy.latitude, pharmacy.longitude),
                      width: isSelected ? 60 : 46,
                      height: isSelected ? 60 : 46,
                      child: GestureDetector(
                        onTap: () => _onSelectPharmacy(pharmacy),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: pharmacy.estDeGarde ? AppColors.success : AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. En-tête Flottant : Carrousel des Carrefours & Quartiers de Yaoundé
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: BentoCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.95),
                    child: Row(
                      children: [
                        const Icon(Icons.explore_rounded, color: AppColors.primary, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Repères & Carrefours de Yaoundé',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PostGIS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
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
                      final isSelected = _selectedLandmark?.id == landmark.id;
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
                        onPressed: () => _onSelectLandmark(landmark),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // 3. Fiche Rétractable Bento en Bas d'Écran (Détails Pharmacie Sélectionnée)
          if (_selectedPharmacy != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildPharmacyDetailCard(_selectedPharmacy!),
            ),
        ],
      ),
    );
  }

  Widget _buildPharmacyDetailCard(Pharmacy pharmacy) {
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => setState(() => _selectedPharmacy = null),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pharmacy.estDeGarde ? AppColors.successSoft : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pharmacy.estDeGarde ? 'DE GARDE CE SOIR' : 'OUVERTE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: pharmacy.estDeGarde ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${pharmacy.quartier} • ${pharmacy.carrefourRepere}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.navigation_outlined, size: 16, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text(
                '~${pharmacy.distanceMetres?.toStringAsFixed(0)} m du repère sélectionné',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                pharmacy.licenceOnpc,
                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.phone_rounded, size: 18),
                  label: const Text('Appel Garde'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Appel vers : ${pharmacy.telephoneGarde}')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Disponibilité'),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Demande de disponibilité flash envoyée à ${pharmacy.nom}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
