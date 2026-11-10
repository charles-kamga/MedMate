import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/core/config/app_config.dart';
import 'package:medmate/core/constants/yaounde_landmarks.dart';
import 'package:medmate/features/flash_order/domain/entities/basket_item.dart';
import 'package:medmate/features/pharmacy_search/domain/entities/medication.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_cubit.dart';
import 'package:medmate/features/pharmacy_search/presentation/controllers/medication_catalog_state.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_cubit.dart';
import 'package:medmate/features/reservation/presentation/controllers/flash_reservation_state.dart';
import 'package:medmate/features/reservation/presentation/widgets/patient_basket_composer_card.dart';
import 'package:mocktail/mocktail.dart';

class MockFlashReservationCubit extends MockCubit<FlashReservationState>
    implements FlashReservationCubit {}

class MockMedicationCatalogCubit extends MockCubit<MedicationCatalogState>
    implements MedicationCatalogCubit {}

void main() {
  late MockFlashReservationCubit mockFlashCubit;
  late MockMedicationCatalogCubit mockCatalogCubit;

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
    prixHomologueCfa: 2500,
    necessiteOrdonnance: true,
  );

  const sampleItem = BasketItem(
    id: 'item-1',
    medication: sampleMedication,
    quantity: 2,
    hasPrescription: false,
  );

  const sampleItemRx = BasketItem(
    id: 'item-2',
    medication: sampleMedicationRx,
    quantity: 1,
    hasPrescription: true,
  );

  setUp(() {
    mockFlashCubit = MockFlashReservationCubit();
    mockCatalogCubit = MockMedicationCatalogCubit();

    when(() => mockFlashCubit.state).thenReturn(const FlashReservationState());
    when(() => mockCatalogCubit.state).thenReturn(const MedicationCatalogInitial());
  });

  Widget buildTestableWidget({
    List<BasketItem>? basketItems,
    YaoundeLandmark? selectedLandmark,
    ValueChanged<Medication>? onAddMedication,
    ValueChanged<String>? onRemoveItem,
    void Function(String itemId, int newQuantity)? onUpdateQuantity,
    ValueChanged<YaoundeLandmark>? onSelectLandmark,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: MultiBlocProvider(
            providers: [
              BlocProvider<FlashReservationCubit>.value(value: mockFlashCubit),
              BlocProvider<MedicationCatalogCubit>.value(value: mockCatalogCubit),
            ],
            child: PatientBasketComposerCard(
              basketItems: basketItems,
              selectedLandmark: selectedLandmark,
              onAddMedication: onAddMedication,
              onRemoveItem: onRemoveItem,
              onUpdateQuantity: onUpdateQuantity,
              onSelectLandmark: onSelectLandmark,
              catalogCubit: mockCatalogCubit,
              flashCubit: mockFlashCubit,
            ),
          ),
        ),
      ),
    );
  }

  group('PatientBasketComposerCard Widget Tests', () {
    testWidgets('displays empty basket message and price policy notice', (tester) async {
      await tester.pumpWidget(buildTestableWidget(basketItems: const []));
      await tester.pumpAndSettle();

      expect(find.text("Votre panier est vide. Recherchez un médicament pour l'ajouter."), findsOneWidget);
      expect(find.text(AppConfig.pricePolicyNotice), findsOneWidget);
    });

    testWidgets('displays basket items with quantity and prescription badge', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          basketItems: [sampleItem, sampleItemRx],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paracétamol 500 mg'), findsOneWidget);
      expect(find.text('Amoxicilline 500 mg'), findsOneWidget);
      expect(find.text('Ordonnance requise'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Médicaments demandés (2)'), findsOneWidget);
    });

    testWidgets('triggers onUpdateQuantity when + or - is pressed', (tester) async {
      String? updatedId;
      int? updatedQuantity;

      await tester.pumpWidget(
        buildTestableWidget(
          basketItems: [sampleItem],
          onUpdateQuantity: (id, q) {
            updatedId = id;
            updatedQuantity = q;
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      expect(updatedId, equals('item-1'));
      expect(updatedQuantity, equals(3));

      await tester.tap(find.byIcon(Icons.remove_circle_outline));
      await tester.pumpAndSettle();

      expect(updatedId, equals('item-1'));
      expect(updatedQuantity, equals(1));
    });

    testWidgets('triggers onRemoveItem when delete icon is pressed', (tester) async {
      String? removedId;

      await tester.pumpWidget(
        buildTestableWidget(
          basketItems: [sampleItem],
          onRemoveItem: (id) => removedId = id,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(removedId, equals('item-1'));
    });

    testWidgets('shows autocomplete suggestions and triggers onAddMedication when tapped', (tester) async {
      when(() => mockCatalogCubit.state).thenReturn(const MedicationCatalogLoaded([sampleMedication]));
      when(() => mockCatalogCubit.search(any())).thenAnswer((_) async {});
      when(() => mockCatalogCubit.clear()).thenReturn(null);

      Medication? addedMed;

      await tester.pumpWidget(
        buildTestableWidget(
          onAddMedication: (m) => addedMed = m,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Para');
      await tester.pumpAndSettle();

      verify(() => mockCatalogCubit.search('Para')).called(1);

      expect(find.text('Paracétamol 500 mg'), findsOneWidget);
      await tester.tap(find.text('Paracétamol 500 mg'));
      await tester.pumpAndSettle();

      expect(addedMed, equals(sampleMedication));
    });
  });
}
