import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/pharmacy.dart';
import '../widgets/pharmacy_map_bottom_card.dart';
import '../widgets/yaounde_landmark_filter_bar.dart';

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
      isPartner: true,
      horaires: '24h/24 (De garde)',
      proposeLivraison: true,
      responsable: 'Dr. Jean Mballa',
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
      isPartner: true,
      horaires: '08h00 - 21h00',
      proposeLivraison: true,
      responsable: 'Dr. Aïcha Bello',
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
      isPartner: true,
      horaires: '24h/24 (De garde)',
      proposeLivraison: false,
      responsable: 'Dr. Paul Biye',
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
      isPartner: false,
      horaires: '08h00 - 20h00',
      proposeLivraison: false,
    ),
    Pharmacy(
      id: 'pharmacy-mfoundi',
      nom: 'Pharmacie du Mfoundi',
      licenceOnpc: 'ONPC-YDE-0304',
      quartier: 'Centre-Ville',
      carrefourRepere: 'Marché Mfoundi',
      latitude: 3.8640,
      longitude: 11.5230,
      telephoneGarde: '+237699000099',
      estOuverte: true,
      estDeGarde: false,
      distanceMetres: 600,
      isPartner: false,
      horaires: '08h00 - 19h30',
      proposeLivraison: false,
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
                    final isPartner = pharmacy.isPartner;
                    return Marker(
                      point: LatLng(pharmacy.latitude, pharmacy.longitude),
                      width: isSelected ? 60 : 46,
                      height: isSelected ? 60 : 46,
                      child: GestureDetector(
                        onTap: () => _onSelectPharmacy(pharmacy),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isPartner
                                ? (pharmacy.estDeGarde ? AppColors.success : AppColors.primary)
                                : const Color(0xFF64748B),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPartner ? Colors.white : const Color(0xFFCBD5E1),
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            isPartner ? Icons.local_pharmacy_rounded : Icons.storefront_outlined,
                            color: Colors.white,
                            size: isPartner ? 24 : 20,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // 2. En-tête : carrousel des carrefours de Yaoundé
          YaoundeLandmarkFilterBar(
            selectedLandmark: _selectedLandmark,
            partnerCount: _samplePharmacies.where((p) => p.isPartner).length,
            nonPartnerCount: _samplePharmacies.where((p) => !p.isPartner).length,
            onSelect: _onSelectLandmark,
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
    void snack(String msg, {Color? bg}) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: bg),
      );
    }

    return PharmacyMapBottomCard(
      pharmacy: pharmacy,
      onClose: () => setState(() => _selectedPharmacy = null),
      onCall: () => snack('Appel vers : ${pharmacy.telephoneGarde}'),
      onSolicit: () => snack(
        'Cette officine recevra votre demande lors de la prochaine recherche.',
        bg: AppColors.primary,
      ),
    );
  }
}
