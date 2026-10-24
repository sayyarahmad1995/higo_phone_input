import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

void main() {
  testWidgets('Displays Pakistan initially', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HiGoPhoneInput())),
    );

    expect(find.text('PK'), findsOneWidget);
  });

  testWidgets('Validates a US phone number', (tester) async {
    PhoneValidationResult? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HiGoPhoneInput(
            initialCountry: IsoCode.US,
            onChanged: (value) {
              result = value;
            },
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('higo_phone_number')),
      '4155552671',
    );

    await tester.pump();

    expect(result?.isValid, true);
    expect(result?.e164, '+14155552671');
  });

  testWidgets('Country changes after selection', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HiGoPhoneInput())),
    );

    await tester.tap(find.byKey(const Key('higo_country_selector')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('US').last);
    await tester.pumpAndSettle();

    expect(find.text('US'), findsOneWidget);
  });

  testWidgets('Invalid phone produces an error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HiGoPhoneInput(initialCountry: IsoCode.US)),
      ),
    );

    await tester.enterText(find.byKey(const Key('higo_phone_number')), '123');

    await tester.pump();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
  });

  testWidgets('Preserves selected country after parent rebuild', (
    tester,
  ) async {
    final notifier = ValueNotifier<int>(0);
    addTearDown(notifier.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: notifier,
        builder: (context, value, child) {
          return MaterialApp(
            home: Scaffold(
              body: Column(
                children: [Text('Rebuild: $value'), const HiGoPhoneInput()],
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.byKey(const Key('higo_country_selector')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('US').last);
    await tester.pumpAndSettle();

    expect(find.text('US'), findsOneWidget);

    notifier.value++;
    await tester.pumpAndSettle();

    expect(find.text('US'), findsOneWidget);
  });
}
