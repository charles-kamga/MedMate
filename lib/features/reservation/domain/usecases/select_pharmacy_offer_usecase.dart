import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';

/// Paramètres requis pour la sélection d'une offre officine et la création de réservation.
class SelectPharmacyOfferParams extends Equatable {
  const SelectPharmacyOfferParams({
    required this.clientReservationId,
    required this.demandeId,
    required this.offreId,
    required this.patientPhone,
  });

  /// Identifiant d'idempotence client (UUID v4).
  final String clientReservationId;

  /// Identifiant de la demande flash associée.
  final String demandeId;

  /// Identifiant de l'offre officine sélectionnée par le patient.
  final String offreId;

  /// Numéro de téléphone du patient au format camerounais (+237...).
  final String patientPhone;

  @override
  List<Object?> get props => [
        clientReservationId,
        demandeId,
        offreId,
        patientPhone,
      ];
}

/// Cas d'utilisation: sélection d'une offre officine par le patient.
///
/// Valide le numéro de téléphone selon la réglementation camerounaise (Loi n° 2024/017)
/// et initialise une réservation d'une validité TTL stricte de 2 heures avec code OTP.
class SelectPharmacyOfferUseCase {
  const SelectPharmacyOfferUseCase(this._repository);

  final ReservationRepository _repository;

  /// Expression régulière des numéros de téléphone mobiles/fixes camerounais.
  static final RegExp _cameroonPhoneRegex =
      RegExp(r'^(?:(?:\+237)|(?:237))?[26]\d{8}$');

  Future<Either<Failure, Reservation>> call(
    SelectPharmacyOfferParams params,
  ) async {
    if (params.clientReservationId.trim().isEmpty ||
        params.demandeId.trim().isEmpty ||
        params.offreId.trim().isEmpty) {
      return const Left(
        ValidationFailure("Paramètres de sélection d'offre invalides."),
      );
    }

    final trimmedPhone = params.patientPhone.trim();
    if (!_cameroonPhoneRegex.hasMatch(trimmedPhone)) {
      return const Left(
        ReservationFailure(
          'Numéro de téléphone camerounais invalide (+237...).',
        ),
      );
    }

    return _repository.selectPharmacyOffer(
      clientReservationId: params.clientReservationId.trim(),
      demandeId: params.demandeId.trim(),
      offreId: params.offreId.trim(),
      patientPhone: trimmedPhone,
    );
  }
}
