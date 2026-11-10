import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/pharmacist_request_inbox_card.dart';

void main() {
  const sampleMedication = Medication(
    id: 'med-clamoxyl-500',
    dci: 'Amoxicilline',
    nomCommercial: 'Clamoxyl 500mg',
    forme: 'Gélule',
    dosage: '500 mg',
    classeTherapeutique: 'Antibiotique',
    prixHomologueCfa: 2400,
    necessiteOrdonnance: true,
  );

  final sampleOrder = FlashOrder(
    id: 'ORD-777',
    items: const [
      BasketItem(
        id: 'item-1',
        medication: sampleMedication,
        quantity: 2,
        hasPrescription: true,
      ),
    ],
    quarter: 'Carrefour Warda, Yaoundé',
    targets: const [],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    waveTimeRemainingSeconds: 90,
    status: FlashOrderStatus.dispatchingWave,
  );

  Widget buildTestWidget({
    required FlashOrder order,
    bool isSelected = false,
    int? remainingSeconds,
    VoidCallback? onSelect,
    VoidCallback? onQuotePressed,
    VoidCallback? onValidateOtpPressed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PharmacistRequestInboxCard(
          order: order,
          isSelected: isSelected,
          remainingSeconds: remainingSeconds,
          onSelect: onSelect,
          onQuotePressed: onQuotePressed,
          onValidateOtpPressed: onValidateOtpPressed,
        ),
      ),
    );
  }

  testWidgets('affiche les informations de commande, médicaments et ordonnance', (tester) async {
    await tester.pumpWidget(buildTestWidget(order: sampleOrder));

    expect(find.text('#ORD-777'), findsOneWidget);
    expect(find.text('Carrefour Warda, Yaoundé'), findsOneWidget);
    expect(find.text('Clamoxyl 500mg (Qté : 2)'), findsOneWidget);
    expect(find.text('Ordonnance'), findsOneWidget);
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('déclenche le callback onSelect au clic sur la carte', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      buildTestWidget(
        order: sampleOrder,
        onSelect: () => selected = true,
      ),
    );

    await tester.tap(find.byType(PharmacistRequestInboxCard));
    await tester.pump();

    expect(selected, isTrue);
  });

  testWidgets('déclenche onQuotePressed au clic sur Émettre un devis', (tester) async {
    var quoteClicked = false;
    await tester.pumpWidget(
      buildTestWidget(
        order: sampleOrder,
        onQuotePressed: () => quoteClicked = true,
      ),
    );

    final btnFinder = find.byKey(const ValueKey('btn_quote_ORD-777'));
    expect(btnFinder, findsOneWidget);

    await tester.tap(btnFinder);
    await tester.pump();

    expect(quoteClicked, isTrue);
  });

  testWidgets('affiche le bouton Valider retrait OTP quand la commande est prête', (tester) async {
    var otpClicked = false;
    final readyOrder = sampleOrder.copyWith(
      status: FlashOrderStatus.readyForPickup,
      reservationOtpCode: '842915',
    );

    await tester.pumpWidget(
      buildTestWidget(
        order: readyOrder,
        onValidateOtpPressed: () => otpClicked = true,
      ),
    );

    final otpBtn = find.byKey(const ValueKey('btn_otp_ORD-777'));
    expect(otpBtn, findsOneWidget);

    await tester.tap(otpBtn);
    await tester.pump();

    expect(otpClicked, isTrue);
  });
}
