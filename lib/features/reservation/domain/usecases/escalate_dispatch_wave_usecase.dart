import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/reservation/domain/entities/flash_request.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';

/// Paramètres requis pour l'escalade d'une vague de diffusion.
class EscalateDispatchWaveParams extends Equatable {
  const EscalateDispatchWaveParams({
    required this.demandeId,
    required this.currentWave,
    required this.candidatePharmacyIds,
    required this.alreadyNotifiedPharmacyIds,
  });

  final String demandeId;
  final int currentWave;
  final List<String> candidatePharmacyIds;
  final List<String> alreadyNotifiedPharmacyIds;

  @override
  List<Object?> get props => [
        demandeId,
        currentWave,
        candidatePharmacyIds,
        alreadyNotifiedPharmacyIds,
      ];
}

/// Cas d'utilisation: escalade équitable de la demande par vagues Round-Robin (ONPC).
///
/// Notifie par lots de 2 officines partenaires non encore contactées et
/// incrémente le numéro de vague.
class EscalateDispatchWaveUseCase {
  const EscalateDispatchWaveUseCase(this._repository);

  final ReservationRepository _repository;

  Future<Either<Failure, FlashRequest>> call(
    EscalateDispatchWaveParams params,
  ) async {
    if (params.demandeId.trim().isEmpty) {
      return const Left(
        ValidationFailure('Identifiant de demande manquant.'),
      );
    }

    // Filtrage des officines candidates déjà notifiées lors des vagues antérieures
    final unnotified = params.candidatePharmacyIds
        .where((id) => !params.alreadyNotifiedPharmacyIds.contains(id))
        .toList();

    if (unnotified.isEmpty) {
      return const Left(
        ReservationFailure(
          'Aucune officine partenaire supplémentaire disponible pour escalade.',
        ),
      );
    }

    // Déontologie ONPC: diffusion équitable par lots de 2 pharmacies partenaires
    final nextBatch = unnotified.take(2).toList();
    final nextWaveNumber = params.currentWave + 1;

    return _repository.escalateDispatchWave(
      demandeId: params.demandeId.trim(),
      nextWaveNumber: nextWaveNumber,
      eligiblePharmacyIds: nextBatch,
    );
  }
}
