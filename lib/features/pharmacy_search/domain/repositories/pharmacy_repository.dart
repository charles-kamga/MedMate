import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/medication.dart';
import '../entities/pharmacy.dart';
import '../entities/reservation.dart';

/// Contrat du repository de recherche et réservation pharmaceutique
abstract class PharmacyRepository {
  /// Recherche des pharmacies de garde/proximité par repère ou GPS (PostGIS)
  Future<Either<Failure, List<Pharmacy>>> searchNearbyPharmacies({
    required double latitude,
    required double longitude,
    double maxRadiusMeters = 3500,
  });

  /// Recherche textuelle tolérante aux fautes d'orthographe (Extension pg_trgm)
  Future<Either<Failure, List<Medication>>> searchMedications(String query);

  /// Demande de réservation temporaire (Idempotence & TTL 2h)
  Future<Either<Failure, Reservation>> requestReservation({
    required String clientReservationId,
    required String pharmacyId,
    required String medicationId,
    required String patientPhone,
    required int quantite,
  });
}
