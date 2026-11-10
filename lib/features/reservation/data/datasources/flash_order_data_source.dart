import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/data/models/reservation_model.dart';

/// Contrat abstrait de la source de données des commandes flash et réservations.
abstract class FlashOrderDataSource {
  /// Soumet une demande flash et diffuse vers la première vague d'officines.
  Future<FlashRequestModel> submitFlashRequest(FlashRequestModel request);

  /// Escalade la diffusion de la demande vers une nouvelle vague d'officines partenaires.
  Future<FlashRequestModel> escalateDispatchWave({
    required String demandeId,
    required int nextWaveNumber,
    required List<String> eligiblePharmacyIds,
  });

  /// Sélectionne une offre reçue et génère une réservation avec OTP et TTL de 2h.
  Future<ReservationModel> selectPharmacyOffer({
    required String clientReservationId,
    required String demandeId,
    required String offreId,
    required String patientPhone,
  });

  /// Confirme la réservation lors de la validation du code OTP à 6 chiffres.
  Future<ReservationModel> confirmReservationOtp({
    required String reservationId,
    required String otpCode,
  });

  /// Récupère une demande flash par son identifiant unique.
  Future<FlashRequestModel> getFlashRequestById(String demandeId);

  /// Récupère une réservation par son identifiant unique.
  Future<ReservationModel> getReservationById(String reservationId);
}

/// Implémentation de la source de données des commandes flash
/// connectée au coordinateur synchronisé en mémoire.
class FlashOrderDataSourceImpl implements FlashOrderDataSource {
  FlashOrderDataSourceImpl({InMemoryFlashOrderStore? store})
      : _store = store ?? InMemoryFlashOrderStore.instance;

  final InMemoryFlashOrderStore _store;

  @override
  Future<FlashRequestModel> submitFlashRequest(FlashRequestModel request) =>
      _store.submitFlashRequest(request);

  @override
  Future<FlashRequestModel> escalateDispatchWave({
    required String demandeId,
    required int nextWaveNumber,
    required List<String> eligiblePharmacyIds,
  }) =>
      _store.escalateDispatchWave(
        demandeId: demandeId,
        nextWaveNumber: nextWaveNumber,
        eligiblePharmacyIds: eligiblePharmacyIds,
      );

  @override
  Future<ReservationModel> selectPharmacyOffer({
    required String clientReservationId,
    required String demandeId,
    required String offreId,
    required String patientPhone,
  }) =>
      _store.selectPharmacyOffer(
        clientReservationId: clientReservationId,
        demandeId: demandeId,
        offreId: offreId,
        patientPhone: patientPhone,
      );

  @override
  Future<ReservationModel> confirmReservationOtp({
    required String reservationId,
    required String otpCode,
  }) =>
      _store.confirmReservationOtp(
        reservationId: reservationId,
        otpCode: otpCode,
      );

  @override
  Future<FlashRequestModel> getFlashRequestById(String demandeId) =>
      _store.getFlashRequestById(demandeId);

  @override
  Future<ReservationModel> getReservationById(String reservationId) =>
      _store.getReservationById(reservationId);
}
