import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pharmacy.dart';
import '../repositories/pharmacy_repository.dart';

class SearchPharmaciesParams extends Equatable {
  const SearchPharmaciesParams({
    required this.latitude,
    required this.longitude,
    this.maxRadiusMeters = 3500,
  });

  final double latitude;
  final double longitude;
  final double maxRadiusMeters;

  @override
  List<Object?> get props => [latitude, longitude, maxRadiusMeters];
}

class SearchPharmaciesUseCase {
  const SearchPharmaciesUseCase(this._repository);

  final PharmacyRepository _repository;

  Future<Either<Failure, List<Pharmacy>>> call(SearchPharmaciesParams params) {
    return _repository.searchNearbyPharmacies(
      latitude: params.latitude,
      longitude: params.longitude,
      maxRadiusMeters: params.maxRadiusMeters,
    );
  }
}
