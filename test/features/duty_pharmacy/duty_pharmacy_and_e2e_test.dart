import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/duty_pharmacy/presentation/controllers/duty_pharmacy_cubit.dart';
import 'package:medmate/features/duty_pharmacy/presentation/views/duty_pharmacy_screen.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacist_portal/data/repositories/pharmacist_portal_repository_impl.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/data/repositories/reservation_repository_impl.dart';

void main() {
  group('DutyPharmacyCubit', () {
    test('état initial : Yaoundé, 4 plus proches', () {
      final cubit = DutyPharmacyCubit();
      expect(cubit.state.selectedCity, 'Yaoundé');
      expect(cubit.state.displayedPharmacies.length, 4);
    });

    test('filtre par quartier dans « Toutes les gardes »', () {
      final cubit = DutyPharmacyCubit()
        ..selectSegment(1)
        ..updateSearchQuery('bastos');
      expect(cubit.state.displayedPharmacies.length, 1);
      expect(cubit.state.displayedPharmacies.first.quarter, 'Bastos');
    });

    test('changement de ville recharge la liste', () async {
      final cubit = DutyPharmacyCubit();
      await cubit.selectCity('Douala');
      expect(cubit.state.selectedCity, 'Douala');
      expect(cubit.state.allCityPharmacies.every((p) => p.city == 'Douala'),
          isTrue,
      );
    });
  });

  for (final size in const [Size(390, 844), Size(1280, 800), Size(320, 568)]) {
    testWidgets('DutyPharmacyScreen sans overflow ${size.width}x${size.height}',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: DutyPharmacyScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Programme de garde'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('E2E : commande patient -> devis pharmacien -> OTP comptoir', () async {
    final shared = <String, FlashOrder>{};
    final patient = ReservationRepositoryImpl(sharedOrders: shared);
    final pharma = PharmacistPortalRepositoryImpl(sharedOrders: shared);

    const med = Medication(
      id: 'm1',
      dci: 'Paracétamol',
      nomCommercial: 'Efferalgan',
      forme: 'Comprimé',
      dosage: '500 mg',
      classeTherapeutique: 'Antalgique',
      prixHomologueCfa: 1200,
      necessiteOrdonnance: false,
    );
    final created = (await patient.submitFlashRequest(
      items: const [BasketItem(id: 'i1', medication: med, quantity: 1)],
      landmark: YaoundeLandmarks.list.first,
    ))
        .getOrElse((_) => throw StateError('échec'));

    final inbox =
        (await pharma.getPendingOrdersForPharmacy('pharma-soleil'))
            .getOrElse((_) => []);
    expect(inbox.any((o) => o.id == created.id), isTrue);

    await pharma.submitQuote(
      orderId: created.id,
      pharmacyId: 'pharma-soleil',
      availability: PharmacyAvailabilityType.fullyAvailable,
      quotedPriceCfa: 1500,
    );
    final refreshed = (await patient.getFlashRequestById(created.id))
        .getOrElse((_) => throw StateError('échec'));
    final offer =
        refreshed.offers.firstWhere((o) => o.pharmacyId == 'pharma-soleil');
    expect(offer.quotedPriceCfa, 1500);

    final reservation = (await patient.selectPharmacyOffer(
      orderId: created.id,
      offer: offer,
      patientPhone: '+237690000000',
    ))
        .getOrElse((_) => throw StateError('échec'));

    final delivered = await pharma.validateOtpAtCounter(
      orderId: created.id,
      pharmacyId: 'pharma-soleil',
      otpCode: reservation.codeRetraitOtp,
    );
    expect(delivered.isRight(), isTrue);
  });
}
