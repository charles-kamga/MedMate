import 'package:equatable/equatable.dart';

/// Données immuables d'une pharmacie de garde officielle (ONPC Cameroun)
class DutyPharmacyItem extends Equatable {
  const DutyPharmacyItem({
    required this.name,
    required this.quarter,
    required this.activity,
    required this.hours,
    required this.distance,
    required this.phone,
    required this.city,
    this.latitude = 3.8667,
    this.longitude = 11.5200,
    this.isPartner = true,
  });

  final String name;
  final String quarter;
  final String activity;
  final String hours;
  final String distance;
  final String phone;
  final String city;
  final double latitude;
  final double longitude;
  final bool isPartner;

  @override
  List<Object?> get props => [
        name,
        quarter,
        activity,
        hours,
        distance,
        phone,
        city,
        latitude,
        longitude,
        isPartner,
      ];
}
