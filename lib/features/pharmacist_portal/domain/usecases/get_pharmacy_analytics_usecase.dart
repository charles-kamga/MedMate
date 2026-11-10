import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacist_portal/domain/entities/pharmacy_daily_analytics.dart';
import 'package:medmate/features/pharmacist_portal/domain/repositories/pharmacist_portal_repository.dart';

/// Paramètres de consultation des statistiques journalières d'une officine.
class GetPharmacyAnalyticsParams extends Equatable {
  const GetPharmacyAnalyticsParams({
    required this.pharmacyId,
    required this.date,
  });

  /// Identifiant de l'officine.
  final String pharmacyId;

  /// Date de l'activité recherchée.
  final DateTime date;

  @override
  List<Object?> get props => [pharmacyId, date];
}

/// Cas d'utilisation: consultation des statistiques journalières anonymisées de l'officine.
///
/// Respecte le principe de minimisation et de confidentialité des données de santé (Loi n° 2024/017).
class GetPharmacyAnalyticsUseCase {
  const GetPharmacyAnalyticsUseCase(this._repository);

  final PharmacistPortalRepository _repository;

  Future<Either<Failure, PharmacyDailyAnalytics>> call(
    GetPharmacyAnalyticsParams params,
  ) async {
    final trimmedPharmacyId = params.pharmacyId.trim();
    if (trimmedPharmacyId.isEmpty) {
      return const Left(
        AuthFailure('Identifiant pharmacie manquant.'),
      );
    }

    return _repository.getPharmacyAnalytics(
      pharmacyId: trimmedPharmacyId,
      date: params.date,
    );
  }
}
