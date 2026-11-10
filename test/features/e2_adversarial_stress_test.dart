import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/duty_pharmacy/data/models/duty_schedule_model.dart';
import 'package:medmate/features/pharmacist_portal/data/datasources/pharmacist_portal_data_source.dart';
import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_pickup_otp_usecase.dart';
import 'package:medmate/features/pharmacy_search/data/datasources/yaounde_pharmacy_data_source.dart';
import 'package:medmate/features/pharmacy_search/data/models/medication_model.dart';
import 'package:medmate/features/pharmacy_search/data/models/pharmacy_model.dart';
import 'package:medmate/features/pharmacy_search/data/repositories/pharmacy_search_repository_impl.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/datasources/flash_order_data_source.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/usecases/confirm_reservation_otp_usecase.dart';

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

  const sampleBasketItem = BasketItemModel(
    medication: sampleMedication,
    quantite: 2,
    precision: 'Urgence céphalée',
  );

  group('EMPIRICAL CHALLENGER: Étape 2 Adversarial Stress Suite', () {
    // =========================================================================
    // 1. Concurrency & Race Conditions on InMemoryFlashOrderStore
    // =========================================================================
    group('Area 1: Concurrency on InMemoryFlashOrderStore', () {
      late InMemoryFlashOrderStore store;

      setUp(() {
        store = InMemoryFlashOrderStore()..reset();
      });

      test(
        '50 simultaneous demands across different Yaoundé quartiers create consistent isolated states',
        () async {
          final quartiers = [
            'Bastos',
            'Mokolo',
            'Tsinga',
            'Obili',
            'Essos',
            'Biyem-Assi',
            'Mendong',
            'Nlongkak',
          ];

          final futures = List.generate(50, (index) {
            final quartier = quartiers[index % quartiers.length];
            final now = DateTime.now();
            final req = FlashRequestModel(
              id: 'concurrent-req-$index',
              clientRequestId: 'client-req-uuid-$index',
              items: const [sampleBasketItem],
              quartierOuCarrefour: quartier,
              statut: FlashRequestStatus.pending,
              vagueActuelle: 1,
              pharmaciesNotifieesIds: const [],
              offresRecues: const [],
              createdAt: now,
              expiresAt: now.add(const Duration(minutes: 30)),
            );
            return store.submitFlashRequest(req);
          });

          final results = await Future.wait(futures);

          expect(results.length, equals(50));
          for (var i = 0; i < results.length; i++) {
            expect(results[i].id, equals('concurrent-req-$i'));
            expect(results[i].statut, equals(FlashRequestStatus.active));
            expect(results[i].pharmaciesNotifieesIds.length, equals(2));

            // Verify store persistence
            final fetched = await store.getFlashRequestById('concurrent-req-$i');
            expect(fetched.id, equals('concurrent-req-$i'));
            expect(fetched.statut, equals(FlashRequestStatus.active));
          }
        },
      );

      test(
        'Simultaneous offers submitted by 4 pharmacies for the same demand maintain data integrity',
        () async {
          final now = DateTime.now();
          final req = FlashRequestModel(
            id: 'multi-offer-demand-1',
            clientRequestId: 'client-multi-1',
            items: const [sampleBasketItem],
            quartierOuCarrefour: 'Bastos',
            statut: FlashRequestStatus.pending,
            vagueActuelle: 1,
            pharmaciesNotifieesIds: const [],
            offresRecues: const [],
            createdAt: now,
            expiresAt: now.add(const Duration(minutes: 30)),
          );
          await store.submitFlashRequest(req);

          final pharmacyIds = [
            'pharma-bastos-01',
            'pharma-nlongkak-01',
            'pharma-mokolo-01',
            'pharma-tsinga-01',
          ];

          final offerFutures = pharmacyIds.map((pId) {
            final submission = CounterQuoteSubmissionModel(
              demandId: 'multi-offer-demand-1',
              pharmacyId: pId,
              itemResponses: const [
                OfferItemResponseModel(
                  medicationId: 'med-para-500',
                  status: ItemAvailabilityStatus.available,
                  prixUnitaireCommunicParPharmacien: 1200,
                ),
              ],
              montantTotal: 2400,
              livraisonPossible: true,
              fraisLivraison: 500,
              delaiMinutes: 25,
            );
            return store.submitCounterQuote(submission);
          }).toList();

          final createdOffers = await Future.wait(offerFutures);
          expect(createdOffers.length, equals(4));

          final updatedReq = await store.getFlashRequestById('multi-offer-demand-1');
          expect(updatedReq.offresRecues.length, equals(4));
          expect(updatedReq.statut, equals(FlashRequestStatus.partiallyAnswered));

          final recordedPharmaIds = updatedReq.offresRecues.map((o) => o.pharmacyId).toSet();
          expect(recordedPharmaIds, equals(pharmacyIds.toSet()));
        },
      );

      test(
        'Simultaneous wave escalations on the same demand prevent duplicate pharmacy notifications',
        () async {
          final now = DateTime.now();
          final req = FlashRequestModel(
            id: 'wave-race-req-1',
            clientRequestId: 'client-wave-1',
            items: const [sampleBasketItem],
            quartierOuCarrefour: 'Bastos',
            statut: FlashRequestStatus.pending,
            vagueActuelle: 1,
            pharmaciesNotifieesIds: const [],
            offresRecues: const [],
            createdAt: now,
            expiresAt: now.add(const Duration(minutes: 30)),
          );
          await store.submitFlashRequest(req);

          // Escalate with overlapping pharmacy lists concurrently
          final escalationFutures = [
            store.escalateDispatchWave(
              demandeId: 'wave-race-req-1',
              nextWaveNumber: 2,
              eligiblePharmacyIds: ['pharma-mokolo-01', 'pharma-tsinga-01'],
            ),
            store.escalateDispatchWave(
              demandeId: 'wave-race-req-1',
              nextWaveNumber: 2,
              eligiblePharmacyIds: ['pharma-tsinga-01', 'pharma-obili-01'],
            ),
          ];

          await Future.wait(escalationFutures);

          final finalReq = await store.getFlashRequestById('wave-race-req-1');
          final setOfNotified = finalReq.pharmaciesNotifieesIds.toSet();
          expect(
            finalReq.pharmaciesNotifieesIds.length,
            equals(setOfNotified.length),
            reason: 'pharmaciesNotifieesIds should never contain duplicates',
          );
        },
      );

      test(
        'Full high-volume concurrent pipeline (30 flows: submit -> quote -> select -> confirm)',
        () async {
          final flowFutures = List.generate(30, (i) async {
            final now = DateTime.now();
            final req = FlashRequestModel(
              id: 'pipeline-req-$i',
              clientRequestId: 'client-pipe-$i',
              items: const [sampleBasketItem],
              quartierOuCarrefour: 'Bastos',
              statut: FlashRequestStatus.pending,
              vagueActuelle: 1,
              pharmaciesNotifieesIds: const [],
              offresRecues: const [],
              createdAt: now,
              expiresAt: now.add(const Duration(minutes: 30)),
            );
            await store.submitFlashRequest(req);

            final quote = CounterQuoteSubmissionModel(
              demandId: 'pipeline-req-$i',
              pharmacyId: 'pharma-bastos-01',
              itemResponses: const [
                OfferItemResponseModel(
                  medicationId: 'med-para-500',
                  status: ItemAvailabilityStatus.available,
                  prixUnitaireCommunicParPharmacien: 1500,
                ),
              ],
              montantTotal: 3000,
              livraisonPossible: false,
            );
            final offer = await store.submitCounterQuote(quote);

            final reservation = await store.selectPharmacyOffer(
              clientReservationId: 'res-pipe-$i',
              demandeId: 'pipeline-req-$i',
              offreId: offer.id,
              patientPhone: '+237699001122',
            );

            final confirmed = await store.validatePickupOtp(
              pharmacyId: 'pharma-bastos-01',
              reservationId: reservation.id,
              otpCode: reservation.codeRetraitOtp6Chiffres,
            );

            return confirmed;
          });

          final confirmedReservations = await Future.wait(flowFutures);
          expect(confirmedReservations.length, equals(30));

          for (final res in confirmedReservations) {
            expect(res.statut, equals(ReservationStatus.confirmedAtCounter));
          }

          final analytics = await store.getPharmacyAnalytics(
            pharmacyId: 'pharma-bastos-01',
            date: DateTime.now(),
          );
          expect(analytics.totalDemandsReceived, greaterThanOrEqualTo(30));
          expect(analytics.totalQuotesSubmitted, greaterThanOrEqualTo(30));
          expect(analytics.totalReservationsConfirmed, equals(30));
          expect(analytics.conversionRate, equals(1.0));
        },
      );

      test('Non-existent demand throws NotFoundException on escalate, quote, and get', () async {
        expect(
          () => store.getFlashRequestById('ghost-demand-id'),
          throwsA(isA<NotFoundException>()),
        );

        expect(
          () => store.escalateDispatchWave(
            demandeId: 'ghost-demand-id',
            nextWaveNumber: 2,
            eligiblePharmacyIds: ['pharma-bastos-01'],
          ),
          throwsA(isA<NotFoundException>()),
        );

        const ghostQuote = CounterQuoteSubmissionModel(
          demandId: 'ghost-demand-id',
          pharmacyId: 'pharma-bastos-01',
          itemResponses: [],
          montantTotal: 1000,
          livraisonPossible: false,
        );
        expect(
          () => store.submitCounterQuote(ghostQuote),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('Expired FlashRequest (> 30 min) strictly blocks selectPharmacyOffer', () async {
        final expiredReq = FlashRequestModel(
          id: 'expired-flash-demand',
          clientRequestId: 'client-exp-1',
          items: const [sampleBasketItem],
          quartierOuCarrefour: 'Bastos',
          statut: FlashRequestStatus.pending,
          vagueActuelle: 1,
          pharmaciesNotifieesIds: const [],
          offresRecues: const [],
          createdAt: DateTime.now().subtract(const Duration(minutes: 35)),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        await store.submitFlashRequest(expiredReq);

        const quote = CounterQuoteSubmissionModel(
          demandId: 'expired-flash-demand',
          pharmacyId: 'pharma-bastos-01',
          itemResponses: [],
          montantTotal: 2000,
          livraisonPossible: false,
        );
        final offer = await store.submitCounterQuote(quote);

        expect(
          () => store.selectPharmacyOffer(
            clientReservationId: 'client-res-exp',
            demandeId: 'expired-flash-demand',
            offreId: offer.id,
            patientPhone: '+237699001122',
          ),
          throwsA(isA<ReservationException>()),
        );
      });

      test('Idempotency analysis on repeated submitFlashRequest with same clientRequestId', () async {
        final now = DateTime.now();
        final req1 = FlashRequestModel(
          id: 'req-idemp-1',
          clientRequestId: 'idempotency-key-shared',
          items: const [sampleBasketItem],
          quartierOuCarrefour: 'Bastos',
          statut: FlashRequestStatus.pending,
          vagueActuelle: 1,
          pharmaciesNotifieesIds: const [],
          offresRecues: const [],
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 30)),
        );
        final req2 = FlashRequestModel(
          id: 'req-idemp-2',
          clientRequestId: 'idempotency-key-shared',
          items: const [sampleBasketItem],
          quartierOuCarrefour: 'Bastos',
          statut: FlashRequestStatus.pending,
          vagueActuelle: 1,
          pharmaciesNotifieesIds: const [],
          offresRecues: const [],
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 30)),
        );

        final res1 = await store.submitFlashRequest(req1);
        final res2 = await store.submitFlashRequest(req2);

        // Documenting behavior: InMemoryFlashOrderStore keys on id (not clientRequestId)
        expect(res1.id, equals('req-idemp-1'));
        expect(res2.id, equals('req-idemp-2'));
      });
    });

    // =========================================================================
    // 2. OTP Robustness, Tampering, TTL, and Replay Vulnerability
    // =========================================================================
    group('Area 2: OTP Validation & Replay Attack Stress Testing', () {
      late InMemoryFlashOrderStore store;
      late PharmacistPortalDataSource portalDataSource;
      late PharmacistPortalRepositoryImpl portalRepo;
      late ValidatePickupOtpUseCase validateOtpUseCase;

      late FlashOrderDataSource flashDataSource;
      late ReservationRepositoryImpl reservationRepo;
      late ConfirmReservationOtpUseCase confirmOtpUseCase;

      setUp(() {
        store = InMemoryFlashOrderStore()..reset();
        portalDataSource = PharmacistPortalDataSourceImpl(store: store);
        portalRepo = PharmacistPortalRepositoryImpl(dataSource: portalDataSource);
        validateOtpUseCase = ValidatePickupOtpUseCase(portalRepo);

        flashDataSource = FlashOrderDataSourceImpl(store: store);
        reservationRepo = ReservationRepositoryImpl(dataSource: flashDataSource);
        confirmOtpUseCase = ConfirmReservationOtpUseCase(reservationRepo);
      });

      Future<ReservationModel> createActiveReservation({
        String reqId = 'otp-test-req-1',
        String pharmaId = 'pharma-bastos-01',
      }) async {
        final now = DateTime.now();
        final req = FlashRequestModel(
          id: reqId,
          clientRequestId: 'client-$reqId',
          items: const [sampleBasketItem],
          quartierOuCarrefour: 'Bastos',
          statut: FlashRequestStatus.pending,
          vagueActuelle: 1,
          pharmaciesNotifieesIds: const [],
          offresRecues: const [],
          createdAt: now,
          expiresAt: now.add(const Duration(minutes: 30)),
        );
        await store.submitFlashRequest(req);

        final quote = CounterQuoteSubmissionModel(
          demandId: reqId,
          pharmacyId: pharmaId,
          itemResponses: const [
            OfferItemResponseModel(
              medicationId: 'med-para-500',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: 1500,
            ),
          ],
          montantTotal: 3000,
          livraisonPossible: false,
        );
        final offer = await store.submitCounterQuote(quote);

        final reservation = await store.selectPharmacyOffer(
          clientReservationId: 'client-res-$reqId',
          demandeId: reqId,
          offreId: offer.id,
          patientPhone: '+237699001122',
        );

        return reservation;
      }

      test('Tampering: Rejects invalid OTP formats (letters, lengths != 6, special chars)', () async {
        final reservation = await createActiveReservation(reqId: 'tamper-req-1');

        final maliciousOtps = [
          '12345', // 5 digits
          '1234567', // 7 digits
          '12345a', // alpha suffix
          'abcdef', // all alpha
          '12 345', // internal space
          '12-345', // hyphenated
          '123.45', // dot
          '00000', // 5 zeros
          '12345\n', // newline
          '12345\x00', // null byte
          '<script>123456</script>',
          '123456 OR 1=1',
          '', // empty
          '   ', // whitespace
        ];

        for (final maliciousOtp in maliciousOtps) {
          final result = await validateOtpUseCase(
            ValidatePickupOtpParams(
              pharmacyId: 'pharma-bastos-01',
              reservationId: reservation.id,
              otpCode: maliciousOtp,
            ),
          );

          expect(
            result.isLeft(),
            isTrue,
            reason: 'Malicious OTP "$maliciousOtp" must be rejected',
          );
        }
      });

      test('Security: Cross-pharmacy redemption attempt is rejected with AuthFailure', () async {
        final reservation = await createActiveReservation(
          reqId: 'cross-pharma-1',
          pharmaId: 'pharma-bastos-01',
        );

        final result = await validateOtpUseCase(
          ValidatePickupOtpParams(
            pharmacyId: 'pharma-mokolo-01', // Attacker pharmacy
            reservationId: reservation.id,
            otpCode: reservation.codeRetraitOtp6Chiffres,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (_) => fail('Cross-pharmacy validation must not succeed'),
        );
      });

      test('TTL Expiration: Expired reservation (> 2 hours) is rejected by confirmReservationOtp', () async {
        final reservation = await createActiveReservation(reqId: 'expired-req-1');

        // Reservation created with expired timestamp
        final expiredReservation = reservation.copyWith(
          expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
        );

        final result = await confirmOtpUseCase(
          ConfirmReservationOtpParams(
            reservationId: expiredReservation.id,
            otpCode: expiredReservation.codeRetraitOtp6Chiffres,
            reservation: expiredReservation,
          ),
        );

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) {
            expect(failure, isA<ReservationFailure>());
            expect(failure.message, contains('expiré'));
          },
          (_) => fail('Expired reservation must not be confirmed'),
        );
      });

      test('Replay Attack & Idempotency Analysis on Pickup OTP', () async {
        final reservation = await createActiveReservation(reqId: 'replay-req-1');

        // First validation: legitimately succeeds
        final firstAttempt = await validateOtpUseCase(
          ValidatePickupOtpParams(
            pharmacyId: 'pharma-bastos-01',
            reservationId: reservation.id,
            otpCode: reservation.codeRetraitOtp6Chiffres,
          ),
        );

        expect(firstAttempt.isRight(), isTrue);
        final firstConfirmed = firstAttempt.getOrElse((_) => throw Exception());
        expect(firstConfirmed.statut, equals(ReservationStatus.confirmedAtCounter));

        final analyticsAfterFirst = await store.getPharmacyAnalytics(
          pharmacyId: 'pharma-bastos-01',
          date: DateTime.now(),
        );
        final confirmedCountAfterFirst = analyticsAfterFirst.totalReservationsConfirmed;

        // Second validation: Replay of identical OTP call
        final secondAttempt = await validateOtpUseCase(
          ValidatePickupOtpParams(
            pharmacyId: 'pharma-bastos-01',
            reservationId: reservation.id,
            otpCode: reservation.codeRetraitOtp6Chiffres,
          ),
        );

        // Verification of system response:
        expect(secondAttempt.isRight(), isTrue);

        final analyticsAfterSecond = await store.getPharmacyAnalytics(
          pharmacyId: 'pharma-bastos-01',
          date: DateTime.now(),
        );

        // Empirical check: In InMemoryFlashOrderStore, does second attempt increment analytics again?
        // Documenting this behavior:
        final hasReplayAnalyticsInflation =
            analyticsAfterSecond.totalReservationsConfirmed > confirmedCountAfterFirst;
        expect(
          hasReplayAnalyticsInflation,
          isTrue,
          reason: 'Empirically documents that InMemoryFlashOrderStore lacks a guard against replaying an already-confirmed OTP',
        );
      });
    });

    // =========================================================================
    // 3. Zero Price Invariant & Catalog Leakage Verification
    // =========================================================================
    group('Area 3: Zero Price Invariant & Catalog Leakage Verification', () {
      late YaoundePharmacyDataSource dataSource;
      late PharmacySearchRepositoryImpl repository;

      setUp(() {
        dataSource = const YaoundePharmacyDataSourceImpl();
        repository = PharmacySearchRepositoryImpl(dataSource: dataSource);
      });

      test('Patient catalog search returns zero price fields on all medications', () async {
        final results = await dataSource.searchMedications('para');
        expect(results.isNotEmpty, isTrue);

        for (final med in results) {
          final json = med.toJson();
          expect(json.containsKey('price'), isFalse);
          expect(json.containsKey('prix'), isFalse);
          expect(json.containsKey('tarif'), isFalse);
          expect(json.containsKey('cost'), isFalse);
          expect(json.containsKey('montant'), isFalse);
        }
      });

      test('Repository searchMedications returns zero price fields in entities', () async {
        final repoResult = await repository.searchMedications('para');
        expect(repoResult.isRight(), isTrue);

        repoResult.fold(
          (_) => fail('Repository search must succeed'),
          (meds) {
            expect(meds.isNotEmpty, isTrue);
            for (final med in meds) {
              final model = MedicationModel.fromDomain(med);
              final json = model.toJson();
              expect(json.containsKey('price'), isFalse);
              expect(json.containsKey('prix'), isFalse);
              expect(json.containsKey('tarif'), isFalse);
            }
          },
        );
      });

      test('Adversarial JSON price injection into MedicationModel is strictly ignored', () {
        final maliciousJson = {
          'id': 'med-inject-01',
          'code_national': 'CIP-9999',
          'nom_commercial': 'Paracétamol Hacked',
          'dci': 'Paracétamol',
          'forme': 'Comprimé',
          'dosage': '500 mg',
          'necessite_ordonnance': false,
          // Maliciously injected price fields
          'prix': 2500,
          'price': 2500,
          'tarif': 2500,
          'cost': 2500,
          'montant': 2500,
        };

        final model = MedicationModel.fromJson(maliciousJson);
        final serialized = model.toJson();

        expect(serialized.containsKey('prix'), isFalse);
        expect(serialized.containsKey('price'), isFalse);
        expect(serialized.containsKey('tarif'), isFalse);
        expect(serialized.containsKey('cost'), isFalse);
        expect(serialized.containsKey('montant'), isFalse);
      });

      test('PharmacyModel serialization and catalog return zero tariff/subscription fields', () async {
        final pharmacies = await dataSource.searchNearbyPharmacies(quartier: 'Bastos');
        expect(pharmacies.isNotEmpty, isTrue);

        for (final pharma in pharmacies) {
          final json = pharma.toJson();
          expect(json.containsKey('price'), isFalse);
          expect(json.containsKey('prix'), isFalse);
          expect(json.containsKey('tarif'), isFalse);
          expect(json.containsKey('abonnement'), isFalse);
          expect(json.containsKey('commission'), isFalse);
          expect(json.containsKey('frais'), isFalse);
        }
      });

      test('BasketItemModel strictly contains NO price or tariff information', () {
        const item = BasketItemModel(
          medication: sampleMedication,
          quantite: 3,
          precision: 'Sans prix',
        );

        final json = item.toJson();
        expect(json.containsKey('prix'), isFalse);
        expect(json.containsKey('price'), isFalse);
        expect(json.containsKey('montant'), isFalse);
        expect(json.containsKey('total'), isFalse);

        final deserialized = BasketItemModel.fromJson(json);
        expect(deserialized.medication.nomCommercial, equals(sampleMedication.nomCommercial));
        expect(deserialized.quantite, equals(3));
      });

      test('DutyScheduleModel serialization strictly contains zero price or tariff fields', () {
        const pharma = PharmacyModel(
          id: 'pharma-duty-test',
          nom: 'Pharmacie Test',
          licenceOnpc: 'ONPC-TEST',
          quartier: 'Bastos',
          carrefourRepere: 'Carrefour Warda',
          latitude: 3.8688,
          longitude: 11.5175,
          telephoneGarde: '+237222201122',
          estOuverte: true,
          estDeGarde: true,
          estPartenaire: true,
        );

        final schedule = DutyScheduleModel(
          id: 'duty-001',
          pharmacy: pharma,
          dateGarde: DateTime(2026, 11, 10),
          heureDebut: '20:00',
          heureFin: '08:00',
          verifieParOnpc: true,
          groupeGarde: 'Groupe A',
        );

        final json = schedule.toJson();
        expect(json.containsKey('price'), isFalse);
        expect(json.containsKey('prix'), isFalse);
        expect(json.containsKey('tarif'), isFalse);
        expect(json.containsKey('majoration_nuit'), isFalse);
        expect(json.containsKey('frais_garde'), isFalse);
      });
    });

    // =========================================================================
    // 4. Spatial Queries with Extreme / Boundary Inputs
    // =========================================================================
    group('Area 4: Spatial Query Robustness & Extreme Boundary Inputs', () {
      late YaoundePharmacyDataSource dataSource;

      setUp(() {
        dataSource = const YaoundePharmacyDataSourceImpl();
      });

      test('Extreme coordinates (North Pole, South Pole, Null Island, Tokyo) do not throw', () async {
        final extremeCoords = [
          (lat: 90, lon: 180, label: 'North Pole / Antimeridian'),
          (lat: -90, lon: -180, label: 'South Pole / Antimeridian'),
          (lat: 0, lon: 0, label: 'Null Island (Atlantic)'),
          (lat: 35.6762, lon: 139.6503, label: 'Tokyo (Far East)'),
          (lat: -33.8688, lon: 151.2093, label: 'Sydney (Southern Hemisphere)'),
        ];

        for (final coord in extremeCoords) {
          final result = await dataSource.searchNearbyPharmacies(
            latitude: coord.lat.toDouble(),
            longitude: coord.lon.toDouble(),
          );

          expect(result.isNotEmpty, isTrue, reason: 'Failed on ${coord.label}');
          // Sorted ascending by distance
          for (var i = 1; i < result.length; i++) {
            expect(
              result[i].distanceMetres! >= result[i - 1].distanceMetres!,
              isTrue,
            );
          }
          // Distances from Tokyo or Poles should be > 5,000 km
          if (coord.lat.abs() > 30 || coord.lon.abs() > 30) {
            expect(result.first.distanceMetres, greaterThan(5000000));
          }
        }
      });

      test('Boundary radiusMetres values (0, negative, very large, infinity) handle safely', () async {
        // Radius 0: falls back safely to withDistance
        final zeroRadius = await dataSource.searchNearbyPharmacies(
          latitude: 3.8688,
          longitude: 11.5175,
          radiusMetres: 0,
        );
        expect(zeroRadius.isNotEmpty, isTrue);

        // Very large radius (50,000 km) includes all pharmacies
        final allRadius = await dataSource.searchNearbyPharmacies(
          latitude: 3.8688,
          longitude: 11.5175,
          radiusMetres: 50000000,
        );
        expect(allRadius.length, equals(YaoundePharmacyDataSourceImpl.seededPharmacies.length));

        // Very tight radius (1 meter) in Bastos: should match 0 unless coordinates match to millimeter
        final tightRadius = await dataSource.searchNearbyPharmacies(
          latitude: 3.8688,
          longitude: 11.5175,
          radiusMetres: 1,
        );
        expect(tightRadius.length, lessThanOrEqualTo(1));
      });

      test('Adversarial text inputs (special regex chars, emojis, SQL/HTML injections, huge string)', () async {
        final adversarialQueries = [
          '***',
          '???',
          '[a-z]',
          '.*',
          r'^.*$',
          r'\',
          '💊 Paracétamol',
          '<script>alert(1)</script>',
          "' OR '1'='1",
          'a' * 10000, // 10,000 characters
        ];

        for (final q in adversarialQueries) {
          final medResults = await dataSource.searchMedications(q);
          expect(medResults, isA<List<MedicationModel>>());

          final pharmaResults = await dataSource.searchNearbyPharmacies(
            quartier: q,
            carrefourRepere: q,
          );
          expect(pharmaResults, isA<List<PharmacyModel>>());
        }
      });

      test('Haversine distance boundary conditions (antipodal, identical points, cross-equator)', () {
        // Identical points -> distance 0
        final zeroDist = YaoundePharmacyDataSourceImpl.calculateHaversineDistance(
          lat1: 3.8688,
          lon1: 11.5175,
          lat2: 3.8688,
          lon2: 11.5175,
        );
        expect(zeroDist, equals(0.0));

        // Antipodal points (0, 0) and (0, 180) -> half circumference of Earth (~20,015 km)
        final antipodalDist = YaoundePharmacyDataSourceImpl.calculateHaversineDistance(
          lat1: 0,
          lon1: 0,
          lat2: 0,
          lon2: 180,
        );
        expect((antipodalDist - 20015087).abs(), lessThan(50000)); // within 50km precision

        // North pole to South pole
        final poleDist = YaoundePharmacyDataSourceImpl.calculateHaversineDistance(
          lat1: 90,
          lon1: 0,
          lat2: -90,
          lon2: 0,
        );
        expect((poleDist - 20015087).abs(), lessThan(50000));
      });

      test('Yaoundé landmark carrefours and quartiers match with mixed case and accents', () async {
        final landmarks = [
          'Carrefour Warda',
          'Marché Mokolo',
          'Carrefour MEEC',
          'Carrefour Obili',
          'Carrefour Biyem-Assi',
          'Poste Centrale',
          'Carrefour Nsam',
          'Hôpital de la Caisse',
        ];

        for (final landmark in landmarks) {
          final results = await dataSource.searchNearbyPharmacies(
            carrefourRepere: landmark.toLowerCase(),
          );
          expect(
            results.isNotEmpty,
            isTrue,
            reason: 'Landmark "$landmark" should match at least one seeded pharmacy',
          );
        }
      });
    });
  });
}
