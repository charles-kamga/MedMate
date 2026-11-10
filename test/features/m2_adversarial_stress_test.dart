import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/auth/domain/entities/patient_session.dart';
import 'package:medmate/features/duty_pharmacy/domain/entities/duty_schedule.dart';
import 'package:medmate/features/duty_pharmacy/domain/repositories/duty_pharmacy_repository.dart';
import 'package:medmate/features/duty_pharmacy/domain/usecases/get_duty_pharmacies_by_quartier_usecase.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/incoming_demand.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pharmacy_analytics_usecase.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote_usecase.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_pickup_otp_usecase.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/pharmacy.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/confirm_reservation_otp_usecase.dart';
import 'package:medmate/features/reservation/domain/usecases/escalate_dispatch_wave_usecase.dart';
import 'package:medmate/features/reservation/domain/usecases/select_pharmacy_offer_usecase.dart';
import 'package:medmate/features/reservation/domain/usecases/submit_flash_request_usecase.dart';
import 'package:mocktail/mocktail.dart';

class MockReservationRepo extends Mock implements ReservationRepository {}
class MockDutyPharmacyRepo extends Mock implements DutyPharmacyRepository {}
class MockPharmacistPortalRepo extends Mock implements PharmacistPortalRepository {}

void main() {
  const sampleMedication = Medication(
    id: 'med-para-500',
    codeNational: 'CIP-3400936184729',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  const samplePharmacy = Pharmacy(
    id: 'pharma-bastos',
    nom: 'Pharmacie Bastos',
    licenceOnpc: 'ONPC-CMR-1001',
    quartier: 'Bastos',
    carrefourRepere: 'Carrefour Warda',
    latitude: 3.8812,
    longitude: 11.5173,
    telephoneGarde: '+237699112233',
    estOuverte: true,
    estDeGarde: true,
    estPartenaire: true,
    distanceMetres: 350,
  );

  group('EMPIRICAL CHALLENGER: Milestone 2 Adversarial Stress Suite', () {
    // -------------------------------------------------------------------------
    // 1. OTP Code Verification Matrix (^\d{6}$)
    // -------------------------------------------------------------------------
    group('Attack Matrix 1: OTP Code Validation Invariant', () {
      late MockReservationRepo mockReservationRepo;
      late ConfirmReservationOtpUseCase confirmUseCase;
      late MockPharmacistPortalRepo mockPortalRepo;
      late ValidatePickupOtpUseCase validateUseCase;

      setUp(() {
        mockReservationRepo = MockReservationRepo();
        confirmUseCase = ConfirmReservationOtpUseCase(mockReservationRepo);
        mockPortalRepo = MockPharmacistPortalRepo();
        validateUseCase = ValidatePickupOtpUseCase(mockPortalRepo);
      });

      final validOtps = ['000000', '999999', '123456', '012345', '789012'];
      for (final otp in validOtps) {
        test('OTP "$otp" is accepted by ConfirmReservationOtpUseCase', () async {
          final dummyReservation = Reservation(
            id: 'res-1',
            clientReservationId: 'c-1',
            demandeId: 'd-1',
            offreId: 'o-1',
            pharmacyId: 'p-1',
            codeRetraitOtp6Chiffres: otp,
            statut: ReservationStatus.confirmedAtCounter,
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
          );
          when(
            () => mockReservationRepo.confirmReservationOtp(
              reservationId: 'res-1',
              otpCode: otp,
            ),
          ).thenAnswer((_) async => Right(dummyReservation));

          final result = await confirmUseCase(
            ConfirmReservationOtpParams(
              reservationId: 'res-1',
              otpCode: otp,
            ),
          );
          expect(result.isRight(), isTrue);
        });

        test('OTP "$otp" is accepted by ValidatePickupOtpUseCase', () async {
          final dummyReservation = Reservation(
            id: 'res-1',
            clientReservationId: 'c-1',
            demandeId: 'd-1',
            offreId: 'o-1',
            pharmacyId: 'p-1',
            codeRetraitOtp6Chiffres: otp,
            statut: ReservationStatus.completed,
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
          );
          when(
            () => mockPortalRepo.validatePickupOtp(
              pharmacyId: 'p-1',
              reservationId: 'res-1',
              otpCode: otp,
            ),
          ).thenAnswer((_) async => Right(dummyReservation));

          final result = await validateUseCase(
            ValidatePickupOtpParams(
              pharmacyId: 'p-1',
              reservationId: 'res-1',
              otpCode: otp,
            ),
          );
          expect(result.isRight(), isTrue);
        });
      }

      final malformedOtps = [
        '',
        ' ',
        '   ',
        '0',
        '12',
        '123',
        '1234',
        '12345', // 5 digits
        '1234567', // 7 digits
        '12345678', // 8 digits
        '12345A', // alphanumeric
        'abcdef', // letters
        '12 345', // space in middle
        '-12345', // negative sign
        '+12345', // plus sign
        '12.345', // decimal point
        '12345\n', // newline trimmed becomes 5 digits
        '1234\t5', // tab in middle
        '٠١٢٣٤٥', // Eastern Arabic digits
        '①②③④⑤⑥', // circled digits
      ];

      for (final badOtp in malformedOtps) {
        test(
          'Malformed OTP "$badOtp" is rejected by ConfirmReservationOtpUseCase',
          () async {
            final result = await confirmUseCase(
              ConfirmReservationOtpParams(
                reservationId: 'res-1',
                otpCode: badOtp,
              ),
            );
            expect(result.isLeft(), isTrue);
            result.fold(
              (failure) {
                expect(failure, isA<ReservationFailure>());
                expect(
                  failure.message,
                  equals('Le code OTP doit comporter exactement 6 chiffres.'),
                );
              },
              (_) => fail('Should have rejected bad OTP "$badOtp"'),
            );
            verifyZeroInteractions(mockReservationRepo);
          },
        );

        test(
          'Malformed OTP "$badOtp" is rejected by ValidatePickupOtpUseCase',
          () async {
            final result = await validateUseCase(
              ValidatePickupOtpParams(
                pharmacyId: 'pharma-1',
                reservationId: 'res-1',
                otpCode: badOtp,
              ),
            );
            expect(result.isLeft(), isTrue);
            result.fold(
              (failure) {
                expect(failure, isA<ReservationFailure>());
                expect(
                  failure.message,
                  equals('Le code OTP doit comporter exactement 6 chiffres.'),
                );
              },
              (_) => fail('Should have rejected bad OTP "$badOtp"'),
            );
            verifyZeroInteractions(mockPortalRepo);
          },
        );
      }
    });

    // -------------------------------------------------------------------------
    // 2. Reservation TTL 2 Hours & Expiration Stress
    // -------------------------------------------------------------------------
    group('Attack Matrix 2: Reservation TTL 2h & Expiration Boundary', () {
      late MockReservationRepo mockReservationRepo;
      late ConfirmReservationOtpUseCase confirmUseCase;

      setUp(() {
        mockReservationRepo = MockReservationRepo();
        confirmUseCase = ConfirmReservationOtpUseCase(mockReservationRepo);
      });

      test('Strict TTL 2h invariant: expiresAt - createdAt == 2 hours exactly', () {
        final now = DateTime.now();
        final reservation = Reservation(
          id: 'res-ttl',
          clientReservationId: 'c-ttl',
          demandeId: 'd-ttl',
          offreId: 'o-ttl',
          pharmacyId: 'p-ttl',
          codeRetraitOtp6Chiffres: '123456',
          statut: ReservationStatus.pending,
          createdAt: now,
          expiresAt: now.add(const Duration(hours: 2)),
        );

        expect(
          reservation.expiresAt.difference(reservation.createdAt),
          equals(const Duration(hours: 2)),
        );
      });

      test('isExpired is true when expiresAt is 1 millisecond in the past', () {
        final past = DateTime.now().subtract(const Duration(milliseconds: 1));
        final expiredRes = Reservation(
          id: 'res-expired',
          clientReservationId: 'c-1',
          demandeId: 'd-1',
          offreId: 'o-1',
          pharmacyId: 'p-1',
          codeRetraitOtp6Chiffres: '123456',
          statut: ReservationStatus.pending,
          createdAt: past.subtract(const Duration(hours: 2)),
          expiresAt: past,
        );

        expect(expiredRes.isExpired, isTrue);
      });

      test('isExpired is false when expiresAt is 1 hour in the future', () {
        final future = DateTime.now().add(const Duration(hours: 1));
        final activeRes = Reservation(
          id: 'res-active',
          clientReservationId: 'c-1',
          demandeId: 'd-1',
          offreId: 'o-1',
          pharmacyId: 'p-1',
          codeRetraitOtp6Chiffres: '123456',
          statut: ReservationStatus.pending,
          createdAt: future.subtract(const Duration(hours: 2)),
          expiresAt: future,
        );

        expect(activeRes.isExpired, isFalse);
        expect(activeRes.remainingTime.inMinutes, greaterThan(0));
      });

      test(
        'ConfirmReservationOtpUseCase blocks confirmation of expired reservation',
        () async {
          final expiredRes = Reservation(
            id: 'res-expired',
            clientReservationId: 'c-1',
            demandeId: 'd-1',
            offreId: 'o-1',
            pharmacyId: 'p-1',
            codeRetraitOtp6Chiffres: '123456',
            statut: ReservationStatus.pending,
            createdAt:
                DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
            expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
          );

          final result = await confirmUseCase(
            ConfirmReservationOtpParams(
              reservationId: 'res-expired',
              otpCode: '123456',
              reservation: expiredRes,
            ),
          );

          expect(result.isLeft(), isTrue);
          result.fold(
            (failure) {
              expect(failure, isA<ReservationFailure>());
              expect(
                failure.message,
                equals('La réservation a expiré (délai de 2h dépassé).'),
              );
            },
            (_) => fail('Should have failed on expired reservation'),
          );
          verifyZeroInteractions(mockReservationRepo);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 3. Basket Item Validation in SubmitFlashRequestUseCase
    // -------------------------------------------------------------------------
    group('Attack Matrix 3: Empty Baskets & Negative Quantities in SubmitFlashRequest', () {
      late MockReservationRepo mockRepo;
      late SubmitFlashRequestUseCase submitUseCase;

      setUp(() {
        mockRepo = MockReservationRepo();
        submitUseCase = SubmitFlashRequestUseCase(mockRepo);
      });

      test('Empty basket list [] is rejected with ValidationFailure', () async {
        final result = await submitUseCase(
          const SubmitFlashRequestParams(
            clientRequestId: 'req-001',
            items: [],
            quartierOuCarrefour: 'Bastos',
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, FlashRequest>(
              ValidationFailure('Le panier ne peut pas être vide.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      final badQuantities = [0, -1, -5, -9999];
      for (final qty in badQuantities) {
        test('Basket item with quantity $qty is rejected', () async {
          final result = await submitUseCase(
            SubmitFlashRequestParams(
              clientRequestId: 'req-001',
              items: [
                BasketItem(medication: sampleMedication, quantite: qty),
              ],
              quartierOuCarrefour: 'Bastos',
            ),
          );

          expect(
            result,
            equals(
              const Left<Failure, FlashRequest>(
                ValidationFailure(
                  'La quantité de chaque médicament doit être au moins 1.',
                ),
              ),
            ),
          );
          verifyZeroInteractions(mockRepo);
        });
      }

      test('Mixed basket with 1 valid and 1 quantity 0 item is rejected', () async {
        final result = await submitUseCase(
          const SubmitFlashRequestParams(
            clientRequestId: 'req-001',
            items: [
              BasketItem(medication: sampleMedication, quantite: 3),
              BasketItem(medication: sampleMedication, quantite: 0),
            ],
            quartierOuCarrefour: 'Bastos',
          ),
        );

        expect(result.isLeft(), isTrue);
        verifyZeroInteractions(mockRepo);
      });

      test('Whitespace-only clientRequestId is rejected', () async {
        final result = await submitUseCase(
          const SubmitFlashRequestParams(
            clientRequestId: '   ',
            items: [BasketItem(medication: sampleMedication, quantite: 1)],
            quartierOuCarrefour: 'Bastos',
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, FlashRequest>(
              ValidationFailure('Paramètres de demande invalides.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      test('Whitespace-only quartierOuCarrefour is rejected', () async {
        final result = await submitUseCase(
          const SubmitFlashRequestParams(
            clientRequestId: 'req-001',
            items: [BasketItem(medication: sampleMedication, quantite: 1)],
            quartierOuCarrefour: '   ',
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, FlashRequest>(
              ValidationFailure('Paramètres de demande invalides.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });
    });

    // -------------------------------------------------------------------------
    // 4. Counter Quote Pricing Invariants in SubmitCounterQuoteUseCase
    // -------------------------------------------------------------------------
    group('Attack Matrix 4: Non-Positive Prices & Counter Quote Invariants', () {
      late MockPharmacistPortalRepo mockRepo;
      late SubmitCounterQuoteUseCase quoteUseCase;

      setUp(() {
        mockRepo = MockPharmacistPortalRepo();
        quoteUseCase = SubmitCounterQuoteUseCase(mockRepo);
      });

      test('Empty itemResponses list is rejected', () async {
        const submission = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: 'p-1',
          itemResponses: [],
          montantTotal: 1000,
          livraisonPossible: false,
        );

        final result = await quoteUseCase(submission);
        expect(
          result,
          equals(
            const Left<Failure, PharmacyOffer>(
              ReservationFailure('La réponse doit contenir au moins un article.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      test('Negative montantTotal (-0.01) is rejected', () async {
        const submission = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: 'p-1',
          itemResponses: [
            OfferItemResponse(
              medicationId: 'med-1',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: 500,
            ),
          ],
          montantTotal: -0.01,
          livraisonPossible: false,
        );

        final result = await quoteUseCase(submission);
        expect(
          result,
          equals(
            const Left<Failure, PharmacyOffer>(
              ReservationFailure('Le montant total ne peut pas être négatif.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      test('Negative unit price (-100) for available item is rejected', () async {
        const submission = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: 'p-1',
          itemResponses: [
            OfferItemResponse(
              medicationId: 'med-1',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: -100,
            ),
          ],
          montantTotal: 500,
          livraisonPossible: false,
        );

        final result = await quoteUseCase(submission);
        expect(
          result,
          equals(
            const Left<Failure, PharmacyOffer>(
              ReservationFailure('Le prix unitaire ne peut pas être négatif.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      test('Negative unit price (-50) for conditional item is rejected', () async {
        const submission = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: 'p-1',
          itemResponses: [
            OfferItemResponse(
              medicationId: 'med-1',
              status: ItemAvailabilityStatus.conditional,
              prixUnitaireCommunicParPharmacien: -50,
            ),
          ],
          montantTotal: 500,
          livraisonPossible: false,
        );

        final result = await quoteUseCase(submission);
        expect(
          result,
          equals(
            const Left<Failure, PharmacyOffer>(
              ReservationFailure('Le prix unitaire ne peut pas être négatif.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      test('Zero FCFA unit price is accepted for unavailable items', () async {
        const submission = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: 'p-1',
          itemResponses: [
            OfferItemResponse(
              medicationId: 'med-1',
              status: ItemAvailabilityStatus.unavailable,
              prixUnitaireCommunicParPharmacien: 0,
            ),
          ],
          montantTotal: 0,
          livraisonPossible: false,
        );

        final dummyOffer = PharmacyOffer(
          id: 'off-1',
          demandeId: 'd-1',
          pharmacyId: 'p-1',
          pharmacyNom: 'Pharmacie Bastos',
          quartier: 'Bastos',
          items: submission.itemResponses,
          montantTotalPropose: 0,
          livraisonDisponible: false,
          createdAt: DateTime.now(),
        );

        when(() => mockRepo.submitCounterQuote(submission))
            .thenAnswer((_) async => Right(dummyOffer));

        final result = await quoteUseCase(submission);
        expect(result.isRight(), isTrue);
      });

      test('Whitespace demandId or pharmacyId is rejected', () async {
        const subNoDemand = CounterQuoteSubmission(
          demandId: '   ',
          pharmacyId: 'p-1',
          itemResponses: [
            OfferItemResponse(
              medicationId: 'm-1',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: 500,
            ),
          ],
          montantTotal: 500,
          livraisonPossible: false,
        );
        expect(
          await quoteUseCase(subNoDemand),
          equals(
            const Left<Failure, PharmacyOffer>(
              ValidationFailure('Paramètres de soumission invalides.'),
            ),
          ),
        );

        const subNoPharma = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: '   ',
          itemResponses: [
            OfferItemResponse(
              medicationId: 'm-1',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: 500,
            ),
          ],
          montantTotal: 500,
          livraisonPossible: false,
        );
        expect(
          await quoteUseCase(subNoPharma),
          equals(
            const Left<Failure, PharmacyOffer>(
              ValidationFailure('Paramètres de soumission invalides.'),
            ),
          ),
        );
      });
    });

    // -------------------------------------------------------------------------
    // 5. Round-Robin Waves (ONPC batches of 2) in EscalateDispatchWaveUseCase
    // -------------------------------------------------------------------------
    group('Attack Matrix 5: Round-Robin Waves & Batches of 2 Pharmacies', () {
      late MockReservationRepo mockRepo;
      late EscalateDispatchWaveUseCase waveUseCase;

      setUp(() {
        mockRepo = MockReservationRepo();
        waveUseCase = EscalateDispatchWaveUseCase(mockRepo);
      });

      test(
        'Strict batch of 2: selects exactly first 2 unnotified pharmacies from list of 6',
        () async {
          final dummyRequest = FlashRequest(
            id: 'flash-001',
            clientRequestId: 'client-1',
            items: const [],
            quartierOuCarrefour: 'Bastos',
            statut: FlashRequestStatus.active,
            vagueActuelle: 2,
            pharmaciesNotifieesIds: const ['p1', 'p2', 'p3', 'p4'],
            offresRecues: const [],
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          );

          when(
            () => mockRepo.escalateDispatchWave(
              demandeId: 'flash-001',
              nextWaveNumber: 2,
              eligiblePharmacyIds: ['p3', 'p4'],
            ),
          ).thenAnswer((_) async => Right(dummyRequest));

          final result = await waveUseCase(
            const EscalateDispatchWaveParams(
              demandeId: 'flash-001',
              currentWave: 1,
              candidatePharmacyIds: ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
              alreadyNotifiedPharmacyIds: ['p1', 'p2'],
            ),
          );

          expect(result.isRight(), isTrue);
          verify(
            () => mockRepo.escalateDispatchWave(
              demandeId: 'flash-001',
              nextWaveNumber: 2,
              eligiblePharmacyIds: ['p3', 'p4'],
            ),
          ).called(1);
        },
      );

      test(
        'Wave increment: wave 4 becomes wave 5 with single remaining pharmacy',
        () async {
          final dummyRequest = FlashRequest(
            id: 'flash-001',
            clientRequestId: 'client-1',
            items: const [],
            quartierOuCarrefour: 'Bastos',
            statut: FlashRequestStatus.active,
            vagueActuelle: 5,
            pharmaciesNotifieesIds: const ['p1', 'p2', 'p3'],
            offresRecues: const [],
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(minutes: 15)),
          );

          when(
            () => mockRepo.escalateDispatchWave(
              demandeId: 'flash-001',
              nextWaveNumber: 5,
              eligiblePharmacyIds: ['p3'],
            ),
          ).thenAnswer((_) async => Right(dummyRequest));

          final result = await waveUseCase(
            const EscalateDispatchWaveParams(
              demandeId: 'flash-001',
              currentWave: 4,
              candidatePharmacyIds: ['p1', 'p2', 'p3'],
              alreadyNotifiedPharmacyIds: ['p1', 'p2'],
            ),
          );

          expect(result.isRight(), isTrue);
          verify(
            () => mockRepo.escalateDispatchWave(
              demandeId: 'flash-001',
              nextWaveNumber: 5,
              eligiblePharmacyIds: ['p3'],
            ),
          ).called(1);
        },
      );

      test('Exhausted pool returns ReservationFailure', () async {
        final result = await waveUseCase(
          const EscalateDispatchWaveParams(
            demandeId: 'flash-001',
            currentWave: 2,
            candidatePharmacyIds: ['p1', 'p2'],
            alreadyNotifiedPharmacyIds: ['p1', 'p2'],
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, FlashRequest>(
              ReservationFailure(
                'Aucune officine partenaire supplémentaire disponible pour escalade.',
              ),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      test('Empty candidate list returns ReservationFailure', () async {
        final result = await waveUseCase(
          const EscalateDispatchWaveParams(
            demandeId: 'flash-001',
            currentWave: 1,
            candidatePharmacyIds: [],
            alreadyNotifiedPharmacyIds: [],
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, FlashRequest>(
              ReservationFailure(
                'Aucune officine partenaire supplémentaire disponible pour escalade.',
              ),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });

      test('Whitespace demandeId returns ValidationFailure', () async {
        final result = await waveUseCase(
          const EscalateDispatchWaveParams(
            demandeId: '   ',
            currentWave: 1,
            candidatePharmacyIds: ['p1', 'p2'],
            alreadyNotifiedPharmacyIds: [],
          ),
        );

        expect(
          result,
          equals(
            const Left<Failure, FlashRequest>(
              ValidationFailure('Identifiant de demande manquant.'),
            ),
          ),
        );
        verifyZeroInteractions(mockRepo);
      });
    });

    // -------------------------------------------------------------------------
    // 6. Cameroon Phone Numbers in SelectPharmacyOfferUseCase
    // -------------------------------------------------------------------------
    group('Attack Matrix 6: Cameroon Phone Number Validation', () {
      late MockReservationRepo mockRepo;
      late SelectPharmacyOfferUseCase selectUseCase;

      setUp(() {
        mockRepo = MockReservationRepo();
        selectUseCase = SelectPharmacyOfferUseCase(mockRepo);
      });

      final validCameroonPhones = [
        '+237699112233',
        '+237677889900',
        '+237655443322',
        '+237222112233',
        '237699112233',
        '699112233',
        '677889900',
        '222112233',
      ];

      for (final phone in validCameroonPhones) {
        test('Valid Cameroon phone "$phone" is accepted', () async {
          final dummyRes = Reservation(
            id: 'res-1',
            clientReservationId: 'c-1',
            demandeId: 'd-1',
            offreId: 'o-1',
            pharmacyId: 'p-1',
            codeRetraitOtp6Chiffres: '123456',
            statut: ReservationStatus.pending,
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(hours: 2)),
          );
          when(
            () => mockRepo.selectPharmacyOffer(
              clientReservationId: 'c-1',
              demandeId: 'd-1',
              offreId: 'o-1',
              patientPhone: phone.trim(),
            ),
          ).thenAnswer((_) async => Right(dummyRes));

          final result = await selectUseCase(
            SelectPharmacyOfferParams(
              clientReservationId: 'c-1',
              demandeId: 'd-1',
              offreId: 'o-1',
              patientPhone: phone,
            ),
          );

          expect(result.isRight(), isTrue);
        });
      }

      final invalidPhones = [
        '',
        '   ',
        '12345678', // 8 digits
        '69911223', // 8 digits mobile
        '+33612345678', // France
        '+14155552671', // USA
        '+23712345678', // Starts with 1 (not 2 or 6)
        '+237599112233', // Starts with 5 (not 2 or 6)
        '+2376991122334', // 10 digits
        'phone-number',
      ];

      for (final badPhone in invalidPhones) {
        test('Invalid phone "$badPhone" is rejected', () async {
          final result = await selectUseCase(
            SelectPharmacyOfferParams(
              clientReservationId: 'c-1',
              demandeId: 'd-1',
              offreId: 'o-1',
              patientPhone: badPhone,
            ),
          );

          expect(result.isLeft(), isTrue);
          verifyZeroInteractions(mockRepo);
        });
      }
    });

    // -------------------------------------------------------------------------
    // 7. Duty Pharmacy & Pharmacist Portal UseCases Edge Cases
    // -------------------------------------------------------------------------
    group('Attack Matrix 7: Duty Pharmacy & Portal Analytics Edge Cases', () {
      late MockDutyPharmacyRepo mockDutyRepo;
      late GetDutyPharmaciesByQuartierUseCase dutyUseCase;
      late MockPharmacistPortalRepo mockPortalRepo;
      late GetPharmacyAnalyticsUseCase analyticsUseCase;

      setUp(() {
        mockDutyRepo = MockDutyPharmacyRepo();
        dutyUseCase = GetDutyPharmaciesByQuartierUseCase(mockDutyRepo);
        mockPortalRepo = MockPharmacistPortalRepo();
        analyticsUseCase = GetPharmacyAnalyticsUseCase(mockPortalRepo);
      });

      test('Whitespace or empty quartier is rejected with LocationFailure', () async {
        for (final badQ in ['', '   ', '\t\n']) {
          final result = await dutyUseCase(
            GetDutyPharmaciesByQuartierParams(quartier: badQ),
          );
          expect(
            result,
            equals(
              const Left<Failure, List<DutySchedule>>(
                LocationFailure('Le quartier doit être spécifié.'),
              ),
            ),
          );
          verifyZeroInteractions(mockDutyRepo);
        }
      });

      test('Whitespace or empty pharmacyId is rejected with AuthFailure', () async {
        for (final badId in ['', '   ', '\t\n']) {
          final result = await analyticsUseCase(
            GetPharmacyAnalyticsParams(pharmacyId: badId, date: DateTime.now()),
          );
          expect(
            result,
            equals(
              const Left<Failure, PharmacyDailyAnalytics>(
                AuthFailure('Identifiant pharmacie manquant.'),
              ),
            ),
          );
          verifyZeroInteractions(mockPortalRepo);
        }
      });

      test('Zero-PII invariant: PharmacyDailyAnalytics contains NO patient data', () {
        final analytics = PharmacyDailyAnalytics(
          pharmacyId: 'pharma-1',
          date: DateTime(2026, 11, 9),
          totalDemandsReceived: 42,
          totalQuotesSubmitted: 38,
          totalReservationsConfirmed: 30,
          conversionRate: 0.789,
          id: 'stat-uuid-1',
          tempsMoyenReponseSecondes: 85,
        );

        expect(analytics.props.length, equals(8));
        for (final prop in analytics.props) {
          expect(prop is! PatientSession, isTrue);
        }
      });
    });

    // -------------------------------------------------------------------------
    // 8. Exhaustive Entity Value Equality, Immutability & copyWith Stress
    // -------------------------------------------------------------------------
    group('Attack Matrix 8: Exhaustive Entity Equality & copyWith Stress', () {
      test('BasketItem equality, props and copyWith', () {
        const item1 = BasketItem(
          medication: sampleMedication,
          quantite: 2,
          precision: 'Note',
        );
        const item2 = BasketItem(
          medication: sampleMedication,
          quantite: 2,
          precision: 'Note',
        );
        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
        expect(item1.props.length, equals(3));

        final copied = item1.copyWith();
        expect(copied, equals(item1));

        expect(item1.copyWith(quantite: 5), isNot(equals(item1)));
        expect(item1.copyWith(precision: 'Autre'), isNot(equals(item1)));
      });

      test('OfferItemResponse equality, props and copyWith', () {
        const res1 = OfferItemResponse(
          medicationId: 'm-1',
          status: ItemAvailabilityStatus.available,
          prixUnitaireCommunicParPharmacien: 1200,
          conditionDelivrance: 'Ordonnance',
          commentaire: 'Note',
        );
        const res2 = OfferItemResponse(
          medicationId: 'm-1',
          status: ItemAvailabilityStatus.available,
          prixUnitaireCommunicParPharmacien: 1200,
          conditionDelivrance: 'Ordonnance',
          commentaire: 'Note',
        );
        expect(res1, equals(res2));
        expect(res1.props.length, equals(5));

        final copied = res1.copyWith();
        expect(copied, equals(res1));

        expect(res1.copyWith(medicationId: 'm-2'), isNot(equals(res1)));
        expect(
          res1.copyWith(status: ItemAvailabilityStatus.unavailable),
          isNot(equals(res1)),
        );
        expect(
          res1.copyWith(prixUnitaireCommunicParPharmacien: 1500),
          isNot(equals(res1)),
        );
        expect(
          res1.copyWith(conditionDelivrance: 'Autre'),
          isNot(equals(res1)),
        );
        expect(res1.copyWith(commentaire: 'Autre com'), isNot(equals(res1)));
      });

      test('DutySchedule equality, props and copyWith', () {
        final t = DateTime(2026, 11, 9);
        final ds1 = DutySchedule(
          id: 'ds-1',
          pharmacy: samplePharmacy,
          dateGarde: t,
          heureDebut: '20:00',
          heureFin: '08:00',
          verifieParOnpc: true,
          groupeGarde: 'Centre',
        );
        final ds2 = DutySchedule(
          id: 'ds-1',
          pharmacy: samplePharmacy,
          dateGarde: t,
          heureDebut: '20:00',
          heureFin: '08:00',
          verifieParOnpc: true,
          groupeGarde: 'Centre',
        );
        expect(ds1, equals(ds2));
        expect(ds1.props.length, equals(7));

        final copied = ds1.copyWith();
        expect(copied, equals(ds1));

        expect(ds1.copyWith(id: 'ds-2'), isNot(equals(ds1)));
        expect(ds1.copyWith(heureDebut: '19:00'), isNot(equals(ds1)));
        expect(ds1.copyWith(verifieParOnpc: false), isNot(equals(ds1)));
        expect(ds1.copyWith(groupeGarde: 'Nord'), isNot(equals(ds1)));
      });

      test('IncomingDemand equality, props and copyWith', () {
        final t = DateTime(2026, 11, 9, 20, 0);
        final flash = FlashRequest(
          id: 'f-1',
          clientRequestId: 'c-1',
          items: const [],
          quartierOuCarrefour: 'Bastos',
          statut: FlashRequestStatus.pending,
          vagueActuelle: 1,
          pharmaciesNotifieesIds: const [],
          offresRecues: const [],
          createdAt: t,
          expiresAt: t.add(const Duration(minutes: 15)),
        );
        final demand1 = IncomingDemand(
          id: 'd-1',
          flashRequest: flash,
          receivedAt: t,
          isResponded: false,
          distanceMetres: 200,
        );
        final demand2 = IncomingDemand(
          id: 'd-1',
          flashRequest: flash,
          receivedAt: t,
          isResponded: false,
          distanceMetres: 200,
        );
        expect(demand1, equals(demand2));
        expect(demand1.props.length, equals(5));

        final copied = demand1.copyWith();
        expect(copied, equals(demand1));

        expect(demand1.demandeId, equals('f-1'));
        expect(demand1.quartierPatient, equals('Bastos'));
        expect(demand1.copyWith(id: 'd-2'), isNot(equals(demand1)));
        expect(demand1.copyWith(isResponded: true), isNot(equals(demand1)));
      });

      test('CounterQuoteSubmission equality, props and copyWith', () {
        const sub1 = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: 'p-1',
          itemResponses: [],
          montantTotal: 1500,
          livraisonPossible: true,
          fraisLivraison: 500,
          delaiMinutes: 30,
          notes: 'Note',
        );
        const sub2 = CounterQuoteSubmission(
          demandId: 'd-1',
          pharmacyId: 'p-1',
          itemResponses: [],
          montantTotal: 1500,
          livraisonPossible: true,
          fraisLivraison: 500,
          delaiMinutes: 30,
          notes: 'Note',
        );
        expect(sub1, equals(sub2));
        expect(sub1.props.length, equals(8));

        final copied = sub1.copyWith();
        expect(copied, equals(sub1));

        expect(sub1.itemsResponse, equals(sub1.itemResponses));
        expect(sub1.delaiEstimeMinutes, equals(30));
        expect(sub1.commentairePharmacien, equals('Note'));
        expect(sub1.copyWith(demandId: 'd-2'), isNot(equals(sub1)));
        expect(sub1.copyWith(montantTotal: 2000), isNot(equals(sub1)));
      });
    });
  });
}
