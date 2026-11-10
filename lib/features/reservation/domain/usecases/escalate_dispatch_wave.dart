import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/flash_order.dart';
import '../repositories/reservation_repository.dart';

/// Cas d'utilisation : escalade vers la vague de diffusion suivante (2 officines / 2 min)
class EscalateDispatchWaveUseCase {
  const EscalateDispatchWaveUseCase(this._repository);

  final ReservationRepository _repository;

  Future<Either<Failure, FlashOrder>> call(String orderId) {
    final sanitizedId = orderId.trim();
    if (sanitizedId.isEmpty) {
      return Future.value(
        const Left(ReservationFailure(
            'Identifiant de commande manquant ou invalide.',),),
      );
    }
    return _repository.escalateDispatchWave(sanitizedId);
  }
}
