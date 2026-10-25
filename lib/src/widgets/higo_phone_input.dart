import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../services/phone_validation_service.dart';
import 'country_bottom_sheet.dart';

class HiGoPhoneInput extends StatefulWidget {
  const HiGoPhoneInput({
    super.key,
    this.initialCountry = IsoCode.PK,
    this.initialNumber = '',
    this.mobileOnly = true,
    this.validateOnChange = true,
    this.enabled = true,
    this.labelText = 'Phone number',
    this.hintText = 'Enter phone number',

    // Appearance customization
    this.decoration,
    this.textStyle,
    this.countrySelectorTextStyle,
    this.searchBoxDecoration,
    this.cursorColor,
    this.autofocus = false,
    this.textInputAction = TextInputAction.done,
    this.showCountryFlag = true,

    this.onChanged,
  });

  final IsoCode initialCountry;
  final String initialNumber;
  final bool mobileOnly;
  final bool validateOnChange;
  final bool enabled;
  final String labelText;
  final String hintText;

  /// Customize the phone input's decoration.
  /// The integrated country selector is preserved.
  final InputDecoration? decoration;

  /// Style of the entered phone number.
  final TextStyle? textStyle;

  /// Style of the country dialing code.
  final TextStyle? countrySelectorTextStyle;

  /// Decoration of the country search field.
  final InputDecoration? searchBoxDecoration;

  /// Cursor color of the phone number field.
  final Color? cursorColor;

  /// Automatically focus the phone number field.
  final bool autofocus;

  /// Keyboard action, such as done or next.
  final TextInputAction textInputAction;

  /// Whether to display the selected country's flag.
  final bool showCountryFlag;

  final ValueChanged<PhoneValidationResult>? onChanged;

  @override
  State<HiGoPhoneInput> createState() => _HiGoPhoneInputState();
}

class _HiGoPhoneInputState extends State<HiGoPhoneInput> {
  final PhoneValidationService _validator = const PhoneValidationService();

  late final TextEditingController _controller;

  late IsoCode _country;
  late PhoneValidationResult _result;

  bool _touched = false;

  // Temporary country list for Phase 2.
  // Phase 3 will support all available countries.
  Future<void> _openCountrySelector() async {
    if (!widget.enabled) return;

    final selected = await showPhoneCountryBottomSheet(
      context: context,
      selectedCountry: _country,
      searchBoxDecoration: widget.searchBoxDecoration,
    );

    if (!mounted || selected == null || selected == _country) {
      return;
    }

    _onCountryChanged(selected);
  }

  @override
  void initState() {
    super.initState();

    _country = widget.initialCountry;
    _controller = TextEditingController(text: widget.initialNumber);

    _result = _validate();
  }

  PhoneValidationResult _validate() {
    return _validator.validate(
      input: _controller.text,
      country: _country,
      mobileOnly: widget.mobileOnly,
    );
  }

  void _updateResult({bool markTouched = true}) {
    if (markTouched) {
      _touched = true;
    }

    final result = _validate();

    setState(() {
      _result = result;
    });

    widget.onChanged?.call(result);
  }

  void _onCountryChanged(IsoCode? country) {
    if (country == null || country == _country) {
      return;
    }

    setState(() {
      _country = country;
    });

    _updateResult();
  }

  void _onNumberChanged(String value) {
    _updateResult();
  }

  @override
  void didUpdateWidget(covariant HiGoPhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only respond to actual configuration changes.
    // An ordinary parent rebuild must not reset the country.
    bool changed = false;

    if (oldWidget.initialCountry != widget.initialCountry) {
      _country = widget.initialCountry;
      changed = true;
    }

    if (oldWidget.initialNumber != widget.initialNumber) {
      _controller.text = widget.initialNumber;
      changed = true;
    }

    if (oldWidget.mobileOnly != widget.mobileOnly) {
      changed = true;
    }

    if (changed) {
      _updateResult(markTouched: false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final country = PhoneCountries.byIso(_country);

    final showError = widget.validateOnChange && _touched && !_result.isValid;

    final selectorTextStyle =
        widget.countrySelectorTextStyle ?? theme.textTheme.bodyMedium;

    final countrySelector = Material(
      type: MaterialType.transparency,
      child: InkWell(
        key: const Key('higo_country_selector'),
        onTap: widget.enabled ? _openCountrySelector : null,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showCountryFlag) ...[
                Text(country.flag, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 6),
              ],
              Text(
                country.dialCode,
                style: selectorTextStyle?.copyWith(
                  color: widget.enabled
                      ? selectorTextStyle.color ?? theme.colorScheme.onSurface
                      : theme.disabledColor,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.arrow_drop_down,
                size: 20,
                color: widget.enabled
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.disabledColor,
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: theme.dividerColor),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );

    final baseDecoration = widget.decoration ?? const InputDecoration();

    final inputDecoration = baseDecoration.copyWith(
      labelText: baseDecoration.label == null
          ? baseDecoration.labelText ?? widget.labelText
          : null,

      hintText: baseDecoration.hint == null
          ? baseDecoration.hintText ?? widget.hintText
          : null,

      floatingLabelBehavior: FloatingLabelBehavior.auto,
      floatingLabelAlignment: FloatingLabelAlignment.start,

      border: baseDecoration.border ?? const OutlineInputBorder(),

      errorText: showError
          ? 'Enter a valid phone number'
          : baseDecoration.errorText,

      prefix: null,
      prefixIcon: countrySelector,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
    );

    return TextField(
      key: const Key('higo_phone_number'),
      controller: _controller,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      style: widget.textStyle,
      cursorColor: widget.cursorColor,
      autofillHints: const [AutofillHints.telephoneNumber],
      decoration: inputDecoration,
      onChanged: _onNumberChanged,
    );
  }
}
