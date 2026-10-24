import 'package:phone_numbers_parser/phone_numbers_parser.dart';

class PhoneValidationResult {
  final String input;
  final String countryCode;
  final String? e164;
  final bool isValid;

  const PhoneValidationResult({
    required this.input,
    required this.countryCode,
    required this.e164,
    required this.isValid,
  });
}

class PhoneValidationService {
  const PhoneValidationService();

  PhoneValidationResult validate({
    required String input,
    required IsoCode country,
    bool mobileOnly = true,
  }) {
    final value = input.trim();

    if (value.isEmpty) {
      return PhoneValidationResult(
        input: input,
        countryCode: country.name,
        e164: null,
        isValid: false,
      );
    }

    try {
      final number = PhoneNumber.parse(value, destinationCountry: country);

      final valid = mobileOnly
          ? number.isValid(type: PhoneNumberType.mobile)
          : number.isValid();

      return PhoneValidationResult(
        input: input,
        countryCode: country.name,
        e164: valid ? number.international : null,
        isValid: valid,
      );
    } on Exception {
      return PhoneValidationResult(
        input: input,
        countryCode: country.name,
        e164: null,
        isValid: false,
      );
    }
  }
}
