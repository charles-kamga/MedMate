import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/duty_pharmacy/domain/repositories/duty_pharmacy_repository.dart';
import 'package:medmate/features/duty_pharmacy/domain/usecases/get_duty_pharmacies_by_quartier_usecase.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:mocktail/mocktail.dart';

class MockDutyPharmacyRepository extends Mock
    implements DutyPharmacyRepository {}

void main() {
  late GetDutyPharmaciesByQuartierUseCase useCase;
  late MockDutyPharmacyRepository mockRepository;

  const samplePharmacy = Pharmacy(
    id: 'pharma-bastos',
    nom: 'Pharmacie Bastos',
    licenceOnpc: 'ONPC-CMR-1029',
    quartier: 'Bastos',
    carrefourRepere: 'Carrefour Warda',
    latitude: 3.8821,
    longitude: 11.5165,
    telephoneGarde: '+237699112233',
    estOuverte: true,
    estDeGarde: true,
    estPartenaire: true,
  );

  final sampleSchedule = DutySchedule(
    id: 'duty-1',
    pharmacy: samplePharmacy,
    dateGarde: DateTime(2026, 11, 9),
    heureDebut: '20:00',
    heureFin: '08:00',
    verifieParOnpc: true,
  );

  setUp(() {
    mockRepository = MockDutyPharmacyRepository();
    useCase = GetDutyPharmaciesByQuartierUseCase(mockRepository);
  });

  group('GetDutyPharmaciesByQuartierUseCase', () {
    test('returns Right(List<DutySchedule>) when valid quartier is provided',
        () async {
      final expectedSchedules = [sampleSchedule];
      when(
        () => mockRepository.getDutyPharmaciesByQuartier(
          quartier: 'Bastos',
          targetDate: any(named: 'targetDate'),
        ),
      ).thenAnswer((_) async => Right(expectedSchedules));

      final result = await useCase(
        const GetDutyPharmaciesByQuartierParams(quartier: '  Bastos  '),
      );

      expect(
        result,
        equals(Right<Failure, List<DutySchedule>>(expectedSchedules)),
      );
      verify(
        () => mockRepository.getDutyPharmaciesByQuartier(
          quartier: 'Bastos',
          targetDate: null,
        ),
      ).called(1);
    });

    test('returns Left(LocationFailure) when quartier is empty or whitespace',
        () async {
      final resultEmpty = await useCase(
        const GetDutyPharmaciesByQuartierParams(quartier: ''),
      );
      final resultWhitespace = await useCase(
        const GetDutyPharmaciesByQuartierParams(quartier: '   '),
      );

      expect(
        resultEmpty,
        equals(
          const Left<Failure, List<DutySchedule>>(
            LocationFailure('Le quartier doit être spécifié.'),
          ),
        ),
      );
      expect(
        resultWhitespace,
        equals(
          const Left<Failure, List<DutySchedule>>(
            LocationFailure('Le quartier doit être spécifié.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository query fails', () async {
      const failure = ServerFailure('Erreur de consultation PostGIS.');
      when(
        () => mockRepository.getDutyPharmaciesByQuartier(
          quartier: any(named: 'quartier'),
          targetDate: any(named: 'targetDate'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        const GetDutyPharmaciesByQuartierParams(quartier: 'Mokolo'),
      );

      expect(result, equals(const Left<Failure, List<DutySchedule>>(failure)));
    });
  });
}
