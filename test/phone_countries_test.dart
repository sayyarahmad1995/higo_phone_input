import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import 'package:higo_phone_input/src/widgets/country_bottom_sheet.dart';

void main() {
  group('PhoneCountries', () {
    test('Resolves Pakistan', () {
      final country = PhoneCountries.byIso(IsoCode.PK);

      expect(country.name, 'Pakistan');
      expect(country.dialCode, '+92');
      expect(country.isoCode, IsoCode.PK);
    });

    test('Resolves United Kingdom', () {
      final country = PhoneCountries.byIso(IsoCode.GB);

      expect(country.name, 'United Kingdom');
      expect(country.dialCode, '+44');
    });

    test('Resolves United Arab Emirates', () {
      final country = PhoneCountries.byIso(IsoCode.AE);

      expect(country.name, 'United Arab Emirates');
      expect(country.dialCode, '+971');
    });

    test('Country names are not empty', () {
      for (final country in PhoneCountries.all) {
        expect(
          country.name.trim(),
          isNotEmpty,
          reason: '${country.isoCode.name} has no name',
        );
      }
    });

    test('Countries are sorted alphabetically', () {
      final names = PhoneCountries.all.map((country) => country.name).toList();

      final sorted = List<String>.from(names)..sort();

      expect(names, sorted);
    });

    test('Every country has a dialing prefix', () {
      for (final country in PhoneCountries.all) {
        expect(country.dialCode, startsWith('+'));
        expect(country.dialCode.length, greaterThan(1));
      }
    });
  });
}
