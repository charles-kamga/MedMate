import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/search_medications.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_state.dart';
import 'package:mocktail/mocktail.dart';

class MockSearchMedicationsUseCase extends Mock
    implements SearchMedicationsUseCase {}

void main() {
  late MockSearchMedicationsUseCase mockSearchMedicationsUseCase;
  late MedicationCatalogCubit cubit;

  const sampleMedications = [
    Medication(
      id: 'med-paracetamol',
      nomCommercial: 'Paracétamol 500 mg',
      dci: 'Paracétamol',
      forme: 'Comprimé',
      dosage: '500 mg',
      classeTherapeutique: 'Antalgique',
      prixHomologueCfa: 1500,
      necessiteOrdonnance: false,
    ),
    Medication(
      id: 'med-amox',
      nomCommercial: 'Amoxicilline 500 mg',
      dci: 'Amoxicilline',
      forme: 'Gélule',
      dosage: '500 mg',
      classeTherapeutique: 'Antibiotique',
      prixHomologueCfa: 3200,
      necessiteOrdonnance: true,
    ),
  ];

  setUp(() {
    mockSearchMedicationsUseCase = MockSearchMedicationsUseCase();
    cubit = MedicationCatalogCubit(
      searchMedicationsUseCase: mockSearchMedicationsUseCase,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('MedicationCatalogCubit', () {
    test("l'état initial est MedicationCatalogInitial", () {
      expect(cubit.state, equals(const MedicationCatalogInitial()));
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.isError, isFalse);
      expect(cubit.state.medications, isEmpty);
    });

    blocTest<MedicationCatalogCubit, MedicationCatalogState>(
      'émet [MedicationCatalogInitial] lorsque la requête de recherche est vide',
      build: () => cubit,
      act: (cubit) => cubit.search('   '),
      expect: () => [
        const MedicationCatalogInitial(),
      ],
      verify: (_) {
        verifyNever(() => mockSearchMedicationsUseCase(any()));
      },
    );

    blocTest<MedicationCatalogCubit, MedicationCatalogState>(
      'émet [MedicationCatalogLoading, MedicationCatalogLoaded] en cas de succès',
      setUp: () {
        when(() => mockSearchMedicationsUseCase('para'))
            .thenAnswer((_) async => const Right(sampleMedications));
      },
      build: () => cubit,
      act: (cubit) => cubit.search('para'),
      expect: () => [
        const MedicationCatalogLoading(),
        const MedicationCatalogLoaded(sampleMedications),
      ],
      verify: (_) {
        verify(() => mockSearchMedicationsUseCase('para')).called(1);
      },
    );

    blocTest<MedicationCatalogCubit, MedicationCatalogState>(
      "émet [MedicationCatalogLoading, MedicationCatalogError] en cas d'échec",
      setUp: () {
        when(() => mockSearchMedicationsUseCase('inconnu'))
            .thenAnswer((_) async => const Left(
                  ServerFailure('Erreur serveur catalogue indisponible'),
                ),);
      },
      build: () => cubit,
      act: (cubit) => cubit.search('inconnu'),
      expect: () => [
        const MedicationCatalogLoading(),
        const MedicationCatalogError('Erreur serveur catalogue indisponible'),
      ],
      verify: (_) {
        verify(() => mockSearchMedicationsUseCase('inconnu')).called(1);
      },
    );

    blocTest<MedicationCatalogCubit, MedicationCatalogState>(
      "clear() réinitialise l'état à MedicationCatalogInitial",
      build: () => cubit,
      seed: () => const MedicationCatalogLoaded(sampleMedications),
      act: (cubit) => cubit.clear(),
      expect: () => [
        const MedicationCatalogInitial(),
      ],
    );
  });
}
