import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/exceptions.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/data/datasources/pharmacist_portal_data_source.dart';
import 'package:medmate/features/pharmacist_portal/data/models/counter_quote_submission_model.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/counter_quote_submission.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/incoming_demand.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';
import 'package:medmate/features/reservation/data/datasources/in_memory_flash_order_store.dart';
import 'package:medmate/features/reservation/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/entities/reservation.dart';

/// Implémentation du référentiel du portail comptoir pharmacien.
class PharmacistPortalRepositoryImpl implements PharmacistPortalRepository {
  PharmacistPortalRepositoryImpl({
    PharmacistPortalDataSource? dataSource,
  }) : _dataSource = dataSource ?? PharmacistPortalDataSourceImpl();

  final PharmacistPortalDataSource _dataSource;

  @override
  Future<Either<Failure, List<IncomingDemand>>> getIncomingDemands({
    required String pharmacyId,
  }) async {
    try {
      final demands = await _dataSource.getIncomingDemands(pharmacyId);
      return Right(demands);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PharmacyOffer>> submitCounterQuote(
    CounterQuoteSubmission submission,
  ) async {
    try {
      final submissionModel = CounterQuoteSubmissionModel.fromDomain(
        submission,
      );
      final offer = await _dataSource.submitCounterQuote(submissionModel);
      return Right(offer);
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
  Future<Either<Failure, Reservation>> validatePickupOtp({
    required String pharmacyId,
    required String reservationId,
    required String otpCode,
  }) async {
    try {
      final reservation = await _dataSource.validatePickupOtp(
        pharmacyId: pharmacyId,
        reservationId: reservationId,
        otpCode: otpCode,
      );
      return Right(reservation);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
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
  Future<Either<Failure, PharmacyDailyAnalytics>> getPharmacyAnalytics({
    required String pharmacyId,
    required DateTime date,
  }) async {
    try {
      final analytics = await _dataSource.getPharmacyAnalytics(
        pharmacyId: pharmacyId,
        date: date,
      );
      return Right(analytics);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
