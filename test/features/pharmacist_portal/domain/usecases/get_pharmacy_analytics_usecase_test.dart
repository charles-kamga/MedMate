import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pharmacy_analytics_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistPortalRepository extends Mock
    implements PharmacistPortalRepository {}

void main() {
  late GetPharmacyAnalyticsUseCase useCase;
  late MockPharmacistPortalRepository mockRepository;

  final sampleDate = DateTime(2026, 11, 9);
  final sampleAnalytics = PharmacyDailyAnalytics(
    id: 'stat-1',
    pharmacyId: 'pharma-bastos',
    date: sampleDate,
    totalDemandsReceived: 15,
    totalQuotesSubmitted: 14,
    totalReservationsConfirmed: 12,
    conversionRate: 0.857,
  );

  setUp(() {
    mockRepository = MockPharmacistPortalRepository();
    useCase = GetPharmacyAnalyticsUseCase(mockRepository);
  });

  group('GetPharmacyAnalyticsUseCase & Minimisation des Données de Santé', () {
    test(
        'returns Right(PharmacyDailyAnalytics) when pharmacyId is valid',
        () async {
      when(
        () => mockRepository.getPharmacyAnalytics(
          pharmacyId: 'pharma-bastos',
          date: sampleDate,
        ),
      ).thenAnswer((_) async => Right(sampleAnalytics));

      final result = await useCase(
        GetPharmacyAnalyticsParams(
          pharmacyId: '  pharma-bastos  ',
          date: sampleDate,
        ),
      );

      expect(
        result,
        equals(Right<Failure, PharmacyDailyAnalytics>(sampleAnalytics)),
      );
      verify(
        () => mockRepository.getPharmacyAnalytics(
          pharmacyId: 'pharma-bastos',
          date: sampleDate,
        ),
      ).called(1);
    });

    test('returns Left(AuthFailure) when pharmacyId is empty or whitespace',
        () async {
      final resultEmpty = await useCase(
        GetPharmacyAnalyticsParams(
          pharmacyId: '',
          date: sampleDate,
        ),
      );
      final resultWhitespace = await useCase(
        GetPharmacyAnalyticsParams(
          pharmacyId: '   ',
          date: sampleDate,
        ),
      );

      expect(
        resultEmpty,
        equals(
          const Left<Failure, PharmacyDailyAnalytics>(
            AuthFailure('Identifiant pharmacie manquant.'),
          ),
        ),
      );
      expect(
        resultWhitespace,
        equals(
          const Left<Failure, PharmacyDailyAnalytics>(
            AuthFailure('Identifiant pharmacie manquant.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository query fails', () async {
      const failure = ServerFailure('Erreur de requête analytique.');
      when(
        () => mockRepository.getPharmacyAnalytics(
          pharmacyId: any(named: 'pharmacyId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(
        GetPharmacyAnalyticsParams(
          pharmacyId: 'pharma-bastos',
          date: sampleDate,
        ),
      );

      expect(
        result,
        equals(const Left<Failure, PharmacyDailyAnalytics>(failure)),
      );
    });
  });
}
