import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/duty_pharmacy/data/datasources/duty_pharmacy_data_source.dart';
import 'package:medmate/features/duty_pharmacy/data/models/duty_schedule_model.dart';
import 'package:medmate/features/duty_pharmacy/data/repositories/duty_pharmacy_repository_impl.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';
import 'package:mocktail/mocktail.dart';

class MockDutyPharmacyDataSource extends Mock
    implements DutyPharmacyDataSource {}

void main() {
  late DutyPharmacyRepositoryImpl repository;
  late MockDutyPharmacyDataSource mockDataSource;

  final testDate = DateTime(2026, 11, 9);

  const testPharmacy = PharmacyModel(
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

  final testSchedule = DutyScheduleModel(
    id: 'duty-bastos-01',
    pharmacy: testPharmacy,
    dateGarde: testDate,
    heureDebut: '20:00',
    heureFin: '08:00',
    verifieParOnpc: true,
    groupeGarde: 'Groupe Centre-Nord ONPC',
  );

  setUp(() {
    mockDataSource = MockDutyPharmacyDataSource();
    repository = DutyPharmacyRepositoryImpl(dataSource: mockDataSource);
  });

  group('DutyPharmacyRepositoryImpl', () {
    group('getDutyPharmaciesByQuartier', () {
      test('returns Right(List<DutySchedule>) on success', () async {
        when(
          () => mockDataSource.getDutyPharmaciesByQuartier(
            quartier: 'Bastos',
            targetDate: any(named: 'targetDate'),
          ),
        ).thenAnswer((_) async => [testSchedule]);

        final result = await repository.getDutyPharmaciesByQuartier(
          quartier: 'Bastos',
        );

        expect(result.isRight(), isTrue);
        expect(
          result.getOrElse((_) => []),
          equals([testSchedule]),
        );
        verify(
          () => mockDataSource.getDutyPharmaciesByQuartier(
            quartier: 'Bastos',
            targetDate: null,
          ),
        ).called(1);
      });

      test('returns Left(ServerFailure) on ServerException', () async {
        when(
          () => mockDataSource.getDutyPharmaciesByQuartier(
            quartier: any(named: 'quartier'),
            targetDate: any(named: 'targetDate'),
          ),
        ).thenThrow(const ServerException('Roster non disponible'));

        final result = await repository.getDutyPharmaciesByQuartier(
          quartier: 'Bastos',
        );

        expect(
          result,
          equals(const Left<Failure, List<DutySchedule>>(ServerFailure('Roster non disponible'))),
        );
      });

      test('returns Left(ServerFailure) on generic Exception', () async {
        when(
          () => mockDataSource.getDutyPharmaciesByQuartier(
            quartier: any(named: 'quartier'),
            targetDate: any(named: 'targetDate'),
          ),
        ).thenThrow(Exception('Erreur inattendue'));

        final result = await repository.getDutyPharmaciesByQuartier(
          quartier: 'Bastos',
        );

        expect(result.isLeft(), isTrue);
      });
    });

    group('getAllActiveDutySchedules', () {
      test('returns Right(List<DutySchedule>) on success', () async {
        when(
          () => mockDataSource.getAllActiveDutySchedules(
            targetDate: any(named: 'targetDate'),
          ),
        ).thenAnswer((_) async => [testSchedule]);

        final result = await repository.getAllActiveDutySchedules();

        expect(result.isRight(), isTrue);
        expect(
          result.getOrElse((_) => []),
          equals([testSchedule]),
        );
        verify(() => mockDataSource.getAllActiveDutySchedules(targetDate: null))
            .called(1);
      });

      test('returns Left(ServerFailure) on ServerException', () async {
        when(
          () => mockDataSource.getAllActiveDutySchedules(
            targetDate: any(named: 'targetDate'),
          ),
        ).thenThrow(const ServerException('Erreur serveur'));

        final result = await repository.getAllActiveDutySchedules();

        expect(
          result,
          equals(const Left<Failure, List<DutySchedule>>(ServerFailure('Erreur serveur'))),
        );
      });
    });
  });
}
