import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/data/datasources/flash_order_data_source.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/data/models/basket_item_model.dart';
import 'package:medmate/features/reservation/data/models/flash_request_model.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:uuid/uuid.dart';

/// Implémentation du référentiel des demandes flash et réservations.
class ReservationRepositoryImpl implements ReservationRepository {
  ReservationRepositoryImpl({
    FlashOrderDataSource? dataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource ?? FlashOrderDataSourceImpl(),
        _uuid = uuid ?? const Uuid();

  final FlashOrderDataSource _dataSource;
  final Uuid _uuid;

  @override
  Future<Either<Failure, FlashRequest>> submitFlashRequest({
    required String clientRequestId,
    required List<BasketItem> items,
    required String quartierOuCarrefour,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final now = DateTime.now();
      final requestModel = FlashRequestModel(
        id: _uuid.v4(),
        clientRequestId: clientRequestId,
        items: items.map(BasketItemModel.fromDomain).toList(),
        quartierOuCarrefour: quartierOuCarrefour,
        statut: FlashRequestStatus.pending,
        vagueActuelle: 1,
        pharmaciesNotifieesIds: const [],
        offresRecues: const [],
        createdAt: now,
        expiresAt: now.add(const Duration(minutes: 30)),
      );

      final result = await _dataSource.submitFlashRequest(requestModel);
      return Right(result);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ReservationException catch (e) {
      return Left(ReservationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FlashRequest>> escalateDispatchWave({
    required String demandeId,
    required int nextWaveNumber,
    required List<String> eligiblePharmacyIds,
  }) async {
    try {
      final result = await _dataSource.escalateDispatchWave(
        demandeId: demandeId,
        nextWaveNumber: nextWaveNumber,
        eligiblePharmacyIds: eligiblePharmacyIds,
      );
      return Right(result);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ReservationException catch (e) {
      return Left(ReservationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Reservation>> selectPharmacyOffer({
    required String clientReservationId,
    required String demandeId,
    required String offreId,
    required String patientPhone,
  }) async {
    try {
      final result = await _dataSource.selectPharmacyOffer(
        clientReservationId: clientReservationId,
        demandeId: demandeId,
        offreId: offreId,
        patientPhone: patientPhone,
      );
      return Right(result);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ReservationException catch (e) {
      return Left(ReservationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Reservation>> confirmReservationOtp({
    required String reservationId,
    required String otpCode,
  }) async {
    try {
      final result = await _dataSource.confirmReservationOtp(
        reservationId: reservationId,
        otpCode: otpCode,
      );
      return Right(result);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ReservationException catch (e) {
      return Left(ReservationFailure(e.message));
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FlashRequest>> getFlashRequestById(
    String demandeId,
  ) async {
    try {
      final result = await _dataSource.getFlashRequestById(demandeId);
      return Right(result);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Reservation>> getReservationById(
    String reservationId,
  ) async {
    try {
      final result = await _dataSource.getReservationById(reservationId);
      return Right(result);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
