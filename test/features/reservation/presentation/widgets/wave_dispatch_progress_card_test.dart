import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/reservation/presentation/widgets/wave_dispatch_progress_card.dart';

void main() {
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

  final sampleOrder = FlashOrder(
    id: 'order-123',
    items: [
      BasketItem(
        id: 'item-1',
        medication: sampleMedication,
        quantity: 2,
      ),
    ],
    quarter: 'Carrefour Warda',
    currentWave: 1,
    waveTimeRemainingSeconds: 90,
    targets: const [
      DispatchedPharmacy(
        id: 'pharma-1',
        name: 'Pharmacie du Centre',
        quarter: 'Poste Centrale',
        distanceKm: 0.8,
        phone: '+237690000001',
        waveIndex: 1,
        status: PharmacistReplyType.waiting,
      ),
      DispatchedPharmacy(
        id: 'pharma-2',
        name: 'Pharmacie Warda Bastos',
        quarter: 'Bastos',
        distanceKm: 1.2,
        phone: '+237690000002',
        waveIndex: 1,
        status: PharmacistReplyType.available,
      ),
    ],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
  );

  Widget buildTestableWidget({
    FlashOrder? order,
    VoidCallback? onEscalate,
    bool isLoading = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WaveDispatchProgressCard(
            order: order,
            onEscalate: onEscalate,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }

  group('WaveDispatchProgressCard Widget Tests', () {
    testWidgets('displays empty state when order is null', (tester) async {
      await tester.pumpWidget(buildTestableWidget(order: null));
      await tester.pumpAndSettle();

      expect(find.text('Aucune recherche flash en cours.'), findsOneWidget);
    });

    testWidgets('displays active wave, round robin badge and targets', (tester) async {
      await tester.pumpWidget(buildTestableWidget(order: sampleOrder));
      await tester.pumpAndSettle();

      expect(find.text('Vague 1 active'), findsOneWidget);
      expect(find.text('Round-Robin 2 officines'), findsOneWidget);
      expect(find.text('Repère urbain : Carrefour Warda'), findsOneWidget);
      expect(find.text('Pharmacie du Centre'), findsOneWidget);
      expect(find.text('Pharmacie Warda Bastos'), findsOneWidget);
      expect(find.text('En attente...'), findsOneWidget);
      expect(find.text('Offre reçue'), findsOneWidget);
      expect(find.text('Solliciter 2 pharmacies de plus (Vague 2)'), findsOneWidget);
    });

    testWidgets('triggers onEscalate when button is tapped', (tester) async {
      var escalated = false;
      await tester.pumpWidget(
        buildTestableWidget(
          order: sampleOrder,
          onEscalate: () => escalated = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Solliciter 2 pharmacies de plus (Vague 2)'));
      await tester.pumpAndSettle();

      expect(escalated, isTrue);
    });

    testWidgets('shows loading spinner when isLoading is true and disables tap', (tester) async {
      var escalated = false;
      await tester.pumpWidget(
        buildTestableWidget(
          order: sampleOrder,
          onEscalate: () => escalated = true,
          isLoading: true,
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(escalated, isFalse);
    });
  });
}
