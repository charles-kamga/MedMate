import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/reservation.dart';
import '../repositories/pharmacy_repository.dart';

class RequestReservationParams extends Equatable {
  const RequestReservationParams({
    required this.clientReservationId,
    required this.pharmacyId,
    required this.medicationId,
    required this.patientPhone,
    required this.quantite,
  });

  final String clientReservationId;
  final String pharmacyId;
  final String medicationId;
  final String patientPhone;
  final int quantite;

  @override
  List<Object?> get props => [
        clientReservationId,
        pharmacyId,
        medicationId,
        patientPhone,
        quantite,
      ];
}

class RequestReservationUseCase {
  const RequestReservationUseCase(this._repository);

  final PharmacyRepository _repository;

  Future<Either<Failure, Reservation>> call(RequestReservationParams params) {
    if (params.quantite <= 0) {
      return Future.value(
        const Left(ReservationFailure('La quantité doit être supérieure à zéro.')),
      );
    }
    if (params.patientPhone.trim().isEmpty) {
      return Future.value(
        const Left(ReservationFailure('Numéro de téléphone requis pour la réservation.')),
      );
    }
    return _repository.requestReservation(
      clientReservationId: params.clientReservationId,
      pharmacyId: params.pharmacyId,
      medicationId: params.medicationId,
      patientPhone: params.patientPhone,
      quantite: params.quantite,
    );
  }
}
