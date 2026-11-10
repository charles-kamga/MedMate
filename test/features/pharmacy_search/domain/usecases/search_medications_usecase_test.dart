import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_search_repository.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_medications_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacySearchRepository extends Mock
    implements PharmacySearchRepository {}

void main() {
  late SearchMedicationsUseCase useCase;
  late MockPharmacySearchRepository mockRepository;

  const sampleMedications = [
    Medication(
      id: 'med-1',
      codeNational: 'CIP-001',
      nomCommercial: 'Paracétamol Biogaran',
      dci: 'Paracétamol',
      forme: 'Comprimé',
      dosage: '500 mg',
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-2',
      codeNational: 'CIP-002',
      nomCommercial: 'Efferalgan 1g',
      dci: 'Paracétamol',
      forme: 'Comprimé effervescent',
      dosage: '1 g',
      necessiteOrdonnance: false,
    ),
  ];

  setUp(() {
    mockRepository = MockPharmacySearchRepository();
    useCase = SearchMedicationsUseCase(mockRepository);
  });

  group('SearchMedicationsUseCase', () {
    test('returns Right(List<Medication>) on valid query >= 2 characters',
        () async {
      when(() => mockRepository.searchMedications('paracétamol')).thenAnswer(
        (_) async => const Right(sampleMedications),
      );

      final result = await useCase(
        const SearchMedicationsParams(query: '  paracétamol  '),
      );

      expect(
        result,
        equals(const Right<Failure, List<Medication>>(sampleMedications)),
      );
      verify(() => mockRepository.searchMedications('paracétamol')).called(1);
    });

    test(
        'returns Right([]) immediately without repository call when query < 2 chars',
        () async {
      final resultEmpty = await useCase(
        const SearchMedicationsParams(query: ''),
      );
      final resultSingleChar = await useCase(
        const SearchMedicationsParams(query: 'p'),
      );
      final resultWhitespace = await useCase(
        const SearchMedicationsParams(query: '   '),
      );

      expect(resultEmpty, equals(const Right<Failure, List<Medication>>([])));
      expect(
        resultSingleChar,
        equals(const Right<Failure, List<Medication>>([])),
      );
      expect(
        resultWhitespace,
        equals(const Right<Failure, List<Medication>>([])),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository search fails', () async {
      const serverFailure = ServerFailure('Erreur de base de données PostGIS.');
      when(() => mockRepository.searchMedications('amoxicilline')).thenAnswer(
        (_) async => const Left(serverFailure),
      );

      final result = await useCase(
        const SearchMedicationsParams(query: 'amoxicilline'),
      );

      expect(
        result,
        equals(const Left<Failure, List<Medication>>(serverFailure)),
      );
      verify(() => mockRepository.searchMedications('amoxicilline')).called(1);
    });
  });
}
