
import 'package:flutter_test/flutter_test.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:higo_phone_input/higo_phone_input.dart';

void main() {
  const service = PhoneValidationService();

  group('PhoneValidationService', () {
    test('accepts a valid US number', () {
      final result = service.validate(
        input: '4155552671',
        country: IsoCode.US,
      );

      expect(result.isValid, true);
      expect(result.e164, '+14155552671');
    });

    test('rejects an incomplete US number', () {
      final result = service.validate(
        input: '415555',
        country: IsoCode.US,
      );

      expect(result.isValid, false);
      expect(result.e164, isNull);
    });

    test('rejects empty input', () {
      final result = service.validate(
        input: '',
        country: IsoCode.PK,
      );

      expect(result.isValid, false);
      expect(result.e164, isNull);
    });

    test('rejects non-phone input', () {
      final result = service.validate(
        input: 'not-a-phone-number',
        country: IsoCode.GB,
      );

      expect(result.isValid, false);
    });
  });
}
