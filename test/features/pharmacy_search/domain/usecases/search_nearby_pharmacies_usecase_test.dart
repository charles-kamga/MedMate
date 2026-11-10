import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_search_repository.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_nearby_pharmacies_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacySearchRepository extends Mock
    implements PharmacySearchRepository {}

void main() {
  late SearchNearbyPharmaciesUseCase useCase;
  late MockPharmacySearchRepository mockRepository;

  const samplePharmacies = [
    Pharmacy(
      id: 'pharma-1',
      nom: 'Pharmacie Bastos',
      licenceOnpc: 'ONPC-CMR-001',
      quartier: 'Bastos',
      carrefourRepere: 'Carrefour Warda',
      latitude: 3.8792,
      longitude: 11.5167,
      telephoneGarde: '+237699000001',
      estOuverte: true,
      estDeGarde: true,
      estPartenaire: true,
      distanceMetres: 250,
    ),
  ];

  setUp(() {
    mockRepository = MockPharmacySearchRepository();
    useCase = SearchNearbyPharmaciesUseCase(mockRepository);
  });

  group('SearchNearbyPharmaciesUseCase', () {
    test('returns Right(List<Pharmacy>) when searching by quartier landmark',
        () async {
      when(
        () => mockRepository.searchNearbyPharmacies(
          quartier: 'Bastos',
          carrefourRepere: null,
          latitude: null,
          longitude: null,
          radiusMetres: 3000,
          onlyOpen: true,
          onlyDuty: null,
        ),
      ).thenAnswer((_) async => const Right(samplePharmacies));

      final result = await useCase(
        const SearchNearbyPharmaciesParams(
          quartier: ' Bastos ',
          radiusMetres: 3000,
          onlyOpen: true,
        ),
      );

      expect(
        result,
        equals(const Right<Failure, List<Pharmacy>>(samplePharmacies)),
      );
      verify(
        () => mockRepository.searchNearbyPharmacies(
          quartier: 'Bastos',
          carrefourRepere: null,
          latitude: null,
          longitude: null,
          radiusMetres: 3000,
          onlyOpen: true,
          onlyDuty: null,
        ),
      ).called(1);
    });

    test('returns Right(List<Pharmacy>) when searching by carrefour landmark',
        () async {
      when(
        () => mockRepository.searchNearbyPharmacies(
          quartier: null,
          carrefourRepere: 'Carrefour Obili',
          latitude: null,
          longitude: null,
          radiusMetres: null,
          onlyOpen: null,
          onlyDuty: null,
        ),
      ).thenAnswer((_) async => const Right(samplePharmacies));

      final result = await useCase(
        const SearchNearbyPharmaciesParams(
          carrefourRepere: 'Carrefour Obili',
        ),
      );

      expect(
        result,
        equals(const Right<Failure, List<Pharmacy>>(samplePharmacies)),
      );
      verify(
        () => mockRepository.searchNearbyPharmacies(
          quartier: null,
          carrefourRepere: 'Carrefour Obili',
          latitude: null,
          longitude: null,
          radiusMetres: null,
          onlyOpen: null,
          onlyDuty: null,
        ),
      ).called(1);
    });

    test('returns Right(List<Pharmacy>) when searching by GPS coordinates',
        () async {
      when(
        () => mockRepository.searchNearbyPharmacies(
          quartier: null,
          carrefourRepere: null,
          latitude: 3.8792,
          longitude: 11.5167,
          radiusMetres: 2000,
          onlyOpen: null,
          onlyDuty: null,
        ),
      ).thenAnswer((_) async => const Right(samplePharmacies));

      final result = await useCase(
        const SearchNearbyPharmaciesParams(
          latitude: 3.8792,
          longitude: 11.5167,
          radiusMetres: 2000,
        ),
      );

      expect(
        result,
        equals(const Right<Failure, List<Pharmacy>>(samplePharmacies)),
      );
      verify(
        () => mockRepository.searchNearbyPharmacies(
          quartier: null,
          carrefourRepere: null,
          latitude: 3.8792,
          longitude: 11.5167,
          radiusMetres: 2000,
          onlyOpen: null,
          onlyDuty: null,
        ),
      ).called(1);
    });

    test('returns Left(LocationFailure) when no location is provided',
        () async {
      final result = await useCase(
        const SearchNearbyPharmaciesParams(),
      );

      expect(
        result,
        equals(
          const Left<Failure, List<Pharmacy>>(
            LocationFailure(
              'Veuillez fournir un quartier, un carrefour ou des coordonnées GPS.',
            ),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test(
        'returns Left(LocationFailure) when only one coordinate is provided',
        () async {
      final resultLatOnly = await useCase(
        const SearchNearbyPharmaciesParams(latitude: 3.8792),
      );
      final resultLonOnly = await useCase(
        const SearchNearbyPharmaciesParams(longitude: 11.5167),
      );

      expect(
        resultLatOnly,
        equals(
          const Left<Failure, List<Pharmacy>>(
            LocationFailure('Coordonnées géographiques incomplètes.'),
          ),
        ),
      );
      expect(
        resultLonOnly,
        equals(
          const Left<Failure, List<Pharmacy>>(
            LocationFailure('Coordonnées géographiques incomplètes.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test(
        'returns Left(LocationFailure) when coordinates are outside valid bounds',
        () async {
      final resultBadLat = await useCase(
        const SearchNearbyPharmaciesParams(
          latitude: 95,
          longitude: 11.5167,
        ),
      );
      final resultBadLon = await useCase(
        const SearchNearbyPharmaciesParams(
          latitude: 3.8792,
          longitude: 195,
        ),
      );

      expect(
        resultBadLat,
        equals(
          const Left<Failure, List<Pharmacy>>(
            LocationFailure('Coordonnées géographiques invalides.'),
          ),
        ),
      );
      expect(
        resultBadLon,
        equals(
          const Left<Failure, List<Pharmacy>>(
            LocationFailure('Coordonnées géographiques invalides.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository fails', () async {
      const serverFailure = ServerFailure('Erreur spatiale PostGIS.');
      when(
        () => mockRepository.searchNearbyPharmacies(
          quartier: 'Essos',
          carrefourRepere: null,
          latitude: null,
          longitude: null,
          radiusMetres: null,
          onlyOpen: null,
          onlyDuty: null,
        ),
      ).thenAnswer((_) async => const Left(serverFailure));

      final result = await useCase(
        const SearchNearbyPharmaciesParams(quartier: 'Essos'),
      );

      expect(
        result,
        equals(const Left<Failure, List<Pharmacy>>(serverFailure)),
      );
      verify(
        () => mockRepository.searchNearbyPharmacies(
          quartier: 'Essos',
          carrefourRepere: null,
          latitude: null,
          longitude: null,
          radiusMetres: null,
          onlyOpen: null,
          onlyDuty: null,
        ),
      ).called(1);
    });
  });
}
