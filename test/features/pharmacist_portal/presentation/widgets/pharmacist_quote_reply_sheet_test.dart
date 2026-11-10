import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_state.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/pharmacist_quote_reply_sheet.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistCounterCubit extends MockCubit<PharmacistCounterState>
    implements PharmacistCounterCubit {}

void main() {
  late MockPharmacistCounterCubit mockCubit;

  setUpAll(() {
    registerFallbackValue(PharmacyAvailabilityType.fullyAvailable);
  });

  setUp(() {
    mockCubit = MockPharmacistCounterCubit();
    when(() => mockCubit.state).thenReturn(const PharmacistCounterState());
  });

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
    id: 'ORD-888',
    items: const [
      BasketItem(
        id: 'item-1',
        medication: sampleMedication,
        quantity: 1,
        hasPrescription: true,
      ),
    ],
    quarter: 'Carrefour Obili, Yaoundé',
    targets: const [],
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(minutes: 2)),
    status: FlashOrderStatus.dispatchingWave,
  );

  Widget buildTestWidget({
    required FlashOrder order,
    required String pharmacyId,
    VoidCallback? onQuoteSubmitted,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<PharmacistCounterCubit>.value(
          value: mockCubit,
          child: PharmacistQuoteReplySheet(
            order: order,
            pharmacyId: pharmacyId,
            isEmbedded: true,
            onQuoteSubmitted: onQuoteSubmitted,
          ),
        ),
      ),
    );
  }

  testWidgets('affiche les 3 statuts ONPC et valide la saisie d\'un prix disponible', (tester) async {
    when(() => mockCubit.submitQuote(
          orderId: any(named: 'orderId'),
          pharmacyId: any(named: 'pharmacyId'),
          availability: any(named: 'availability'),
          quotedPriceCfa: any(named: 'quotedPriceCfa'),
          conditionRequirements: any(named: 'conditionRequirements'),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: any(named: 'proposesDelivery'),
          deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
          estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildTestWidget(order: sampleOrder, pharmacyId: 'pharma-soleil'),
    );

    expect(find.text('Disponible'), findsOneWidget);
    expect(find.text('Sous conditions'), findsOneWidget);
    expect(find.text('Indisponible'), findsOneWidget);

    // Saisie du prix
    final priceInput = find.byKey(const ValueKey('input_quoted_price'));
    expect(priceInput, findsOneWidget);
    await tester.enterText(priceInput, '3500');
    await tester.pump();

    // Soumission
    final submitBtn = find.byKey(const ValueKey('btn_submit_counter_quote'));
    expect(submitBtn, findsOneWidget);
    await tester.tap(submitBtn);
    await tester.pump();

    verify(() => mockCubit.submitQuote(
          orderId: 'ORD-888',
          pharmacyId: 'pharma-soleil',
          availability: PharmacyAvailabilityType.fullyAvailable,
          quotedPriceCfa: 3500,
          conditionRequirements: any(named: 'conditionRequirements'),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: false,
          deliveryFeeCfa: 0,
          estimatedDeliveryMinutes: null,
        )).called(1);
  });

  testWidgets('bascule en Indisponible avec prix 0 FCFA', (tester) async {
    when(() => mockCubit.submitQuote(
          orderId: any(named: 'orderId'),
          pharmacyId: any(named: 'pharmacyId'),
          availability: any(named: 'availability'),
          quotedPriceCfa: any(named: 'quotedPriceCfa'),
          conditionRequirements: any(named: 'conditionRequirements'),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: any(named: 'proposesDelivery'),
          deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
          estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildTestWidget(order: sampleOrder, pharmacyId: 'pharma-soleil'),
    );

    // Clic sur l'onglet Indisponible
    await tester.tap(find.text('Indisponible'));
    await tester.pumpAndSettle();

    // Le champ de prix doit disparaître
    expect(find.byKey(const ValueKey('input_quoted_price')), findsNothing);

    // Soumission de l'indisponibilité
    final submitBtn = find.byKey(const ValueKey('btn_submit_counter_quote'));
    await tester.tap(submitBtn);
    await tester.pump();

    verify(() => mockCubit.submitQuote(
          orderId: 'ORD-888',
          pharmacyId: 'pharma-soleil',
          availability: PharmacyAvailabilityType.unavailable,
          quotedPriceCfa: 0,
          conditionRequirements: any(named: 'conditionRequirements'),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: false,
          deliveryFeeCfa: 0,
          estimatedDeliveryMinutes: null,
        )).called(1);
  });
}
