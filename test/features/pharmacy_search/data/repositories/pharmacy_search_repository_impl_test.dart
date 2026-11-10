import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/data/datasources/yaounde_pharmacy_data_source.dart';
import 'package:medmate/features/pharmacy_search/data/models/medication_model.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';
import 'package:medmate/features/pharmacy_search/data/repositories/pharmacy_search_repository_impl.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:mocktail/mocktail.dart';

class MockYaoundePharmacyDataSource extends Mock
    implements YaoundePharmacyDataSource {}

void main() {
  late PharmacySearchRepositoryImpl repository;
  late MockYaoundePharmacyDataSource mockDataSource;

  const testMedicationModel = MedicationModel(
    id: 'med-001',
    codeNational: 'CIP-CMR-001',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  const testPharmacyModel = PharmacyModel(
    id: 'pharma-bastos-01',
    nom: 'Pharmacie de Bastos',
    licenceOnpc: 'ONPC-YDE-001',
    quartier: 'Bastos',
    carrefourRepere: 'Carrefour Warda',
    latitude: 3.8688,
    longitude: 11.5175,
    telephoneGarde: '+237222201122',
    estOuverte: true,
    estDeGarde: true,
    estPartenaire: true,
  );

  setUp(() {
    mockDataSource = MockYaoundePharmacyDataSource();
    repository = PharmacySearchRepositoryImpl(dataSource: mockDataSource);
  });

  group('PharmacySearchRepositoryImpl', () {
    group('searchMedications', () {
      test('returns Right(List<Medication>) on success', () async {
        when(() => mockDataSource.searchMedications('paracetamol'))
            .thenAnswer((_) async => [testMedicationModel]);

        final result = await repository.searchMedications('paracetamol');

        expect(result.isRight(), isTrue);
        expect(
          result.getOrElse((_) => []),
          equals([testMedicationModel]),
        );
        verify(() => mockDataSource.searchMedications('paracetamol')).called(1);
      });

      test('returns Left(ServerFailure) on ServerException', () async {
        when(() => mockDataSource.searchMedications(any()))
            .thenThrow(const ServerException('Erreur catalogue'));

        final result = await repository.searchMedications('paracetamol');

        expect(
          result,
          equals(const Left<Failure, List<Medication>>(ServerFailure('Erreur catalogue'))),
        );
      });

      test('returns Left(ServerFailure) on generic Exception', () async {
        when(() => mockDataSource.searchMedications(any()))
            .thenThrow(Exception('Erreur inattendue'));

        final result = await repository.searchMedications('paracetamol');

        expect(result.isLeft(), isTrue);
      });
    });

    group('searchNearbyPharmacies', () {
      test('returns Right(List<Pharmacy>) on success', () async {
        when(
          () => mockDataSource.searchNearbyPharmacies(
            quartier: any(named: 'quartier'),
            carrefourRepere: any(named: 'carrefourRepere'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusMetres: any(named: 'radiusMetres'),
            onlyOpen: any(named: 'onlyOpen'),
            onlyDuty: any(named: 'onlyDuty'),
          ),
        ).thenAnswer((_) async => [testPharmacyModel]);

        final result = await repository.searchNearbyPharmacies(quartier: 'Bastos');

        expect(result.isRight(), isTrue);
        expect(
          result.getOrElse((_) => []),
          equals([testPharmacyModel]),
        );
      });

      test('returns Left(ServerFailure) on ServerException', () async {
        when(
          () => mockDataSource.searchNearbyPharmacies(
            quartier: any(named: 'quartier'),
            carrefourRepere: any(named: 'carrefourRepere'),
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            radiusMetres: any(named: 'radiusMetres'),
            onlyOpen: any(named: 'onlyOpen'),
            onlyDuty: any(named: 'onlyDuty'),
          ),
        ).thenThrow(const ServerException('PostGIS indisponible'));

        final result = await repository.searchNearbyPharmacies();

        expect(
          result,
          equals(const Left<Failure, List<Pharmacy>>(ServerFailure('PostGIS indisponible'))),
        );
      });
    });

    group('getPharmacyById', () {
      test('returns Right(Pharmacy) when pharmacy found', () async {
        when(() => mockDataSource.getPharmacyById('pharma-bastos-01'))
            .thenAnswer((_) async => testPharmacyModel);

        final result = await repository.getPharmacyById('pharma-bastos-01');

        expect(result, equals(const Right<Failure, Pharmacy>(testPharmacyModel)));
      });

      test('returns Left(NotFoundFailure) when NotFoundException thrown', () async {
        when(() => mockDataSource.getPharmacyById('unknown'))
            .thenThrow(const NotFoundException('Officine introuvable'));

        final result = await repository.getPharmacyById('unknown');

        expect(
          result,
          equals(const Left<Failure, Pharmacy>(NotFoundFailure('Officine introuvable'))),
        );
      });

      test('returns Left(ServerFailure) on generic Exception', () async {
        when(() => mockDataSource.getPharmacyById(any()))
            .thenThrow(Exception('Fail'));

        final result = await repository.getPharmacyById('pharma-01');

        expect(result.isLeft(), isTrue);
      });
    });
  });
}
