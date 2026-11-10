import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/data/datasources/pharmacist_portal_data_source.dart';
import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacist_portal/data/models/incoming_demand_model.dart';
import 'package:medmate/features/pharmacist_portal/data/models/pharmacy_daily_analytics_model.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/incoming_demand.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/data/models/pharmacy_offer_model.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistPortalDataSource extends Mock
    implements PharmacistPortalDataSource {}

void main() {
  late MockPharmacistPortalDataSource mockDataSource;
  late PharmacistPortalRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const CounterQuoteSubmissionModel(
        demandId: 'dummy',
        pharmacyId: 'dummy',
        itemResponses: [],
        montantTotal: 0,
        livraisonPossible: false,
      ),
    );
  });

  setUp(() {
    mockDataSource = MockPharmacistPortalDataSource();
    repository = PharmacistPortalRepositoryImpl(dataSource: mockDataSource);
  });

  const tMedication = Medication(
    id: 'med-para-500',
    codeNational: 'CIP-3400936184729',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  final tFlashRequest = FlashRequestModel(
    id: 'req-repo-1',
    clientRequestId: 'client-req-1',
    items: const [
      BasketItemModel(medication: tMedication, quantite: 2),
    ],
    quartierOuCarrefour: 'Bastos',
    statut: FlashRequestStatus.active,
    vagueActuelle: 1,
    pharmaciesNotifieesIds: const ['pharma-bastos-01'],
    offresRecues: const [],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
  );

  final tIncomingDemand = IncomingDemandModel(
    id: 'demand-repo-1',
    flashRequest: tFlashRequest,
    receivedAt: DateTime.now(),
    isResponded: false,
  );

  final tOffer = PharmacyOfferModel(
    id: 'offer-repo-1',
    demandeId: 'req-repo-1',
    pharmacyId: 'pharma-bastos-01',
    pharmacyNom: 'Pharmacie Bastos',
    quartier: 'Bastos',
    items: const [
      OfferItemResponseModel(
        medicationId: 'med-para-500',
        status: ItemAvailabilityStatus.available,
        prixUnitaireCommunicParPharmacien: 1500,
      ),
    ],
    montantTotalPropose: 3000,
    livraisonDisponible: false,
    createdAt: DateTime.now(),
  );

  final tReservation = ReservationModel(
    id: 'res-repo-1',
    clientReservationId: 'client-res-1',
    demandeId: 'req-repo-1',
    offreId: 'offer-repo-1',
    pharmacyId: 'pharma-bastos-01',
    codeRetraitOtp6Chiffres: '123456',
    statut: ReservationStatus.confirmedAtCounter,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  final tAnalytics = PharmacyDailyAnalyticsModel(
    id: 'analytics-repo-1',
    pharmacyId: 'pharma-bastos-01',
    date: DateTime.now(),
    totalDemandsReceived: 5,
    totalQuotesSubmitted: 4,
    totalReservationsConfirmed: 3,
    conversionRate: 0.75,
  );

  group('PharmacistPortalRepositoryImpl', () {
    test('getIncomingDemands returns Right(List<IncomingDemand>) on success', () async {
      when(() => mockDataSource.getIncomingDemands('pharma-bastos-01'))
          .thenAnswer((_) async => [tIncomingDemand]);

      final result = await repository.getIncomingDemands(
        pharmacyId: 'pharma-bastos-01',
      );

      expect(result.isRight(), isTrue);
      expect(result.getOrElse((_) => []), equals([tIncomingDemand]));
      verify(() => mockDataSource.getIncomingDemands('pharma-bastos-01')).called(1);
    });

    test('getIncomingDemands returns Left(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.getIncomingDemands('pharma-bastos-01'))
          .thenThrow(const ServerException('Erreur serveur'));

      final result = await repository.getIncomingDemands(
        pharmacyId: 'pharma-bastos-01',
      );

      expect(result, equals(const Left<Failure, List<IncomingDemand>>(ServerFailure('Erreur serveur'))));
    });

    test('submitCounterQuote returns Right(PharmacyOffer) on success', () async {
      when(() => mockDataSource.submitCounterQuote(any()))
          .thenAnswer((_) async => tOffer);

      const submission = CounterQuoteSubmission(
        demandId: 'req-repo-1',
        pharmacyId: 'pharma-bastos-01',
        itemResponses: [
          OfferItemResponseModel(
            medicationId: 'med-para-500',
            status: ItemAvailabilityStatus.available,
            prixUnitaireCommunicParPharmacien: 1500,
          ),
        ],
        montantTotal: 3000,
        livraisonPossible: false,
      );

      final result = await repository.submitCounterQuote(submission);
      expect(result, equals(Right<Failure, PharmacyOffer>(tOffer)));
    });

    test('submitCounterQuote returns Left(NotFoundFailure) on NotFoundException', () async {
      when(() => mockDataSource.submitCounterQuote(any()))
          .thenThrow(const NotFoundException('Demande non trouvée'));

      const submission = CounterQuoteSubmission(
        demandId: 'unknown',
        pharmacyId: 'pharma-bastos-01',
        itemResponses: [],
        montantTotal: 0,
        livraisonPossible: false,
      );

      final result = await repository.submitCounterQuote(submission);
      expect(result, equals(const Left<Failure, PharmacyOffer>(NotFoundFailure('Demande non trouvée'))));
    });

    test('validatePickupOtp returns Right(Reservation) on success', () async {
      when(
        () => mockDataSource.validatePickupOtp(
          pharmacyId: any(named: 'pharmacyId'),
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenAnswer((_) async => tReservation);

      final result = await repository.validatePickupOtp(
        pharmacyId: 'pharma-bastos-01',
        reservationId: 'res-repo-1',
        otpCode: '123456',
      );

      expect(result, equals(Right<Failure, Reservation>(tReservation)));
    });

    test('validatePickupOtp returns Left(AuthFailure) on AuthException', () async {
      when(
        () => mockDataSource.validatePickupOtp(
          pharmacyId: any(named: 'pharmacyId'),
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenThrow(const AuthException('Officine non autorisée'));

      final result = await repository.validatePickupOtp(
        pharmacyId: 'wrong-pharma',
        reservationId: 'res-repo-1',
        otpCode: '123456',
      );

      expect(result, equals(const Left<Failure, Reservation>(AuthFailure('Officine non autorisée'))));
    });

    test('validatePickupOtp returns Left(ValidationFailure) on ValidationException', () async {
      when(
        () => mockDataSource.validatePickupOtp(
          pharmacyId: any(named: 'pharmacyId'),
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenThrow(const ValidationException('Code OTP invalide'));

      final result = await repository.validatePickupOtp(
        pharmacyId: 'pharma-bastos-01',
        reservationId: 'res-repo-1',
        otpCode: '000000',
      );

      expect(result, equals(const Left<Failure, Reservation>(ValidationFailure('Code OTP invalide'))));
    });

    test('validatePickupOtp returns Left(ReservationFailure) on ReservationException', () async {
      when(
        () => mockDataSource.validatePickupOtp(
          pharmacyId: any(named: 'pharmacyId'),
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenThrow(const ReservationException('Délai de 2h expiré'));

      final result = await repository.validatePickupOtp(
        pharmacyId: 'pharma-bastos-01',
        reservationId: 'res-repo-1',
        otpCode: '123456',
      );

      expect(result, equals(const Left<Failure, Reservation>(ReservationFailure('Délai de 2h expiré'))));
    });

    test('getPharmacyAnalytics returns Right(PharmacyDailyAnalytics) on success', () async {
      when(
        () => mockDataSource.getPharmacyAnalytics(
          pharmacyId: any(named: 'pharmacyId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) async => tAnalytics);

      final result = await repository.getPharmacyAnalytics(
        pharmacyId: 'pharma-bastos-01',
        date: DateTime.now(),
      );

      expect(result, equals(Right<Failure, PharmacyDailyAnalytics>(tAnalytics)));
    });
  });
}
