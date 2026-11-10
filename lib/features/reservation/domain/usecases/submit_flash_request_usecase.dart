import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/basket_item.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';

/// Paramètres requis pour la soumission d'une demande flash de disponibilité.
class SubmitFlashRequestParams extends Equatable {
  const SubmitFlashRequestParams({
    required this.clientRequestId,
    required this.items,
    required this.quartierOuCarrefour,
    this.latitude,
    this.longitude,
  });

  final String clientRequestId;
  final List<BasketItem> items;
  final String quartierOuCarrefour;
  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [
        clientRequestId,
        items,
        quartierOuCarrefour,
        latitude,
        longitude,
      ];
}

/// Cas d'utilisation: soumission d'une demande flash de disponibilité multi-officines.
class SubmitFlashRequestUseCase {
  const SubmitFlashRequestUseCase(this._repository);

  final ReservationRepository _repository;

  Future<Either<Failure, FlashRequest>> call(
    SubmitFlashRequestParams params,
  ) async {
    if (params.items.isEmpty) {
      return const Left(ValidationFailure('Le panier ne peut pas être vide.'));
    }

    final hasInvalidQuantity = params.items.any((item) => item.quantite < 1);
    if (hasInvalidQuantity) {
      return const Left(
        ValidationFailure(
          'La quantité de chaque médicament doit être au moins 1.',
        ),
      );
    }

    if (params.clientRequestId.trim().isEmpty ||
        params.quartierOuCarrefour.trim().isEmpty) {
      return const Left(
        ValidationFailure('Paramètres de demande invalides.'),
      );
    }

    return _repository.submitFlashRequest(
      clientRequestId: params.clientRequestId.trim(),
      items: params.items,
      quartierOuCarrefour: params.quartierOuCarrefour.trim(),
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}
