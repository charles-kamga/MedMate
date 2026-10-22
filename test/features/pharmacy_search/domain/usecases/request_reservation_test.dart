import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/reservation.dart';
import 'package:medmate/features/pharmacy_search/domain/repositories/pharmacy_repository.dart';
import 'package:medmate/features/pharmacy_search/domain/usecases/request_reservation.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacyRepository extends Mock implements PharmacyRepository {}

void main() {
  late MockPharmacyRepository mockRepository;
  late RequestReservationUseCase useCase;

  setUp(() {
    mockRepository = MockPharmacyRepository();
    useCase = RequestReservationUseCase(mockRepository);
  });

  const tParams = RequestReservationParams(
    clientReservationId: 'test-uuid-v4',
    pharmacyId: 'pharmacy-1',
    medicationId: 'med-1',
    patientPhone: '+237699001122',
    quantite: 2,
  );

  final tReservation = Reservation(
    id: 'res-1',
    clientReservationId: 'test-uuid-v4',
    pharmacyId: 'pharmacy-1',
    pharmacyName: 'Grande Pharmacie du Centre',
    medicationId: 'med-1',
    medicationName: 'Doliprane 1000mg',
    quantite: 2,
    codeRetraitOtp: '849201',
    statut: ReservationStatus.pending,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  test('doit confirmer la réservation avec succès quand les paramètres sont valides', () async {
    // Arrange
    when(
      () => mockRepository.requestReservation(
        clientReservationId: any(named: 'clientReservationId'),
        pharmacyId: any(named: 'pharmacyId'),
        medicationId: any(named: 'medicationId'),
        patientPhone: any(named: 'patientPhone'),
        quantite: any(named: 'quantite'),
      ),
    ).thenAnswer((_) async => Right(tReservation));

    // Act
    final result = await useCase(tParams);

    // Assert
    expect(result, Right(tReservation));
    verify(
      () => mockRepository.requestReservation(
        clientReservationId: 'test-uuid-v4',
        pharmacyId: 'pharmacy-1',
        medicationId: 'med-1',
        patientPhone: '+237699001122',
        quantite: 2,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('doit renvoyer un ReservationFailure si la quantité est inférieure ou égale à 0', () async {
    // Arrange
    const invalidParams = RequestReservationParams(
      clientReservationId: 'test-uuid-v4',
      pharmacyId: 'pharmacy-1',
      medicationId: 'med-1',
      patientPhone: '+237699001122',
      quantite: 0,
    );

    // Act
    final result = await useCase(invalidParams);

    // Assert
    expect(
      result,
      const Left(ReservationFailure('La quantité doit être supérieure à zéro.')),
    );
    verifyZeroInteractions(mockRepository);
  });

  test('doit renvoyer un ReservationFailure si le numéro de téléphone est vide', () async {
    // Arrange
    const invalidPhoneParams = RequestReservationParams(
      clientReservationId: 'test-uuid-v4',
      pharmacyId: 'pharmacy-1',
      medicationId: 'med-1',
      patientPhone: '  ',
      quantite: 1,
    );

    // Act
    final result = await useCase(invalidPhoneParams);

    // Assert
    expect(
      result,
      const Left(ReservationFailure('Numéro de téléphone requis pour la réservation.')),
    );
    verifyZeroInteractions(mockRepository);
  });
}
