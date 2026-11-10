import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

/// Contrat abstrait du référentiel des demandes flash et des réservations.
abstract class ReservationRepository {
  /// Soumet une nouvelle demande flash de disponibilité multi-officines.
  Future<Either<Failure, FlashRequest>> submitFlashRequest({
    required String clientRequestId,
    required List<BasketItem> items,
    required String quartierOuCarrefour,
    double? latitude,
    double? longitude,
  });

  /// Escalade la diffusion de la demande vers une nouvelle vague de pharmacies partenaires.
  Future<Either<Failure, FlashRequest>> escalateDispatchWave({
    required String demandeId,
    required int nextWaveNumber,
    required List<String> eligiblePharmacyIds,
  });

  /// Sélectionne une offre reçue et initialise une réservation avec OTP et TTL de 2h.
  Future<Either<Failure, Reservation>> selectPharmacyOffer({
    required String clientReservationId,
    required String demandeId,
    required String offreId,
    required String patientPhone,
  });

  /// Confirme la réservation au comptoir lors de la saisie/vérification du code OTP.
  Future<Either<Failure, Reservation>> confirmReservationOtp({
    required String reservationId,
    required String otpCode,
  });

  /// Récupère une demande flash par son identifiant unique.
  Future<Either<Failure, FlashRequest>> getFlashRequestById(String demandeId);

  /// Récupère une réservation par son identifiant unique.
  Future<Either<Failure, Reservation>> getReservationById(String reservationId);
}
