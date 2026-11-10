import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/data/datasources/pharmacist_portal_data_source.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/get_pharmacy_analytics_usecase.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote_usecase.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/validate_pickup_otp_usecase.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/datasources/flash_order_data_source.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/offer_item_response_model.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/usecases/confirm_reservation_otp_usecase.dart';
import 'package:medmate/features/reservation/domain/usecases/escalate_dispatch_wave_usecase.dart';
import 'package:medmate/features/reservation/domain/usecases/select_pharmacy_offer_usecase.dart';
import 'package:medmate/features/reservation/domain/usecases/submit_flash_request_usecase.dart';
import 'package:uuid/uuid.dart';

void main() {
  const uuid = Uuid();

  late InMemoryFlashOrderStore store;
  late FlashOrderDataSource flashDataSource;
  late PharmacistPortalDataSource portalDataSource;
  late ReservationRepositoryImpl reservationRepo;
  late PharmacistPortalRepositoryImpl portalRepo;

  // Patient UseCases
  late SubmitFlashRequestUseCase submitFlashUseCase;
  late EscalateDispatchWaveUseCase escalateWaveUseCase;
  late SelectPharmacyOfferUseCase selectOfferUseCase;
  late ConfirmReservationOtpUseCase confirmOtpUseCase;

  // Pharmacist UseCases
  late SubmitCounterQuoteUseCase submitQuoteUseCase;
  late ValidatePickupOtpUseCase validateOtpUseCase;
  late GetPharmacyAnalyticsUseCase getAnalyticsUseCase;

  const medPara = Medication(
    id: 'med-para-500',
    codeNational: 'CIP-3400936184729',
    nomCommercial: 'Paracétamol Biogaran',
    dci: 'Paracétamol',
    forme: 'Comprimé effervescent',
    dosage: '500 mg',
    necessiteOrdonnance: false,
  );

  const medAmox = Medication(
    id: 'med-amox-500',
    codeNational: 'CIP-3400936184730',
    nomCommercial: 'Amoxicilline Biogaran',
    dci: 'Amoxicilline',
    forme: 'Gélule',
    dosage: '500 mg',
    necessiteOrdonnance: true,
  );

  const medIbu = Medication(
    id: 'med-ibu-400',
    codeNational: 'CIP-3400936184731',
    nomCommercial: 'Ibuprofène Biogaran',
    dci: 'Ibuprofène',
    forme: 'Comprimé pelliculé',
    dosage: '400 mg',
    necessiteOrdonnance: false,
  );

  setUp(() {
    store = InMemoryFlashOrderStore()..reset();

    flashDataSource = FlashOrderDataSourceImpl(store: store);
    portalDataSource = PharmacistPortalDataSourceImpl(store: store);

    reservationRepo = ReservationRepositoryImpl(dataSource: flashDataSource);
    portalRepo = PharmacistPortalRepositoryImpl(dataSource: portalDataSource);

    submitFlashUseCase = SubmitFlashRequestUseCase(reservationRepo);
    escalateWaveUseCase = EscalateDispatchWaveUseCase(reservationRepo);
    selectOfferUseCase = SelectPharmacyOfferUseCase(reservationRepo);
    confirmOtpUseCase = ConfirmReservationOtpUseCase(reservationRepo);

    submitQuoteUseCase = SubmitCounterQuoteUseCase(portalRepo);
    validateOtpUseCase = ValidatePickupOtpUseCase(portalRepo);
    getAnalyticsUseCase = GetPharmacyAnalyticsUseCase(portalRepo);
  });

  group('Lifecycle Integration: Patient Flash Request -> Counter Quote -> OTP Pickup', () {
    test('comprehensive happy path: patient request to pharmacist pickup validation with real-time state synchronization', () async {
      // -------------------------------------------------------------
      // ÉTAPE 1: Le patient soumet une demande flash multi-produits
      // -------------------------------------------------------------
      final patientRequestId = uuid.v4();
      final submitResult = await submitFlashUseCase(
        SubmitFlashRequestParams(
          clientRequestId: patientRequestId,
          items: const [
            BasketItemModel(medication: medPara, quantite: 2),
            BasketItemModel(medication: medAmox, quantite: 1),
            BasketItemModel(medication: medIbu, quantite: 1),
          ],
          quartierOuCarrefour: 'Bastos - Carrefour Warda',
        ),
      );

      expect(submitResult.isRight(), isTrue);
      final flashRequest = submitResult.getOrElse((_) => throw Exception());
      expect(flashRequest.statut, equals(FlashRequestStatus.active));
      expect(flashRequest.vagueActuelle, equals(1));
      expect(flashRequest.pharmaciesNotifieesIds.length, equals(2));
      expect(flashRequest.pharmaciesNotifieesIds, contains('pharma-bastos-01'));

      // -------------------------------------------------------------
      // ÉTAPE 2: Le pharmacien de Pharmacie Bastos consulte ses demandes entrantes
      // -------------------------------------------------------------
      final demandsResult = await portalRepo.getIncomingDemands(
        pharmacyId: 'pharma-bastos-01',
      );
      expect(demandsResult.isRight(), isTrue);
      final demands = demandsResult.getOrElse((_) => []);
      expect(demands, isNotEmpty);

      final matchingDemand = demands.firstWhere((d) => d.demandeId == flashRequest.id);
      expect(matchingDemand.isResponded, isFalse);
      expect(matchingDemand.items.length, equals(3));
      expect(matchingDemand.quartierPatient, equals('Bastos - Carrefour Warda'));

      // -------------------------------------------------------------
      // ÉTAPE 3: Le pharmacien formule un devis au comptoir avec 3 statuts
      // -------------------------------------------------------------
      final quoteSubmission = CounterQuoteSubmission(
        demandId: flashRequest.id,
        pharmacyId: 'pharma-bastos-01',
        itemResponses: const [
          // Statut 1: Available avec prix comptoir
          OfferItemResponseModel(
            medicationId: 'med-para-500',
            status: ItemAvailabilityStatus.available,
            prixUnitaireCommunicParPharmacien: 1500,
          ),
          // Statut 2: Conditional avec condition de délivrance
          OfferItemResponseModel(
            medicationId: 'med-amox-500',
            status: ItemAvailabilityStatus.conditional,
            prixUnitaireCommunicParPharmacien: 3500,
            conditionDelivrance: "Présentation d'une ordonnance originale obligatoire",
          ),
          // Statut 3: Unavailable avec prix à 0.0 et commentaire de rupture
          OfferItemResponseModel(
            medicationId: 'med-ibu-400',
            status: ItemAvailabilityStatus.unavailable,
            prixUnitaireCommunicParPharmacien: 0,
            commentaire: 'Rupture de stock temporaire',
          ),
        ],
        montantTotal: 5000,
        livraisonPossible: true,
        fraisLivraison: 500,
        delaiMinutes: 25,
        notes: 'Disponible pour retrait rapide au comptoir',
      );

      final quoteResult = await submitQuoteUseCase(quoteSubmission);
      expect(quoteResult.isRight(), isTrue);
      final offer = quoteResult.getOrElse((_) => throw Exception());
      expect(offer.montantTotalPropose, equals(5000));
      expect(offer.pharmacyId, equals('pharma-bastos-01'));
      expect(offer.pharmacyNom, equals('Pharmacie Bastos'));

      // Vérification que la demande entrante est désormais marquée comme répondue
      final updatedDemands = await portalRepo.getIncomingDemands(
        pharmacyId: 'pharma-bastos-01',
      );
      final updatedDemand = updatedDemands.getOrElse((_) => []).firstWhere(
            (d) => d.demandeId == flashRequest.id,
          );
      expect(updatedDemand.isResponded, isTrue);

      // Vérification des statistiques journalières du pharmacien (1 devis envoyé)
      final analyticsAfterQuote = await getAnalyticsUseCase(
        GetPharmacyAnalyticsParams(
          pharmacyId: 'pharma-bastos-01',
          date: DateTime.now(),
        ),
      );
      expect(analyticsAfterQuote.isRight(), isTrue);
      final analytics1 = analyticsAfterQuote.getOrElse((_) => throw Exception());
      expect(analytics1.totalDemandsReceived, equals(1));
      expect(analytics1.totalQuotesSubmitted, equals(1));
      expect(analytics1.totalReservationsConfirmed, equals(0));

      // -------------------------------------------------------------
      // ÉTAPE 4: Le patient consulte l'offre reçue et la sélectionne
      // -------------------------------------------------------------
      final refreshedReqResult = await reservationRepo.getFlashRequestById(flashRequest.id);
      expect(refreshedReqResult.isRight(), isTrue);
      final refreshedReq = refreshedReqResult.getOrElse((_) => throw Exception());
      expect(refreshedReq.statut, equals(FlashRequestStatus.partiallyAnswered));
      expect(refreshedReq.offresRecues.length, equals(1));
      expect(refreshedReq.offresRecues.first.id, equals(offer.id));

      final selectResult = await selectOfferUseCase(
        SelectPharmacyOfferParams(
          clientReservationId: uuid.v4(),
          demandeId: flashRequest.id,
          offreId: offer.id,
          patientPhone: '+237699001122',
        ),
      );
      expect(selectResult.isRight(), isTrue);
      final reservation = selectResult.getOrElse((_) => throw Exception());

      // -------------------------------------------------------------
      // ÉTAPE 5: Vérification des invariants de réservation (OTP à 6 chiffres, TTL de 2h)
      // -------------------------------------------------------------
      expect(reservation.statut, equals(ReservationStatus.pending));
      expect(reservation.pharmacyId, equals('pharma-bastos-01'));
      expect(reservation.offreId, equals(offer.id));

      // Invariant: Code OTP strictement composé de 6 chiffres décimaux
      expect(
        RegExp(r'^\d{6}$').hasMatch(reservation.codeRetraitOtp6Chiffres),
        isTrue,
        reason: 'Le code OTP doit être exactement composé de 6 chiffres',
      );

      // Invariant: TTL strict de 2 heures
      final duration = reservation.expiresAt.difference(reservation.createdAt);
      expect(duration.inHours, equals(2));
      expect(reservation.isExpired, isFalse);

      // Vérification que la demande flash du patient est passée au statut fulfilled
      final fulfilledReqResult = await reservationRepo.getFlashRequestById(flashRequest.id);
      final fulfilledReq = fulfilledReqResult.getOrElse((_) => throw Exception());
      expect(fulfilledReq.statut, equals(FlashRequestStatus.fulfilled));

      // -------------------------------------------------------------
      // ÉTAPE 6: Le pharmacien valide le code OTP présenté au comptoir
      // -------------------------------------------------------------
      final validateResult = await validateOtpUseCase(
        ValidatePickupOtpParams(
          pharmacyId: 'pharma-bastos-01',
          reservationId: reservation.id,
          otpCode: reservation.codeRetraitOtp6Chiffres,
        ),
      );

      expect(validateResult.isRight(), isTrue);
      final confirmedReservation = validateResult.getOrElse((_) => throw Exception());
      expect(
        confirmedReservation.statut,
        equals(ReservationStatus.confirmedAtCounter),
      );

      // -------------------------------------------------------------
      // ÉTAPE 7: Vérification de l'incrémentation des analytics
      // -------------------------------------------------------------
      final finalAnalyticsResult = await getAnalyticsUseCase(
        GetPharmacyAnalyticsParams(
          pharmacyId: 'pharma-bastos-01',
          date: DateTime.now(),
        ),
      );
      expect(finalAnalyticsResult.isRight(), isTrue);
      final finalAnalytics = finalAnalyticsResult.getOrElse((_) => throw Exception());
      expect(finalAnalytics.totalReservationsConfirmed, equals(1));
      expect(finalAnalytics.totalQuotesSubmitted, equals(1));
      expect(finalAnalytics.conversionRate, equals(1.0)); // 100% conversion
    });

    test('round-robin wave escalation notifies next wave of 2 partner pharmacies', () async {
      final submitResult = await submitFlashUseCase(
        SubmitFlashRequestParams(
          clientRequestId: uuid.v4(),
          items: const [
            BasketItemModel(medication: medPara, quantite: 1),
          ],
          quartierOuCarrefour: 'Bastos',
        ),
      );

      final initial = submitResult.getOrElse((_) => throw Exception());
      expect(initial.vagueActuelle, equals(1));
      expect(initial.pharmaciesNotifieesIds.length, equals(2));

      // Escalade vers vague 2
      final escalateResult = await escalateWaveUseCase(
        EscalateDispatchWaveParams(
          demandeId: initial.id,
          currentWave: 1,
          candidatePharmacyIds: const [
            'pharma-mokolo-01',
            'pharma-tsinga-01',
            'pharma-obili-01',
          ],
          alreadyNotifiedPharmacyIds: initial.pharmaciesNotifieesIds,
        ),
      );

      expect(escalateResult.isRight(), isTrue);
      final escalated = escalateResult.getOrElse((_) => throw Exception());
      expect(escalated.vagueActuelle, equals(2));
      expect(escalated.pharmaciesNotifieesIds.length, equals(4));
      expect(escalated.pharmaciesNotifieesIds, contains('pharma-mokolo-01'));
      expect(escalated.pharmaciesNotifieesIds, contains('pharma-tsinga-01'));

      // Vérification que Pharmacie Mokolo a bien reçu la demande
      final mokoloDemands = await portalRepo.getIncomingDemands(
        pharmacyId: 'pharma-mokolo-01',
      );
      expect(mokoloDemands.getOrElse((_) => []), isNotEmpty);
    });

    test('confirmReservationOtp confirms reservation when validated directly by patient/system', () async {
      final submitResult = await submitFlashUseCase(
        SubmitFlashRequestParams(
          clientRequestId: uuid.v4(),
          items: const [
            BasketItemModel(medication: medPara, quantite: 1),
          ],
          quartierOuCarrefour: 'Bastos',
        ),
      );
      final flashReq = submitResult.getOrElse((_) => throw Exception());

      final quoteResult = await submitQuoteUseCase(
        CounterQuoteSubmission(
          demandId: flashReq.id,
          pharmacyId: 'pharma-bastos-01',
          itemResponses: const [
            OfferItemResponseModel(
              medicationId: 'med-para-500',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: 1500,
            ),
          ],
          montantTotal: 1500,
          livraisonPossible: false,
        ),
      );
      final offer = quoteResult.getOrElse((_) => throw Exception());

      final resResult = await selectOfferUseCase(
        SelectPharmacyOfferParams(
          clientReservationId: uuid.v4(),
          demandeId: flashReq.id,
          offreId: offer.id,
          patientPhone: '+237699001122',
        ),
      );
      final reservation = resResult.getOrElse((_) => throw Exception());

      final confirmResult = await confirmOtpUseCase(
        ConfirmReservationOtpParams(
          reservationId: reservation.id,
          otpCode: reservation.codeRetraitOtp6Chiffres,
        ),
      );

      expect(confirmResult.isRight(), isTrue);
      final confirmed = confirmResult.getOrElse((_) => throw Exception());
      expect(confirmed.statut, equals(ReservationStatus.confirmedAtCounter));
    });
  });

  group('Lifecycle Integration: Adversarial & Negative Test Cases', () {
    test('validatePickupOtp rejects invalid 6-digit OTP code', () async {
      final submitResult = await submitFlashUseCase(
        SubmitFlashRequestParams(
          clientRequestId: uuid.v4(),
          items: const [BasketItemModel(medication: medPara, quantite: 1)],
          quartierOuCarrefour: 'Bastos',
        ),
      );
      final flashReq = submitResult.getOrElse((_) => throw Exception());

      final quoteResult = await submitQuoteUseCase(
        CounterQuoteSubmission(
          demandId: flashReq.id,
          pharmacyId: 'pharma-bastos-01',
          itemResponses: const [
            OfferItemResponseModel(
              medicationId: 'med-para-500',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: 1500,
            ),
          ],
          montantTotal: 1500,
          livraisonPossible: false,
        ),
      );
      final offer = quoteResult.getOrElse((_) => throw Exception());

      final resResult = await selectOfferUseCase(
        SelectPharmacyOfferParams(
          clientReservationId: uuid.v4(),
          demandeId: flashReq.id,
          offreId: offer.id,
          patientPhone: '+237699001122',
        ),
      );
      final reservation = resResult.getOrElse((_) => throw Exception());

      // OTP intentionnellement erroné
      final invalidOtpResult = await validateOtpUseCase(
        ValidatePickupOtpParams(
          pharmacyId: 'pharma-bastos-01',
          reservationId: reservation.id,
          otpCode: '999999',
        ),
      );

      expect(invalidOtpResult.isLeft(), isTrue);
      invalidOtpResult.fold(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Should have rejected wrong OTP'),
      );
    });

    test('validatePickupOtp rejects validation by an unauthorized pharmacy', () async {
      final submitResult = await submitFlashUseCase(
        SubmitFlashRequestParams(
          clientRequestId: uuid.v4(),
          items: const [BasketItemModel(medication: medPara, quantite: 1)],
          quartierOuCarrefour: 'Bastos',
        ),
      );
      final flashReq = submitResult.getOrElse((_) => throw Exception());

      final quoteResult = await submitQuoteUseCase(
        CounterQuoteSubmission(
          demandId: flashReq.id,
          pharmacyId: 'pharma-bastos-01',
          itemResponses: const [
            OfferItemResponseModel(
              medicationId: 'med-para-500',
              status: ItemAvailabilityStatus.available,
              prixUnitaireCommunicParPharmacien: 1500,
            ),
          ],
          montantTotal: 1500,
          livraisonPossible: false,
        ),
      );
      final offer = quoteResult.getOrElse((_) => throw Exception());

      final resResult = await selectOfferUseCase(
        SelectPharmacyOfferParams(
          clientReservationId: uuid.v4(),
          demandeId: flashReq.id,
          offreId: offer.id,
          patientPhone: '+237699001122',
        ),
      );
      final reservation = resResult.getOrElse((_) => throw Exception());

      // Pharmacie Mokolo tente de valider la réservation appartenant à Pharmacie Bastos
      final wrongPharmaResult = await validateOtpUseCase(
        ValidatePickupOtpParams(
          pharmacyId: 'pharma-mokolo-01',
          reservationId: reservation.id,
          otpCode: reservation.codeRetraitOtp6Chiffres,
        ),
      );

      expect(wrongPharmaResult.isLeft(), isTrue);
      wrongPharmaResult.fold(
        (failure) => expect(failure, isA<AuthFailure>()),
        (_) => fail('Should have rejected unauthorized pharmacy'),
      );
    });

    test('confirmReservationOtpUseCase rejects expired 2h TTL reservation', () async {
      // Réservation expirée (créée il y a 3 heures)
      final expiredCreatedAt = DateTime.now().subtract(const Duration(hours: 3));
      final expiredExpiresAt = DateTime.now().subtract(const Duration(hours: 1));

      final expiredReservation = ReservationModel(
        id: 'res-expired-1',
        clientReservationId: 'client-res-exp',
        demandeId: 'req-exp-1',
        offreId: 'offer-exp-1',
        pharmacyId: 'pharma-bastos-01',
        codeRetraitOtp6Chiffres: '123456',
        statut: ReservationStatus.pending,
        createdAt: expiredCreatedAt,
        expiresAt: expiredExpiresAt,
      );

      final result = await confirmOtpUseCase(
        ConfirmReservationOtpParams(
          reservationId: 'res-expired-1',
          otpCode: '123456',
          reservation: expiredReservation,
        ),
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ReservationFailure>()),
        (_) => fail('Should have rejected expired reservation'),
      );
    });
  });
}
