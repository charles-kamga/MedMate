import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/reservation.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';
import 'package:medmate/features/reservation/presentation/widgets/reservation_otp_ticket_card.dart';
import 'package:mocktail/mocktail.dart';

class MockFlashReservationCubit extends MockCubit<FlashReservationState>
    implements FlashReservationCubit {}

void main() {
  final now = DateTime.now();

  final sampleReservation = Reservation(
    id: 'RES-TEST-001',
    clientReservationId: 'ORD-TEST-001',
    pharmacyId: 'pharma-melen-8',
    pharmacyName: 'Pharmacie Melen 8',
    medicationId: 'med-doliprane-1000',
    medicationName: 'Doliprane 1000mg',
    quantite: 2,
    codeRetraitOtp: '123456',
    statut: ReservationStatus.confirmed,
    createdAt: now,
    expiresAt: now.add(const Duration(hours: 2)),
  );

  Widget buildWidget({
    required Reservation reservation,
    FlashOrder? order,
    FlashReservationCubit? cubit,
    VoidCallback? onCancel,
    void Function(String)? onCallPharmacy,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReservationOtpTicketCard(
            reservation: reservation,
            order: order,
            cubit: cubit,
            onCancel: onCancel,
            onCallPharmacy: onCallPharmacy,
          ),
        ),
      ),
    );
  }

  group(
      'ReservationOtpTicketCard — Fallback Téléphone & Confirmation Annulation',
      () {
    testWidgets(
        'affiche « Numéro non communiqué » et désactive le bouton appeler si téléphone vide',
        (tester) async {
      final orderWithEmptyPhone = FlashOrder(
        id: 'ORD-TEST-001',
        items: const [],
        quarter: 'Melen',
        targets: const [],
        selectedOffer: PharmacyOffer(
          id: 'OFFER-001',
          pharmacyId: 'pharma-melen-8',
          pharmacyName: 'Pharmacie Melen 8',
          quarter: 'Melen',
          distanceKm: 0.7,
          phone: '', // Téléphone vide
          availabilityType: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 2000,
          submittedAt: now,
        ),
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        buildWidget(
          reservation: sampleReservation,
          order: orderWithEmptyPhone,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Numéro non communiqué'), findsOneWidget);

      final callBtn = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey('btn_call_pharmacy')),
      );
      expect(callBtn.onPressed, isNull);
    });

    testWidgets(
        'affiche le numéro et active le bouton appeler lorsque téléphone présent',
        (tester) async {
      var callTriggeredWith = '';

      final orderWithPhone = FlashOrder(
        id: 'ORD-TEST-002',
        items: const [],
        quarter: 'Face CHU',
        targets: const [],
        selectedOffer: PharmacyOffer(
          id: 'OFFER-002',
          pharmacyId: 'pharma-mandela',
          pharmacyName: 'Pharmacie Mandela Face CHU',
          quarter: 'Face CHU',
          distanceKm: 0.5,
          phone: '+237 242 79 29 85',
          availabilityType: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 3500,
          submittedAt: now,
        ),
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 2)),
      );

      await tester.pumpWidget(
        buildWidget(
          reservation: sampleReservation,
          order: orderWithPhone,
          onCallPharmacy: (p) => callTriggeredWith = p,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('+237 242 79 29 85'), findsOneWidget);

      final callBtnFinder = find.byKey(const ValueKey('btn_call_pharmacy'));
      await tester.ensureVisible(callBtnFinder);
      await tester.tap(callBtnFinder);
      await tester.pumpAndSettle();

      expect(callTriggeredWith, equals('+237 242 79 29 85'));
    });

    testWidgets(
        'dialogue de confirmation d’annulation : Non conserve, Oui appelle cancelReservation',
        (tester) async {
      final mockCubit = MockFlashReservationCubit();
      when(() => mockCubit.state).thenReturn(const FlashReservationState());
      when(mockCubit.cancelReservation).thenAnswer((_) async {});

      await tester.pumpWidget(
        buildWidget(
          reservation: sampleReservation,
          cubit: mockCubit,
        ),
      );
      await tester.pumpAndSettle();

      final cancelBtn = find.byKey(const ValueKey('btn_cancel_reservation'));
      await tester.ensureVisible(cancelBtn);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Êtes-vous sûr de vouloir annuler votre demande ? Les pharmacies ciblées seront prévenues.',
        ),
        findsOneWidget,
      );
      expect(find.text('Non, conserver'), findsOneWidget);
      expect(find.text('Oui, annuler'), findsOneWidget);

      await tester.tap(find.text('Non, conserver'));
      await tester.pumpAndSettle();

      verifyNever(mockCubit.cancelReservation);

      // Nouvelle ouverture et confirmation via « Oui, annuler »
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Oui, annuler'));
      await tester.pumpAndSettle();

      verify(mockCubit.cancelReservation).called(1);
    });
  });
}
