import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

void main() {
  group('HiGoPhoneInput', () {
    testWidgets('Displays Pakistan initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HiGoPhoneInput())),
      );

      expect(find.text('+92'), findsOneWidget);
      expect(find.byKey(const Key('higo_country_selector')), findsOneWidget);
      expect(find.byKey(const Key('higo_phone_number')), findsOneWidget);
    });

    testWidgets('Displays a custom initial country', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HiGoPhoneInput(initialCountry: IsoCode.GB)),
        ),
      );

      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets('Validates a correct US phone number', (tester) async {
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

      expect(result, isNotNull);
      expect(result!.isValid, true);
      expect(result!.countryCode, 'US');
      expect(result!.e164, '+14155552671');
    });

    testWidgets('Rejects an invalid phone number', (tester) async {
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

      await tester.enterText(find.byKey(const Key('higo_phone_number')), '123');

      await tester.pump();

      expect(result, isNotNull);
      expect(result!.isValid, false);
      expect(result!.e164, isNull);

      expect(find.text('Enter a valid phone number'), findsOneWidget);
    });

    testWidgets('Empty input is invalid after interaction', (tester) async {
      PhoneValidationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HiGoPhoneInput(
              onChanged: (value) {
                result = value;
              },
            ),
          ),
        ),
      );

      final phoneField = find.byKey(const Key('higo_phone_number'));

      await tester.enterText(phoneField, '123');
      await tester.pump();

      await tester.enterText(phoneField, '');
      await tester.pump();

      expect(result, isNotNull);
      expect(result!.isValid, false);
      expect(result!.e164, isNull);

      expect(find.text('Enter a valid phone number'), findsOneWidget);
    });

    testWidgets('Country selector opens bottom sheet', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HiGoPhoneInput())),
      );

      await tester.tap(find.byKey(const Key('higo_country_selector')));
      await tester.pumpAndSettle();

      expect(find.text('Select country'), findsOneWidget);

      expect(find.byKey(const Key('higo_country_search')), findsOneWidget);

      expect(find.byKey(const Key('higo_country_list')), findsOneWidget);
    });

    testWidgets('Search filters countries', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HiGoPhoneInput())),
      );

      await tester.tap(find.byKey(const Key('higo_country_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('higo_country_search')),
        'United Kingdom',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('higo_country_GB')), findsOneWidget);

      expect(find.byKey(const Key('higo_country_PK')), findsNothing);
    });

    testWidgets('Selecting country updates dial code and callback', (
      tester,
    ) async {
      PhoneValidationResult? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HiGoPhoneInput(
              onChanged: (value) {
                result = value;
              },
            ),
          ),
        ),
      );

      expect(find.text('+92'), findsOneWidget);

      await tester.tap(find.byKey(const Key('higo_country_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('higo_country_search')),
        'United States',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('higo_country_US')));
      await tester.pumpAndSettle();

      expect(find.text('+1'), findsOneWidget);
      expect(find.text('+92'), findsNothing);

      expect(result, isNotNull);
      expect(result!.countryCode, 'US');
      expect(result!.isValid, false);
    });

    testWidgets('Changing country revalidates phone number', (tester) async {
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

      expect(result!.isValid, true);
      expect(result!.countryCode, 'US');

      await tester.tap(find.byKey(const Key('higo_country_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('higo_country_search')),
        'Pakistan',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('higo_country_PK')));
      await tester.pumpAndSettle();

      expect(find.text('+92'), findsOneWidget);
      expect(result!.countryCode, 'PK');
      expect(result!.isValid, false);
      expect(result!.e164, isNull);
    });

    testWidgets('Dismissing bottom sheet preserves country', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HiGoPhoneInput())),
      );

      expect(find.text('+92'), findsOneWidget);

      await tester.tap(find.byKey(const Key('higo_country_selector')));
      await tester.pumpAndSettle();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('+92'), findsOneWidget);
      expect(find.text('Select country'), findsNothing);
    });

    testWidgets('Selected country survives parent rebuild', (tester) async {
      final notifier = ValueNotifier<int>(0);
      addTearDown(notifier.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<int>(
          valueListenable: notifier,
          builder: (context, count, child) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [Text('Rebuild: $count'), const HiGoPhoneInput()],
                ),
              ),
            );
          },
        ),
      );

      await tester.tap(find.byKey(const Key('higo_country_selector')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('higo_country_search')),
        'United Kingdom',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('higo_country_GB')));
      await tester.pumpAndSettle();

      expect(find.text('+44'), findsOneWidget);

      notifier.value++;
      await tester.pumpAndSettle();

      expect(find.text('+44'), findsOneWidget);
    });

    testWidgets('Disabled widget prevents input and selection', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HiGoPhoneInput(enabled: false))),
      );

      final phoneField = tester.widget<TextField>(
        find.byKey(const Key('higo_phone_number')),
      );

      // Phone input must be disabled.
      expect(phoneField.enabled, false);

      // Country selector must have no action.
      final selector = tester.widget<InkWell>(
        find.byKey(const Key('higo_country_selector')),
      );

      expect(selector.onTap, isNull);

      // Initial country must remain unchanged.
      expect(find.text('+92'), findsOneWidget);

      // The country selection sheet must not be visible.
      expect(find.text('Select country'), findsNothing);
    });
  });
}
