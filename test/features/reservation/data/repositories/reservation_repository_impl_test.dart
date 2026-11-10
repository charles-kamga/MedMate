import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/datasources/flash_order_data_source.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:mocktail/mocktail.dart';

class MockFlashOrderDataSource extends Mock implements FlashOrderDataSource {}

void main() {
  late MockFlashOrderDataSource mockDataSource;
  late ReservationRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      FlashRequestModel(
        id: 'dummy',
        clientRequestId: 'dummy',
        items: const [],
        quartierOuCarrefour: 'dummy',
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: DateTime.now(),
        expiresAt: DateTime.now(),
      ),
    );
  });

  setUp(() {
    mockDataSource = MockFlashOrderDataSource();
    repository = ReservationRepositoryImpl(dataSource: mockDataSource);
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

  const tBasketItem = BasketItemModel(
    medication: tMedication,
    quantite: 2,
  );

  final tFlashRequest = FlashRequestModel(
    id: 'req-repo-1',
    clientRequestId: 'client-req-1',
    items: const [tBasketItem],
    quartierOuCarrefour: 'Bastos',
    statut: FlashRequestStatus.active,
    vagueActuelle: 1,
    pharmaciesNotifieesIds: const ['pharma-bastos-01'],
    offresRecues: const [],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 30)),
  );

  final tReservation = ReservationModel(
    id: 'res-repo-1',
    clientReservationId: 'client-res-1',
    demandeId: 'req-repo-1',
    offreId: 'offer-1',
    pharmacyId: 'pharma-bastos-01',
    codeRetraitOtp6Chiffres: '123456',
    statut: ReservationStatus.pending,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  group('ReservationRepositoryImpl', () {
    test('submitFlashRequest returns Right(FlashRequest) on success', () async {
      when(() => mockDataSource.submitFlashRequest(any()))
          .thenAnswer((_) async => tFlashRequest);

      final result = await repository.submitFlashRequest(
        clientRequestId: 'client-req-1',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
      );

      expect(result, equals(Right<Failure, FlashRequest>(tFlashRequest)));
      verify(() => mockDataSource.submitFlashRequest(any())).called(1);
    });

    test('submitFlashRequest returns Left(ServerFailure) on ServerException', () async {
      when(() => mockDataSource.submitFlashRequest(any()))
          .thenThrow(const ServerException('Erreur serveur'));

      final result = await repository.submitFlashRequest(
        clientRequestId: 'client-req-1',
        items: const [tBasketItem],
        quartierOuCarrefour: 'Bastos',
      );

      expect(result, equals(const Left<Failure, FlashRequest>(ServerFailure('Erreur serveur'))));
    });

    test('escalateDispatchWave returns Right(FlashRequest) on success', () async {
      when(
        () => mockDataSource.escalateDispatchWave(
          demandeId: any(named: 'demandeId'),
          nextWaveNumber: any(named: 'nextWaveNumber'),
          eligiblePharmacyIds: any(named: 'eligiblePharmacyIds'),
        ),
      ).thenAnswer((_) async => tFlashRequest);

      final result = await repository.escalateDispatchWave(
        demandeId: 'req-repo-1',
        nextWaveNumber: 2,
        eligiblePharmacyIds: const ['pharma-mokolo-01'],
      );

      expect(result, equals(Right<Failure, FlashRequest>(tFlashRequest)));
    });

    test('escalateDispatchWave returns Left(NotFoundFailure) on NotFoundException', () async {
      when(
        () => mockDataSource.escalateDispatchWave(
          demandeId: any(named: 'demandeId'),
          nextWaveNumber: any(named: 'nextWaveNumber'),
          eligiblePharmacyIds: any(named: 'eligiblePharmacyIds'),
        ),
      ).thenThrow(const NotFoundException('Demande non trouvée'));

      final result = await repository.escalateDispatchWave(
        demandeId: 'unknown',
        nextWaveNumber: 2,
        eligiblePharmacyIds: const ['pharma-mokolo-01'],
      );

      expect(result, equals(const Left<Failure, FlashRequest>(NotFoundFailure('Demande non trouvée'))));
    });

    test('selectPharmacyOffer returns Right(Reservation) on success', () async {
      when(
        () => mockDataSource.selectPharmacyOffer(
          clientReservationId: any(named: 'clientReservationId'),
          demandeId: any(named: 'demandeId'),
          offreId: any(named: 'offreId'),
          patientPhone: any(named: 'patientPhone'),
        ),
      ).thenAnswer((_) async => tReservation);

      final result = await repository.selectPharmacyOffer(
        clientReservationId: 'client-res-1',
        demandeId: 'req-repo-1',
        offreId: 'offer-1',
        patientPhone: '+237699001122',
      );

      expect(result, equals(Right<Failure, Reservation>(tReservation)));
    });

    test('selectPharmacyOffer returns Left(ReservationFailure) on ReservationException', () async {
      when(
        () => mockDataSource.selectPharmacyOffer(
          clientReservationId: any(named: 'clientReservationId'),
          demandeId: any(named: 'demandeId'),
          offreId: any(named: 'offreId'),
          patientPhone: any(named: 'patientPhone'),
        ),
      ).thenThrow(const ReservationException('Demande expirée'));

      final result = await repository.selectPharmacyOffer(
        clientReservationId: 'client-res-1',
        demandeId: 'req-repo-1',
        offreId: 'offer-1',
        patientPhone: '+237699001122',
      );

      expect(result, equals(const Left<Failure, Reservation>(ReservationFailure('Demande expirée'))));
    });

    test('confirmReservationOtp returns Right(Reservation) on success', () async {
      when(
        () => mockDataSource.confirmReservationOtp(
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenAnswer((_) async => tReservation);

      final result = await repository.confirmReservationOtp(
        reservationId: 'res-repo-1',
        otpCode: '123456',
      );

      expect(result, equals(Right<Failure, Reservation>(tReservation)));
    });

    test('confirmReservationOtp returns Left(ValidationFailure) on ValidationException', () async {
      when(
        () => mockDataSource.confirmReservationOtp(
          reservationId: any(named: 'reservationId'),
          otpCode: any(named: 'otpCode'),
        ),
      ).thenThrow(const ValidationException('Code OTP invalide'));

      final result = await repository.confirmReservationOtp(
        reservationId: 'res-repo-1',
        otpCode: '000000',
      );

      expect(result, equals(const Left<Failure, Reservation>(ValidationFailure('Code OTP invalide'))));
    });

    test('getFlashRequestById returns Right(FlashRequest) and handles NotFoundException', () async {
      when(() => mockDataSource.getFlashRequestById('req-1'))
          .thenAnswer((_) async => tFlashRequest);

      final result = await repository.getFlashRequestById('req-1');
      expect(result, equals(Right<Failure, FlashRequest>(tFlashRequest)));

      when(() => mockDataSource.getFlashRequestById('unknown'))
          .thenThrow(const NotFoundException('Non trouvée'));

      final failResult = await repository.getFlashRequestById('unknown');
      expect(failResult, equals(const Left<Failure, FlashRequest>(NotFoundFailure('Non trouvée'))));
    });

    test('getReservationById returns Right(Reservation) and handles NotFoundException', () async {
      when(() => mockDataSource.getReservationById('res-1'))
          .thenAnswer((_) async => tReservation);

      final result = await repository.getReservationById('res-1');
      expect(result, equals(Right<Failure, Reservation>(tReservation)));

      when(() => mockDataSource.getReservationById('unknown'))
          .thenThrow(const NotFoundException('Non trouvée'));

      final failResult = await repository.getReservationById('unknown');
      expect(failResult, equals(const Left<Failure, Reservation>(NotFoundFailure('Non trouvée'))));
    });
  });
}
