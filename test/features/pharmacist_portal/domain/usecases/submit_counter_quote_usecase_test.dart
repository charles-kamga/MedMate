import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/pharmacist_portal/domain/usecases/submit_counter_quote_usecase.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/offer_item_response.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistPortalRepository extends Mock
    implements PharmacistPortalRepository {}

void main() {
  late SubmitCounterQuoteUseCase useCase;
  late MockPharmacistPortalRepository mockRepository;

  const sampleItemResponse = OfferItemResponse(
    medicationId: 'med-para-500',
    status: ItemAvailabilityStatus.available,
    prixUnitaireCommunicParPharmacien: 1250,
    conditionDelivrance: null,
    commentaire: 'Disponible au comptoir',
  );

  const sampleSubmission = CounterQuoteSubmission(
    demandId: 'demand-1',
    pharmacyId: 'pharma-1',
    itemResponses: [sampleItemResponse],
    montantTotal: 2500,
    livraisonPossible: true,
    fraisLivraison: 1000,
    delaiMinutes: 20,
  );

  final sampleOffer = PharmacyOffer(
    id: 'offer-1',
    demandeId: 'demand-1',
    pharmacyId: 'pharma-1',
    pharmacyNom: 'Pharmacie Bastos',
    quartier: 'Bastos',
    items: const [sampleItemResponse],
    montantTotalPropose: 2500,
    livraisonDisponible: true,
    createdAt: DateTime(2026, 11, 9, 20, 0),
  );

  setUp(() {
    mockRepository = MockPharmacistPortalRepository();
    useCase = SubmitCounterQuoteUseCase(mockRepository);
  });

  group('SubmitCounterQuoteUseCase & Tarification au Comptoir Invariant', () {
    test('returns Right(PharmacyOffer) when quote submission is valid',
        () async {
      when(
        () => mockRepository.submitCounterQuote(sampleSubmission),
      ).thenAnswer((_) async => Right(sampleOffer));

      final result = await useCase(sampleSubmission);

      expect(result, equals(Right<Failure, PharmacyOffer>(sampleOffer)));
      verify(() => mockRepository.submitCounterQuote(sampleSubmission)).called(1);
    });

    test('returns Left(ReservationFailure) when itemResponses list is empty',
        () async {
      final invalidSubmission = sampleSubmission.copyWith(
        itemResponses: const [],
      );

      final result = await useCase(invalidSubmission);

      expect(
        result,
        equals(
          const Left<Failure, PharmacyOffer>(
            ReservationFailure('La réponse doit contenir au moins un article.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ReservationFailure) when montantTotal is negative',
        () async {
      final invalidSubmission = sampleSubmission.copyWith(
        montantTotal: -500,
      );

      final result = await useCase(invalidSubmission);

      expect(
        result,
        equals(
          const Left<Failure, PharmacyOffer>(
            ReservationFailure('Le montant total ne peut pas être négatif.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ReservationFailure) when an item has negative unit price',
        () async {
      const negativeItem = OfferItemResponse(
        medicationId: 'med-para-500',
        status: ItemAvailabilityStatus.available,
        prixUnitaireCommunicParPharmacien: -100,
      );

      final invalidSubmission = sampleSubmission.copyWith(
        itemResponses: const [negativeItem],
      );

      final result = await useCase(invalidSubmission);

      expect(
        result,
        equals(
          const Left<Failure, PharmacyOffer>(
            ReservationFailure('Le prix unitaire ne peut pas être négatif.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ValidationFailure) when demandId or pharmacyId is empty',
        () async {
      final emptyDemandSubmission = sampleSubmission.copyWith(demandId: '   ');
      final resultDemand = await useCase(emptyDemandSubmission);
      expect(
        resultDemand,
        equals(
          const Left<Failure, PharmacyOffer>(
            ValidationFailure('Paramètres de soumission invalides.'),
          ),
        ),
      );

      final emptyPharmacySubmission =
          sampleSubmission.copyWith(pharmacyId: '   ');
      final resultPharmacy = await useCase(emptyPharmacySubmission);
      expect(
        resultPharmacy,
        equals(
          const Left<Failure, PharmacyOffer>(
            ValidationFailure('Paramètres de soumission invalides.'),
          ),
        ),
      );
      verifyZeroInteractions(mockRepository);
    });

    test('returns Left(ServerFailure) when repository submission fails',
        () async {
      const failure = ServerFailure('Erreur serveur lors de la soumission.');
      when(
        () => mockRepository.submitCounterQuote(sampleSubmission),
      ).thenAnswer((_) async => const Left(failure));

      final result = await useCase(sampleSubmission);

      expect(result, equals(const Left<Failure, PharmacyOffer>(failure)));
    });
  });
}
