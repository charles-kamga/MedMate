import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/duty_pharmacy/data/repositories/duty_pharmacy_repository_impl.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/flash_order/domain/entities/flash_order.dart';
import 'package:medmate/features/flash_order/domain/entities/pharmacy_offer.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_state.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/pharmacist_quote_reply_sheet.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistCounterCubit extends MockCubit<PharmacistCounterState>
    implements PharmacistCounterCubit {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(PharmacyAvailabilityType.fullyAvailable);
  });

  const sampleMedication = Medication(
    id: 'med-doliprane',
    nomCommercial: 'Doliprane 1000mg',
    dci: 'Paracétamol',
    forme: 'Comprimé',
    dosage: '1000mg',
    classeTherapeutique: 'Antalgique',
    prixHomologueCfa: 1500,
    necessiteOrdonnance: false,
  );

  final sampleOrder = FlashOrder(
    id: 'ORD-TEST-V1',
    items: const [
      BasketItem(id: 'item-1', medication: sampleMedication, quantity: 1),
    ],
    quarter: 'Melen, Yaoundé 3e',
    targets: const [
      DispatchedPharmacy(
        id: 'pharma-mandela',
        name: 'Pharmacie Mandela Face CHU',
        quarter: 'Melen / Face CHU',
        distanceKm: 0.5,
        phone: '+237242792985',
        waveIndex: 1,
      ),
    ],
    currentWave: 1,
    waveTimeRemainingSeconds: 90,
    offers: const [],
    status: FlashOrderStatus.dispatchingWave,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(hours: 2)),
  );

  group('Afya-Health V1 — Configuration, Constantes & Données Pilotes', () {
    test('Identité de marque & drapeaux V1 validés', () {
      expect(AppConfig.appName, 'Afya-Health');
      expect(AppConfig.appTagline, 'La santé, avec clarté.');
      expect(AppConfig.pricePolicyNotice, contains('Afya-Health'));
      expect(AppConfig.enableDeliveryInV1, isFalse);
      expect(AppConfig.enableInAppPaymentInV1, isFalse);
      expect(AppConfig.clientSupportPhone, '+237 656 63 25 01');
      expect(AppConfig.pharmacySupportPhone, contains('+237 659 80 58 04'));
      expect(AppConfig.officialEmail, 'deanstephan06.tf@gmail.com');
    });

    test('Repères géographiques de la zone pilote Yaoundé Melen / Ngoa-Ekellé',
        () {
      final melen = YaoundeLandmarks.list
          .firstWhere((l) => l.id == 'carrefour-melen-chu');
      expect(melen.nom, 'Carrefour Melen / CHU');
      expect(melen.latitude, closeTo(3.8539, 0.001));
      expect(melen.longitude, closeTo(11.4870, 0.001));

      final polytech =
          YaoundeLandmarks.list.firstWhere((l) => l.id == 'ngoa-ekelle-ensp');
      expect(polytech.nom, contains('ENSP'));
      expect(polytech.latitude, closeTo(3.8622, 0.001));
      expect(polytech.longitude, closeTo(11.5003, 0.001));
    });

    test(
        'Référentiel des pharmacies de garde inclut les officines MboaPHARMA pilotes',
        () async {
      const repo = DutyPharmacyRepositoryImpl();
      final result = await repo.getDutyPharmacies(city: 'Yaoundé');
      expect(result.isRight(), isTrue);

      final pharmacies = result.getOrElse((_) => []);
      expect(pharmacies.any((p) => p.name.contains('Mandela')), isTrue);
      expect(pharmacies.any((p) => p.name.contains('Acacias')), isTrue);
      expect(pharmacies.any((p) => p.name.contains('Well')), isTrue);
      expect(pharmacies.any((p) => p.name.contains('Nsimeyong')), isTrue);
      expect(pharmacies.any((p) => p.quarter == 'Bastos'), isTrue);
    });
  });

  group('Afya-Health V1 — PharmacistQuoteReplySheet', () {
    late MockPharmacistCounterCubit mockCounterCubit;

    setUp(() {
      mockCounterCubit = MockPharmacistCounterCubit();
      when(() => mockCounterCubit.state)
          .thenReturn(const PharmacistCounterState());
    });

    testWidgets(
        'affiche bandeau V1 retrait comptoir quand enableDeliveryOption = false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PharmacistCounterCubit>.value(
              value: mockCounterCubit,
              child: PharmacistQuoteReplySheet(
                order: sampleOrder,
                pharmacyId: 'pharma-mandela',
                enableDeliveryOption: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Retrait au comptoir uniquement (V1) · Paiement sur place',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('switch_mototaxi')), findsNothing);
    });

    testWidgets('affiche switch mototaxi quand enableDeliveryOption = true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PharmacistCounterCubit>.value(
              value: mockCounterCubit,
              child: PharmacistQuoteReplySheet(
                order: sampleOrder,
                pharmacyId: 'pharma-mandela',
                enableDeliveryOption: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('switch_mototaxi')), findsOneWidget);
    });

    testWidgets('case majorité requise sous conditions transmise au devis',
        (tester) async {
      when(
        () => mockCounterCubit.submitQuote(
          orderId: any(named: 'orderId'),
          pharmacyId: any(named: 'pharmacyId'),
          availability: any(named: 'availability'),
          quotedPriceCfa: any(named: 'quotedPriceCfa'),
          conditionRequirements: any(named: 'conditionRequirements'),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: any(named: 'proposesDelivery'),
          deliveryFeeCfa: any(named: 'deliveryFeeCfa'),
          estimatedDeliveryMinutes: any(named: 'estimatedDeliveryMinutes'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<PharmacistCounterCubit>.value(
              value: mockCounterCubit,
              child: PharmacistQuoteReplySheet(
                order: sampleOrder,
                pharmacyId: 'pharma-mandela',
                enableDeliveryOption: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clic onglet Sous conditions
      await tester.tap(find.text('Sous conditions'));
      await tester.pumpAndSettle();

      // Coche majorité requise
      final majorityCheckbox = find.text("Pièce d'identité / Majorité requise");
      expect(majorityCheckbox, findsOneWidget);
      await tester.tap(majorityCheckbox);
      await tester.pumpAndSettle();

      // Saisie prix
      await tester.enterText(
        find.byKey(const ValueKey('input_quoted_price')),
        '4200',
      );
      await tester.pump();

      // Soumission
      await tester.tap(find.byKey(const ValueKey('btn_submit_counter_quote')));
      await tester.pump();

      verify(
        () => mockCounterCubit.submitQuote(
          orderId: 'ORD-TEST-V1',
          pharmacyId: 'pharma-mandela',
          availability: PharmacyAvailabilityType.conditional,
          quotedPriceCfa: 4200,
          conditionRequirements: any(
            named: 'conditionRequirements',
            that: contains("Pièce d'identité / Majorité requise"),
          ),
          conditionNote: any(named: 'conditionNote'),
          proposesDelivery: false,
          deliveryFeeCfa: 0,
          estimatedDeliveryMinutes: null,
        ),
      ).called(1);
    });
  });
}
