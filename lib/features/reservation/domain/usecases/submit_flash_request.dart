import 'package:fpdart/fpdart.dart';
import '../../../../core/constants/yaounde_landmarks.dart';
import '../../../../core/errors/failures.dart';
import '../entities/basket_item.dart';
import '../entities/flash_order.dart';
import '../repositories/reservation_repository.dart';

/// Cas d'utilisation : diffusion de la demande de réservation flash par vagues
class SubmitFlashRequestUseCase {
  const SubmitFlashRequestUseCase(this._repository);

  final ReservationRepository _repository;

  Future<Either<Failure, FlashOrder>> call({
    required List<BasketItem> items,
    required YaoundeLandmark landmark,
  }) {
    if (items.isEmpty) {
      return Future.value(
        const Left(ReservationFailure('Le panier de médicaments est vide.')),
      );
    }
    return _repository.submitFlashRequest(
      items: items,
      landmark: landmark,
    );
  }
}
