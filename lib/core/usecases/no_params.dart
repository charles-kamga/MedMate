import 'package:equatable/equatable.dart';

/// Paramètre sentinelle représentant l'absence d'arguments pour un UseCase.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
