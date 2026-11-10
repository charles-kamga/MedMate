import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/pharmacy_offer.dart';
import '../entities/reservation.dart';
import '../repositories/reservation_repository.dart';

/// Cas d'utilisation : sélection souveraine d'une offre officinale avec génération du ticket OTP 2h
class SelectPharmacyOfferUseCase {
  const SelectPharmacyOfferUseCase(this._repository);

  final ReservationRepository _repository;

  Future<Either<Failure, Reservation>> call({
    required String orderId,
    required PharmacyOffer offer,
    required String patientPhone,
  }) {
    final sanitizedOrderId = orderId.trim();
    if (sanitizedOrderId.isEmpty) {
      return Future.value(
        const Left(ReservationFailure('Identifiant de commande manquant.')),
      );
    }
    final sanitizedPhone = patientPhone.trim();
    if (sanitizedPhone.isEmpty) {
      return Future.value(
        const Left(ReservationFailure(
            'Numéro de téléphone requis pour la réservation.',),),
      );
    }
    return _repository.selectPharmacyOffer(
      orderId: sanitizedOrderId,
      offer: offer,
      patientPhone: sanitizedPhone,
    );
  }
}
