# HiGO Phone Input

A customizable international phone input widget for Flutter, with a searchable country selector, country-aware validation, and E.164 output.

The package uses standard Flutter Material widgets, `phone_numbers_parser` for parsing and validation, and `locale_names` for English country display names.

## Features

- A unified phone number field with an integrated country selector, flag, dialing prefix, and dropdown.
- Searchable country bottom sheet: search by English country name, two-letter ISO code, or dialing prefix.
- Country search automatically receives focus when the selector opens; the keyboard stays open while browsing and scrolling.
- The country list includes keyboard-aware scroll space so the final country can be brought above the keyboard.
- Pull down from the top of the list to drag the sheet; on release, it closes after a downward pull of at least 20% of its initial height and otherwise returns to expanded height.
- The phone input label animates from inside the empty, unfocused field to the upper-left outline when focused or populated, and returns when empty and unfocused.
- Country-aware validation, with mobile-number-only validation enabled by default.
- Normalized E.164 output for valid phone numbers.
- Optional input decoration, text styles, search-box decoration, cursor color, autofocus, keyboard action, and flag visibility.
- Selected country is retained through ordinary parent rebuilds.

## Installation

Add the package to your Flutter application's `pubspec.yaml`:

```yaml
dependencies:
  higo_phone_input:
    git:
      url: https://github.com/sayyarahmad1995/higo_phone_input.git
      ref: main
```

Then run:

```sh
flutter pub get
```

For reproducible builds, replace `main` with a tested commit SHA or release tag.

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

class PhonePage extends StatelessWidget {
  const PhonePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: _PhoneInputDemo(),
      ),
    );
  }
}

class _PhoneInputDemo extends StatefulWidget {
  const _PhoneInputDemo();

  @override
  State<_PhoneInputDemo> createState() => _PhoneInputDemoState();
}

