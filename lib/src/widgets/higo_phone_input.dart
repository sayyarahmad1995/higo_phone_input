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

  final FocusNode _phoneFocusNode = FocusNode();

  final GlobalKey _countrySelectorKey = GlobalKey();

  late IsoCode _country;
  late PhoneValidationResult _result;

  bool _touched = false;

  double _countrySelectorWidth = 0;

  // ============================================================
  // Lifecycle
  // ============================================================

  @override
  void initState() {
    super.initState();

    _country = widget.initialCountry;

    _controller = TextEditingController(text: widget.initialNumber);

    _phoneFocusNode.addListener(_onPhoneFocusChanged);

    _result = _validate();
  }

  @override
  void dispose() {
    _phoneFocusNode.removeListener(_onPhoneFocusChanged);
    _phoneFocusNode.dispose();

    _controller.dispose();

    super.dispose();
  }

  void _onPhoneFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // Country selector measurement
  // ============================================================

  void _measureCountrySelector() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final renderObject = _countrySelectorKey.currentContext
          ?.findRenderObject();

      if (renderObject is! RenderBox || !renderObject.hasSize) {
        return;
      }

      final width = renderObject.size.width;

      if ((width - _countrySelectorWidth).abs() > 0.5) {
        setState(() {
          _countrySelectorWidth = width;
        });
      }
    });
  }

  // ============================================================
  // Validation
  // ============================================================

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

  void _onNumberChanged(String value) {
    _updateResult();
  }

  // ============================================================
  // Country selection
  // ============================================================

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

  void _onCountryChanged(IsoCode? country) {
    if (country == null || country == _country) {
      return;
    }

    setState(() {
      _country = country;
    });

    _updateResult();
  }

  // ============================================================
  // Widget updates
  // ============================================================

  @override
  void didUpdateWidget(covariant HiGoPhoneInput oldWidget) {
    super.didUpdateWidget(oldWidget);

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

  // ============================================================
  // Country selector widget
  // ============================================================

  Widget _buildCountrySelector(BuildContext context, PhoneCountry country) {
    final theme = Theme.of(context);

    final selectorTextStyle =
        widget.countrySelectorTextStyle ?? theme.textTheme.bodyMedium;

    return Material(
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
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final country = PhoneCountries.byIso(_country);

    final baseDecoration = widget.decoration ?? const InputDecoration();

    final hasValue = _controller.text.isNotEmpty;

    final isFloating = _phoneFocusNode.hasFocus || hasValue;

    final showError = widget.validateOnChange && _touched && !_result.isValid;

    // ----------------------------------------------------------
    // Measure country selector
    // ----------------------------------------------------------

    _measureCountrySelector();

    // ----------------------------------------------------------
    // Animated label
    // ----------------------------------------------------------

    final label =
        baseDecoration.label ??
        Text(baseDecoration.labelText ?? widget.labelText);

    final animatedLabel = IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: isFloating ? 0 : _countrySelectorWidth),

        duration: const Duration(milliseconds: 180),

        curve: Curves.easeInOut,

        builder: (context, offset, child) {
          return Transform.translate(offset: Offset(offset, 0), child: child);
        },

        child: label,
      ),
    );

    // ----------------------------------------------------------
    // Outer decoration
    // ----------------------------------------------------------

    final outerDecoration = InputDecoration(
      label: animatedLabel,

      // Flutter handles the vertical floating animation.
      floatingLabelBehavior: FloatingLabelBehavior.auto,

      floatingLabelAlignment: FloatingLabelAlignment.start,

      border: baseDecoration.border ?? const OutlineInputBorder(),

      enabledBorder: baseDecoration.enabledBorder,
      focusedBorder: baseDecoration.focusedBorder,
      disabledBorder: baseDecoration.disabledBorder,
      errorBorder: baseDecoration.errorBorder,
      focusedErrorBorder: baseDecoration.focusedErrorBorder,

      filled: baseDecoration.filled,
      fillColor: baseDecoration.fillColor,
      focusColor: baseDecoration.focusColor,
      hoverColor: baseDecoration.hoverColor,

      contentPadding:
          baseDecoration.contentPadding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 16),

      isDense: baseDecoration.isDense,
      constraints: baseDecoration.constraints,

      helperText: baseDecoration.helperText,
      helperStyle: baseDecoration.helperStyle,

      errorText: showError
          ? 'Enter a valid phone number'
          : baseDecoration.errorText,

      errorStyle: baseDecoration.errorStyle,

      labelStyle: baseDecoration.labelStyle,
      floatingLabelStyle: baseDecoration.floatingLabelStyle,

      enabled: widget.enabled,
    );

    // ----------------------------------------------------------
    // Shared input wrapper
    // ----------------------------------------------------------

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        _measureCountrySelector();
        return false;
      },

      child: InputDecorator(
        decoration: outerDecoration,

        isFocused: _phoneFocusNode.hasFocus,
        isEmpty: !hasValue,

        child: Row(
          children: [
            // --------------------------------------------------
            // Country selector
            // --------------------------------------------------
            SizeChangedLayoutNotifier(
              child: KeyedSubtree(
                key: _countrySelectorKey,

                child: _buildCountrySelector(context, country),
              ),
            ),

            // --------------------------------------------------
            // Phone number field
            // --------------------------------------------------
            Expanded(
              child: TextField(
                key: const Key('higo_phone_number'),

                controller: _controller,
                focusNode: _phoneFocusNode,

                enabled: widget.enabled,
                autofocus: widget.autofocus,

                keyboardType: TextInputType.phone,
                textInputAction: widget.textInputAction,

                style: widget.textStyle,
                cursorColor: widget.cursorColor,

                autofillHints: const [AutofillHints.telephoneNumber],

                // Outer InputDecorator owns the border
                // and label. Inner TextField owns input.
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,

                  hintText: isFloating && baseDecoration.hint == null
                      ? baseDecoration.hintText ?? widget.hintText
                      : null,

                  hint: isFloating ? baseDecoration.hint : null,

                  hintStyle: baseDecoration.hintStyle,
                ),

                onChanged: _onNumberChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
