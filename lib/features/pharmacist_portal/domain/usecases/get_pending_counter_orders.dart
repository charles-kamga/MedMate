import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../../../flash_order/domain/entities/flash_order.dart';
import '../repositories/pharmacist_portal_repository.dart';

/// Cas d'utilisation : Récupère la liste des demandes flash en attente pour l'officine
class GetPendingCounterOrdersUseCase {
  const GetPendingCounterOrdersUseCase(this._repository);

  final PharmacistPortalRepository _repository;

  Future<Either<Failure, List<FlashOrder>>> call(String pharmacyId) {
    if (pharmacyId.trim().isEmpty) {
      return Future.value(
        const Left(NotFoundFailure("Identifiant d'officine non renseigné.")),
      );
    }
    return _repository.getPendingOrdersForPharmacy(pharmacyId);
  }
}
