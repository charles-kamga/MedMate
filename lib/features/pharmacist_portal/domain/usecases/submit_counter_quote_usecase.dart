import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/reservation/domain/entities/item_availability_status.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';

/// Cas d'utilisation: soumission d'un devis comptoir formulé par le pharmacien.
///
/// Valide les invariants de tarification au comptoir (prix non négatifs, réponse non vide)
/// et transmet l'offre chiffrée au patient via le référentiel.
class SubmitCounterQuoteUseCase {
  const SubmitCounterQuoteUseCase(this._repository);

  final PharmacistPortalRepository _repository;

  Future<Either<Failure, PharmacyOffer>> call(
    CounterQuoteSubmission submission,
  ) async {
    if (submission.demandId.trim().isEmpty ||
        submission.pharmacyId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Paramètres de soumission invalides.'),
      );
    }

    if (submission.itemResponses.isEmpty) {
      return const Left(
        ReservationFailure('La réponse doit contenir au moins un article.'),
      );
    }

    if (submission.montantTotal < 0) {
      return const Left(
        ReservationFailure('Le montant total ne peut pas être négatif.'),
      );
    }

    final hasNegativePrice = submission.itemResponses.any(
      (item) =>
          (item.status == ItemAvailabilityStatus.available ||
              item.status == ItemAvailabilityStatus.conditional) &&
          item.prixUnitaireCommunicParPharmacien < 0,
    );
    if (hasNegativePrice) {
      return const Left(
        ReservationFailure('Le prix unitaire ne peut pas être négatif.'),
      );
    }

    return _repository.submitCounterQuote(submission);
  }
}
