import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_cubit.dart';
import 'package:medmate/features/pharmacist_portal/presentation/controllers/pharmacist_counter_state.dart';
import 'package:medmate/features/pharmacist_portal/presentation/widgets/counter_otp_validation_keypad.dart';
import 'package:mocktail/mocktail.dart';

class MockPharmacistCounterCubit extends MockCubit<PharmacistCounterState>
    implements PharmacistCounterCubit {}

void main() {
  late MockPharmacistCounterCubit mockCubit;

  setUp(() {
    mockCubit = MockPharmacistCounterCubit();
    when(() => mockCubit.state).thenReturn(const PharmacistCounterState());
  });

  Widget buildTestWidget({
    required String orderId,
    required String pharmacyId,
    VoidCallback? onSuccess,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<PharmacistCounterCubit>.value(
          value: mockCubit,
          child: CounterOtpValidationKeypad(
            orderId: orderId,
            pharmacyId: pharmacyId,
            onSuccess: onSuccess,
          ),
        ),
      ),
    );
  }

  testWidgets('saisie des 6 chiffres au clavier tactile et activation du bouton de validation',
      (tester) async {
    when(() => mockCubit.validateOtpAtCounter(
          orderId: any(named: 'orderId'),
          pharmacyId: any(named: 'pharmacyId'),
          otpCode: any(named: 'otpCode'),
        )).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildTestWidget(orderId: 'ORD-999', pharmacyId: 'pharma-soleil'),
    );

    // Initialement, le bouton est désactivé
    final submitBtn = find.byKey(const ValueKey('btn_confirm_counter_otp'));
    expect(submitBtn, findsOneWidget);
    var buttonWidget = tester.widget<ElevatedButton>(submitBtn);
    expect(buttonWidget.onPressed, isNull);

    // Saisie de 6 chiffres : 8, 4, 2, 9, 1, 5
    for (final digit in ['8', '4', '2', '9', '1', '5']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }

    // Le bouton doit être activé
    buttonWidget = tester.widget<ElevatedButton>(submitBtn);
    expect(buttonWidget.onPressed, isNotNull);

    // Clic pour valider
    await tester.tap(submitBtn);
    await tester.pump();

    verify(() => mockCubit.validateOtpAtCounter(
          orderId: 'ORD-999',
          pharmacyId: 'pharma-soleil',
          otpCode: '842915',
        )).called(1);
  });

  testWidgets('fonctionnement des touches retour arrière et effacer', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(orderId: 'ORD-999', pharmacyId: 'pharma-soleil'),
    );

    // Taper '1', '2'
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.tap(find.text('2'));
    await tester.pump();

    // Touche backspace
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump();

    // Touche Clear 'C'
    await tester.tap(find.text('C'));
    await tester.pump();

    final submitBtn = find.byKey(const ValueKey('btn_confirm_counter_otp'));
    final buttonWidget = tester.widget<ElevatedButton>(submitBtn);
    expect(buttonWidget.onPressed, isNull);
  });

  testWidgets('affiche un retour visuel émeraude en cas de succès OTP', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const PharmacistCounterState(
        status: PharmacistCounterStatus.otpSuccess,
        successMessage: 'Code OTP validé. Médicaments remis au patient.',
      ),
    );

    await tester.pumpWidget(
      buildTestWidget(orderId: 'ORD-999', pharmacyId: 'pharma-soleil'),
    );

    expect(find.text('Code OTP validé. Médicaments remis au patient.'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('affiche une alerte rouge en cas de code OTP expiré ou erroné', (tester) async {
    when(() => mockCubit.state).thenReturn(
      const PharmacistCounterState(
        status: PharmacistCounterStatus.failure,
        errorMessage: 'Ce code de retrait a expiré (validité max 2 heures).',
      ),
    );

    await tester.pumpWidget(
      buildTestWidget(orderId: 'ORD-999', pharmacyId: 'pharma-soleil'),
    );

    expect(
      find.text('Ce code de retrait a expiré (validité max 2 heures).'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
