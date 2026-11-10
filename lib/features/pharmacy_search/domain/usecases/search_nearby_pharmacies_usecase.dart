import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_search_repository.dart';

/// Paramètres de recherche de proximité pour les officines de Yaoundé.
class SearchNearbyPharmaciesParams extends Equatable {
  const SearchNearbyPharmaciesParams({
    this.quartier,
    this.carrefourRepere,
    this.latitude,
    this.longitude,
    this.radiusMetres,
    this.onlyOpen,
    this.onlyDuty,
  });

  /// Quartier d'implantation à Yaoundé.
  final String? quartier;

  /// Carrefour ou repère remarquable.
  final String? carrefourRepere;

  /// Latitude WGS84.
  final double? latitude;

  /// Longitude WGS84.
  final double? longitude;

  /// Rayon de recherche en mètres.
  final double? radiusMetres;

  /// Alias de compatibilité pour [radiusMetres].
  double? get radiusMeters => radiusMetres;

  /// Filtrer uniquement les officines actuellement ouvertes.
  final bool? onlyOpen;

  /// Filtrer uniquement les officines assurant la garde.
  final bool? onlyDuty;

  @override
  List<Object?> get props => [
        quartier,
        carrefourRepere,
        latitude,
        longitude,
        radiusMetres,
        onlyOpen,
        onlyDuty,
      ];
}

/// Recherche des officines à proximité d'un repère urbain ou d'une position GPS.
class SearchNearbyPharmaciesUseCase {
  const SearchNearbyPharmaciesUseCase(this._repository);

  final PharmacySearchRepository _repository;

  /// Valide les paramètres géographiques et délègue la requête au dépôt.
  Future<Either<Failure, List<Pharmacy>>> call(
    SearchNearbyPharmaciesParams params,
  ) async {
    final hasQuartier =
        params.quartier != null && params.quartier!.trim().isNotEmpty;
    final hasCarrefour = params.carrefourRepere != null &&
        params.carrefourRepere!.trim().isNotEmpty;

    final lat = params.latitude;
    final lon = params.longitude;
    final hasBothCoords = lat != null && lon != null;
    final hasPartialCoords = (lat != null && lon == null) ||
        (lat == null && lon != null);

    if (hasPartialCoords) {
      return const Left(
        LocationFailure('Coordonnées géographiques incomplètes.'),
      );
    }

    if (!hasQuartier && !hasCarrefour && !hasBothCoords) {
      return const Left(
        LocationFailure(
          'Veuillez fournir un quartier, un carrefour ou des coordonnées GPS.',
        ),
      );
    }

    if (hasBothCoords) {
      if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) {
        return const Left(
          LocationFailure('Coordonnées géographiques invalides.'),
        );
      }
    }

    return _repository.searchNearbyPharmacies(
      quartier: hasQuartier ? params.quartier!.trim() : null,
      carrefourRepere: hasCarrefour ? params.carrefourRepere!.trim() : null,
      latitude: lat,
      longitude: lon,
      radiusMetres: params.radiusMetres,
      onlyOpen: params.onlyOpen,
      onlyDuty: params.onlyDuty,
    );
  }
}
