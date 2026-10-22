import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_pharmacies.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacyRepository extends Mock implements PharmacyRepository {}

void main() {
  late MockPharmacyRepository mockRepository;
  late SearchPharmaciesUseCase useCase;

  setUp(() {
    mockRepository = MockPharmacyRepository();
    useCase = SearchPharmaciesUseCase(mockRepository);
  });

  const tLat = 3.8688;
  const tLon = 11.5175;
  const tRadius = 3500.0;
  const tParams = SearchPharmaciesParams(
    latitude: tLat,
    longitude: tLon,
    maxRadiusMeters: tRadius,
  );

  final tPharmacies = [
    const Pharmacy(
      id: 'pharmacy-1',
      nom: 'Grande Pharmacie du Centre',
      licenceOnpc: 'ONPC-YDE-0042',
      quartier: 'Poste Centrale',
      carrefourRepere: 'Rond-Point Poste Centrale',
      latitude: 3.8665,
      longitude: 11.5205,
      telephoneGarde: '+237699112233',
      estOuverte: true,
      estDeGarde: true,
      distanceMetres: 450,
    ),
  ];

  test('doit retourner une liste de pharmacies lors d''une recherche réussie', () async {
    // Arrange
    when(
      () => mockRepository.searchNearbyPharmacies(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        maxRadiusMeters: any(named: 'maxRadiusMeters'),
      ),
    ).thenAnswer((_) async => Right(tPharmacies));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, Right(tPharmacies));
    verify(
      () => mockRepository.searchNearbyPharmacies(
        latitude: tLat,
        longitude: tLon,
        maxRadiusMeters: tRadius,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('doit propager un NetworkFailure en cas de problème de connexion', () async {
    // Arrange
    const tFailure = NetworkFailure();
    when(
      () => mockRepository.searchNearbyPharmacies(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
        maxRadiusMeters: any(named: 'maxRadiusMeters'),
      ),
    ).thenAnswer((_) async => const Left(tFailure));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, const Left(tFailure));
    verify(
      () => mockRepository.searchNearbyPharmacies(
        latitude: tLat,
        longitude: tLon,
        maxRadiusMeters: tRadius,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
