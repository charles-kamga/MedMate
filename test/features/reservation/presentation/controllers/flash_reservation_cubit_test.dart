import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/core/errors/failures.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/domain/repositories/reservation_repository.dart';
import 'package:medmate/features/reservation/domain/usecases/escalate_dispatch_wave.dart';
import 'package:medmate/features/reservation/domain/usecases/select_pharmacy_offer.dart';
import 'package:medmate/features/reservation/domain/usecases/submit_flash_request.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';
import 'package:mocktail/mocktail.dart';

class MockSubmitFlashRequestUseCase extends Mock
    implements SubmitFlashRequestUseCase {}

class MockEscalateDispatchWaveUseCase extends Mock
    implements EscalateDispatchWaveUseCase {}

class MockSelectPharmacyOfferUseCase extends Mock
    implements SelectPharmacyOfferUseCase {}

class MockReservationRepository extends Mock
    implements ReservationRepository {}

void main() {
  late MockSubmitFlashRequestUseCase mockSubmitFlashRequestUseCase;
  late MockEscalateDispatchWaveUseCase mockEscalateDispatchWaveUseCase;
  late MockSelectPharmacyOfferUseCase mockSelectPharmacyOfferUseCase;
  late MockReservationRepository mockReservationRepository;
  late FlashReservationCubit cubit;

  const sampleLandmark = YaoundeLandmark(
    id: 'carrefour-warda',
    nom: 'Carrefour Warda',
    quartier: 'Poste Centrale',
    arrondissement: 'Yaoundé 1er',
    latitude: 3.8688,
    longitude: 11.5175,
    description: 'Face au Bois Sainte-Anastasie',
  );

  const sampleMedication = Medication(
    id: 'med-paracetamol',
    nomCommercial: 'Paracétamol 500 mg',
    dci: 'Paracétamol',
    forme: 'Comprimé',
    dosage: '500 mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1500,
    necessiteOrdonnance: false,
  );

  const sampleMedicationRx = Medication(
    id: 'med-amox',
    nomCommercial: 'Amoxicilline 500 mg',
    dci: 'Amoxicilline',
    forme: 'Gélule',
    dosage: '500 mg',
    classeTherapeutique: 'Antibiotique',
    prixHomologueCfa: 3200,
    necessiteOrdonnance: true,
  );

  final sampleOffer = PharmacyOffer(
    id: 'offer-1',
    pharmacyId: 'pharma-soleil',
    pharmacyName: 'Pharmacie du Soleil',
    quarter: 'Carrefour Warda',
    distanceKm: 0.4,
    phone: '+237 677 12 34 56',
    availabilityType: PharmacyAvailabilityType.fullyAvailable,
    quotedPriceCfa: 3100,
    submittedAt: DateTime(2026, 11, 10, 8, 0),
  );

  final sampleOrder = FlashOrder(
    id: 'ORD-12345',
    items: const [
      BasketItem(
        id: 'item-1',
        medication: sampleMedication,
        quantity: 2,
      ),
    ],
    quarter: 'Carrefour Warda, Poste Centrale',
    targets: const [],
    currentWave: 1,
    offers: [sampleOffer],
    status: FlashOrderStatus.offersReceived,
    createdAt: DateTime(2026, 11, 10, 8, 0),
    expiresAt: DateTime(2026, 11, 10, 10, 0),
  );

  final sampleReservation = Reservation(
    id: 'RES-999',
    clientReservationId: 'ORD-12345',
    pharmacyId: 'pharma-soleil',
    pharmacyName: 'Pharmacie du Soleil',
    medicationId: 'med-paracetamol',
    medicationName: 'Paracétamol 500 mg (x2)',
    quantite: 2,
    codeRetraitOtp: '849201',
    statut: ReservationStatus.confirmed,
    createdAt: DateTime(2026, 11, 10, 8, 5),
    expiresAt: DateTime(2026, 11, 10, 10, 5),
  );

  setUp(() {
    mockSubmitFlashRequestUseCase = MockSubmitFlashRequestUseCase();
    mockEscalateDispatchWaveUseCase = MockEscalateDispatchWaveUseCase();
    mockSelectPharmacyOfferUseCase = MockSelectPharmacyOfferUseCase();
    mockReservationRepository = MockReservationRepository();

    cubit = FlashReservationCubit(
      submitFlashRequestUseCase: mockSubmitFlashRequestUseCase,
      escalateDispatchWaveUseCase: mockEscalateDispatchWaveUseCase,
      selectPharmacyOfferUseCase: mockSelectPharmacyOfferUseCase,
      reservationRepository: mockReservationRepository,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('FlashReservationCubit - Initialisation et Panier', () {
    test('l\'état initial est conforme', () {
      expect(cubit.state.basketItems, isEmpty);
      expect(cubit.state.selectedLandmark, isNull);
      expect(cubit.state.currentOrder, isNull);
      expect(cubit.state.status, FlashReservationStatus.initial);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.confirmedReservation, isNull);
      expect(cubit.state.canSubmit, isFalse);
    });

    test('addItem ajoute un nouvel article et gère l\'ordonnance', () {
      cubit.addItem(sampleMedicationRx, quantity: 2, note: 'Prendre le soir');

      expect(cubit.state.basketItems.length, 1);
      final item = cubit.state.basketItems.first;
      expect(item.medication.id, 'med-amox');
      expect(item.quantity, 2);
      expect(item.hasPrescription, isTrue);
      expect(item.prescriptionNote, 'Prendre le soir');
      expect(cubit.state.totalItemCount, 2);
    });

    test('addItem incrémente la quantité si le médicament existe déjà', () {
      cubit
        ..addItem(sampleMedication, quantity: 1)
        ..addItem(sampleMedication, quantity: 3);

      expect(cubit.state.basketItems.length, 1);
      expect(cubit.state.basketItems.first.quantity, 4);
    });

    test('updateQuantity met à jour la quantité ou supprime si <= 0', () {
      cubit.addItem(sampleMedication, quantity: 2);
      final itemId = cubit.state.basketItems.first.id;

      cubit.updateQuantity(itemId, 5);
      expect(cubit.state.basketItems.first.quantity, 5);

      cubit.updateQuantity(itemId, 0);
      expect(cubit.state.basketItems, isEmpty);
    });

    test('updateNote modifie la précision associée à l\'article', () {
      cubit.addItem(sampleMedication, quantity: 1);
      final itemId = cubit.state.basketItems.first.id;

      cubit.updateNote(itemId, 'Gélules si possible');
      expect(cubit.state.basketItems.first.prescriptionNote, 'Gélules si possible');
    });

    test('removeItem supprime l\'article spécifié', () {
      cubit
        ..addItem(sampleMedication, quantity: 1)
        ..addItem(sampleMedicationRx, quantity: 1);

      expect(cubit.state.basketItems.length, 2);
      final firstItemId = cubit.state.basketItems.first.id;

      cubit.removeItem(firstItemId);
      expect(cubit.state.basketItems.length, 1);
      expect(cubit.state.basketItems.first.medication.id, 'med-amox');
    });

    test('selectLandmark définit le repère urbain', () {
      cubit.selectLandmark(sampleLandmark);
      expect(cubit.state.selectedLandmark, sampleLandmark);
    });
  });

  group('FlashReservationCubit - Soumission Flash', () {
    test('échoue si le panier est vide', () async {
      cubit.selectLandmark(sampleLandmark);
      await cubit.submitFlashRequest();

      expect(cubit.state.status, FlashReservationStatus.failure);
      expect(cubit.state.errorMessage, contains('panier'));
    });

    test('échoue si aucun repère urbain n\'est sélectionné', () async {
      cubit.addItem(sampleMedication, quantity: 1);
      await cubit.submitFlashRequest();

      expect(cubit.state.status, FlashReservationStatus.failure);
      expect(cubit.state.errorMessage, contains('repère'));
    });

    blocTest<FlashReservationCubit, FlashReservationState>(
      'émet [loading, offersReceived] lors d\'une soumission réussie avec offres',
      setUp: () {
        when(() => mockSubmitFlashRequestUseCase(
              items: any(named: 'items'),
              landmark: sampleLandmark,
            )).thenAnswer((_) async => Right(sampleOrder));
      },
      build: () => cubit,
      seed: () => const FlashReservationState(
        basketItems: [
          BasketItem(id: 'item-1', medication: sampleMedication, quantity: 2),
        ],
        selectedLandmark: sampleLandmark,
      ),
      act: (cubit) => cubit.submitFlashRequest(),
      expect: () => [
        const FlashReservationState(
          basketItems: [
            BasketItem(id: 'item-1', medication: sampleMedication, quantity: 2),
          ],
          selectedLandmark: sampleLandmark,
          status: FlashReservationStatus.loading,
        ),
        FlashReservationState(
          basketItems: const [
            BasketItem(id: 'item-1', medication: sampleMedication, quantity: 2),
          ],
          selectedLandmark: sampleLandmark,
          status: FlashReservationStatus.offersReceived,
          currentOrder: sampleOrder,
        ),
      ],
    );

    blocTest<FlashReservationCubit, FlashReservationState>(
      'émet [loading, failure] en cas d\'échec de soumission',
      setUp: () {
        when(() => mockSubmitFlashRequestUseCase(
              items: any(named: 'items'),
              landmark: sampleLandmark,
            )).thenAnswer((_) async => const Left(
              ServerFailure('Connexion réseau interrompue'),
            ));
      },
      build: () => cubit,
      seed: () => const FlashReservationState(
        basketItems: [
          BasketItem(id: 'item-1', medication: sampleMedication, quantity: 2),
        ],
        selectedLandmark: sampleLandmark,
      ),
      act: (cubit) => cubit.submitFlashRequest(),
      expect: () => [
        const FlashReservationState(
          basketItems: [
            BasketItem(id: 'item-1', medication: sampleMedication, quantity: 2),
          ],
          selectedLandmark: sampleLandmark,
          status: FlashReservationStatus.loading,
        ),
        const FlashReservationState(
          basketItems: [
            BasketItem(id: 'item-1', medication: sampleMedication, quantity: 2),
          ],
          selectedLandmark: sampleLandmark,
          status: FlashReservationStatus.failure,
          errorMessage: 'Connexion réseau interrompue',
        ),
      ],
    );
  });

  group('FlashReservationCubit - Escalade de Vague', () {
    test('échoue si aucune commande active', () async {
      await cubit.escalateWave();
      expect(cubit.state.status, FlashReservationStatus.failure);
      expect(cubit.state.errorMessage, contains('Aucune recherche active'));
    });

    blocTest<FlashReservationCubit, FlashReservationState>(
      'émet [loading, offersReceived] lors d\'une escalade réussie',
      setUp: () {
        when(() => mockEscalateDispatchWaveUseCase('ORD-12345'))
            .thenAnswer((_) async => Right(sampleOrder.copyWith(currentWave: 2)));
      },
      build: () => cubit,
      seed: () => FlashReservationState(
        currentOrder: sampleOrder,
        status: FlashReservationStatus.waveActive,
      ),
      act: (cubit) => cubit.escalateWave(),
      expect: () => [
        FlashReservationState(
          currentOrder: sampleOrder,
          status: FlashReservationStatus.loading,
        ),
        FlashReservationState(
          currentOrder: sampleOrder.copyWith(currentWave: 2),
          status: FlashReservationStatus.offersReceived,
        ),
      ],
    );
  });

  group('FlashReservationCubit - Sélection d\'offre et OTP', () {
    test('échoue si aucune commande en cours', () async {
      await cubit.selectOffer(sampleOffer, patientPhone: '699112233');
      expect(cubit.state.status, FlashReservationStatus.failure);
    });

    blocTest<FlashReservationCubit, FlashReservationState>(
      'émet [loading, reservationConfirmed] avec ticket OTP 6 chiffres',
      setUp: () {
        when(() => mockSelectPharmacyOfferUseCase(
              orderId: 'ORD-12345',
              offer: sampleOffer,
              patientPhone: '699112233',
            )).thenAnswer((_) async => Right(sampleReservation));
      },
      build: () => cubit,
      seed: () => FlashReservationState(
        currentOrder: sampleOrder,
        status: FlashReservationStatus.offersReceived,
      ),
      act: (cubit) => cubit.selectOffer(sampleOffer, patientPhone: '699112233'),
      expect: () => [
        FlashReservationState(
          currentOrder: sampleOrder,
          status: FlashReservationStatus.loading,
        ),
        FlashReservationState(
          currentOrder: sampleOrder.copyWith(selectedOffer: sampleOffer),
          status: FlashReservationStatus.reservationConfirmed,
          confirmedReservation: sampleReservation,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.confirmedReservation?.codeRetraitOtp, '849201');
        expect(cubit.state.confirmedReservation?.codeRetraitOtp.length, 6);
      },
    );
  });

  group('FlashReservationCubit - Rafraîchissement et Réinitialisation', () {
    blocTest<FlashReservationCubit, FlashReservationState>(
      'refreshFlashRequest met à jour currentOrder',
      setUp: () {
        when(() => mockReservationRepository.getFlashRequestById('ORD-12345'))
            .thenAnswer((_) async => Right(sampleOrder));
      },
      build: () => cubit,
      seed: () => FlashReservationState(
        currentOrder: sampleOrder,
        status: FlashReservationStatus.initial,
      ),
      act: (cubit) => cubit.refreshFlashRequest('ORD-12345'),
      expect: () => [
        FlashReservationState(
          currentOrder: sampleOrder,
          status: FlashReservationStatus.offersReceived,
        ),
      ],
    );

    test('reset réinitialise l\'état complètement', () {
      cubit
        ..addItem(sampleMedication, quantity: 2)
        ..selectLandmark(sampleLandmark)
        ..reset();

      expect(cubit.state.basketItems, isEmpty);
      expect(cubit.state.selectedLandmark, isNull);
      expect(cubit.state.status, FlashReservationStatus.initial);
    });
  });
}