class _PhoneInputDemoState extends State<_PhoneInputDemo> {
  PhoneValidationResult? result;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HiGoPhoneInput(
          onChanged: (value) => setState(() => result = value),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: result?.isValid == true
              ? () {
                  final e164 = result!.e164!;
                  debugPrint('Valid number: $e164');
                }
              : null,
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
```

`onChanged` is invoked after phone text edits and country changes. It is **not** automatically called on the widget's initial build. The example disables submission until a valid result is received.

## Widget parameters

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `initialCountry` | `IsoCode` | `IsoCode.PK` | Initial selected country. |
| `initialNumber` | `String` | `''` | Initial phone number text. |
| `mobileOnly` | `bool` | `true` | Require a valid mobile number; `false` allows any valid supported number type. |
| `validateOnChange` | `bool` | `true` | Show inline errors after user interaction when the number is invalid. Validation and callbacks still run when `false`. |
| `enabled` | `bool` | `true` | Enable/disable both the phone field and country selector. |
| `labelText` | `String` | `'Phone number'` | Default field label. |
| `hintText` | `String` | `'Enter phone number'` | Default placeholder. |
| `decoration` | `InputDecoration?` | `null` | Flutter input decoration. Defaults to an outlined field; the integrated country selector and validation error are managed by the package. |
| `textStyle` | `TextStyle?` | `null` | Phone number text style. |
| `countrySelectorTextStyle` | `TextStyle?` | `null` | Dialing-prefix text style (not the flag or dropdown icon). |
| `searchBoxDecoration` | `InputDecoration?` | `null` | Decoration for the bottom sheet search field. |
| `cursorColor` | `Color?` | `null` | Phone field cursor color. |
| `autofocus` | `bool` | `false` | Automatically focus the **phone field** when built. Country search already focuses on opening the selector. |
| `textInputAction` | `TextInputAction` | `TextInputAction.done` | Phone keyboard action. |
| `showCountryFlag` | `bool` | `true` | Show/hide the flag in the main input prefix. Country flags remain visible in the picker. |
| `onChanged` | `ValueChanged<PhoneValidationResult>?` | `null` | Receives validation results when the number or selected country changes. |

### Country selection and initial values

The initial country defaults to Pakistan (`PK`, `+92`). Use `IsoCode` from `phone_numbers_parser` for another initial country:

```dart
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

HiGoPhoneInput(
  initialCountry: IsoCode.US,
  initialNumber: '4155552671',
  onChanged: (result) {
    // Handle edits and country changes.
  },
)
```

If your application imports `IsoCode` directly, declare `phone_numbers_parser` as a direct dependency. Changing `initialCountry` or `initialNumber` on a later widget update updates those values; ordinary parent rebuilds do not reset the user's selection.

## Customization

Use standard Material `InputDecoration` and `TextStyle` objects rather than package-specific color and border options.

```dart
HiGoPhoneInput(
  labelText: 'Mobile',
  hintText: 'Enter mobile number',
  showCountryFlag: false,
  cursorColor: Colors.teal,
  textStyle: const TextStyle(fontSize: 16),
  countrySelectorTextStyle: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  ),
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.teal.shade50,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 16,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.teal),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.teal, width: 2),
    ),
  ),
  searchBoxDecoration: const InputDecoration(
    hintText: 'Search by country or prefix',
    border: OutlineInputBorder(),
  ),
  onChanged: (result) {},
)
```

**Decoration precedence:** `decoration.labelText` and `decoration.hintText` take precedence over the corresponding widget strings; a supplied `label`/`hint` widget also takes precedence. The package installs the country selector as `prefixIcon` (and clears `prefix`), uses `FloatingLabelBehavior.auto` with `FloatingLabelAlignment.start` for the native floating-label animation, and sets the default outline border when no border is supplied. On an invalid, interacted-with input, the package sets `errorText` to `Enter a valid phone number` when `validateOnChange` is true. A custom `decoration.errorText` can still display an error in other states, so generally leave it unset.

## Validation result

`onChanged` receives a `PhoneValidationResult`:

| Property | Type | Meaning |
| --- | --- | --- |
| `input` | `String` | Raw input text supplied to validation. |
| `countryCode` | `String` | Selected country's two-letter ISO code, e.g. `PK`. |
| `e164` | `String?` | International number such as `+923111234567`, or `null` if invalid. |
| `isValid` | `bool` | Whether the number meets the chosen validation mode. |

An empty number is invalid. With `mobileOnly: true`, numbers must pass the parser's mobile-number validation; `mobileOnly: false` checks general phone-number validity. Metadata-based validation does **not** prove that a number is active or reachable.

### Validate without the widget

The public API also exports `PhoneValidationService`:

```dart
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

const validator = PhoneValidationService();
final result = validator.validate(
  input: '3111234567',
  country: IsoCode.PK,
);

if (result.isValid) {
  print(result.e164); // +923111234567
}
```

## Country selector behavior

- Opens a searchable modal bottom sheet.
- Search matches English country names, ISO codes (`PK`, `US`, `GB`) and dialing prefixes (`+92`, `+1`).
- The search field receives keyboard focus when the sheet opens.
- Search automatically receives focus and opens the keyboard. Scrolling the list does not unfocus search or automatically dismiss the keyboard.
- Extra bottom padding inside the country list allows the final country to scroll above the keyboard; the bottom sheet itself does not apply keyboard-inset padding.
- Dragging down from the top of the list resizes the sheet. On release, a downward pull of at least 20% of its original height dismisses the sheet and keyboard; a shorter pull restores its expanded height. There is no middle snap position.
- Selecting a country closes the sheet and revalidates the current phone number.
- Country names fall back to their ISO codes when a display name is unavailable.

## Example and testing

An executable demonstration is available in [`example/`](example/). Run it using:

```sh
cd example
flutter pub get
flutter run
```

Run the package checks from the repository root:

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Scope and limitations

- The current widget uses a searchable bottom sheet for country selection; dropdown and dialog selector modes are not implemented.
- As-you-type number formatting, country allowlists, and translated country names are not currently exposed.
- The widget manages its own internal phone text controller; a public controller and `FormField` API are not yet exposed.
- This package does not send SMS, perform OTP verification, or verify ownership of phone numbers.

## Contributing and issues

Report defects or suggest enhancements through [GitHub Issues](https://github.com/sayyarahmad1995/higo_phone_input/issues).
