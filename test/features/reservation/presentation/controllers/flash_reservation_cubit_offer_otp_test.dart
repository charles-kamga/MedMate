import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
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

class _MockSubmitFlashRequestUseCase extends Mock
    implements SubmitFlashRequestUseCase {}

class _MockEscalateDispatchWaveUseCase extends Mock
    implements EscalateDispatchWaveUseCase {}

class _MockSelectPharmacyOfferUseCase extends Mock
    implements SelectPharmacyOfferUseCase {}

class _MockReservationRepository extends Mock
    implements ReservationRepository {}

void main() {
  late _MockSubmitFlashRequestUseCase mockSubmitFlashRequestUseCase;
  late _MockEscalateDispatchWaveUseCase mockEscalateDispatchWaveUseCase;
  late _MockSelectPharmacyOfferUseCase mockSelectPharmacyOfferUseCase;
  late _MockReservationRepository mockReservationRepository;
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
    mockSubmitFlashRequestUseCase = _MockSubmitFlashRequestUseCase();
    mockEscalateDispatchWaveUseCase = _MockEscalateDispatchWaveUseCase();
    mockSelectPharmacyOfferUseCase = _MockSelectPharmacyOfferUseCase();
    mockReservationRepository = _MockReservationRepository();

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

  group('FlashReservationCubit - Escalade de Vague', () {
    test('échoue si aucune commande active', () async {
      await cubit.escalateWave();
      expect(cubit.state.status, FlashReservationStatus.failure);
      expect(cubit.state.errorMessage, contains('Aucune recherche active'));
    });

    blocTest<FlashReservationCubit, FlashReservationState>(
      "émet [loading, offersReceived] lors d'une escalade réussie",
      setUp: () {
        when(() => mockEscalateDispatchWaveUseCase('ORD-12345')).thenAnswer(
          (_) async => Right(sampleOrder.copyWith(currentWave: 2)),
        );
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

  group("FlashReservationCubit - Sélection d'offre et OTP", () {
    test('échoue si aucune commande en cours', () async {
      await cubit.selectOffer(sampleOffer, patientPhone: '699112233');
      expect(cubit.state.status, FlashReservationStatus.failure);
    });

    blocTest<FlashReservationCubit, FlashReservationState>(
      'émet [loading, reservationConfirmed] avec ticket OTP 6 chiffres',
      setUp: () {
        when(
          () => mockSelectPharmacyOfferUseCase(
            orderId: 'ORD-12345',
            offer: sampleOffer,
            patientPhone: '699112233',
          ),
        ).thenAnswer((_) async => Right(sampleReservation));
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

    test("reset réinitialise l'état complètement", () {
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
