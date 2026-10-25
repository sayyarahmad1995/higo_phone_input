import 'package:flutter/material.dart';
import 'package:locale_names/locale_names.dart';
import 'package:phone_numbers_parser/metadata.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

// ============================================================
// Country model
// ============================================================

class PhoneCountry {
  final IsoCode isoCode;
  final String name;
  final String dialCode;

  const PhoneCountry({
    required this.isoCode,
    required this.name,
    required this.dialCode,
  });

  String get flag {
    final code = isoCode.name.toUpperCase();

    if (code.length != 2) return '';

    return String.fromCharCodes(code.codeUnits.map((unit) => unit + 127397));
  }
}

// ============================================================
// Country metadata
// ============================================================

class PhoneCountries {
  PhoneCountries._();

  static String nameForIso(IsoCode isoCode) {
    final code = isoCode.name.toUpperCase();

    final locale = Locale.fromSubtags(languageCode: 'en', countryCode: code);

    final name = locale.defaultDisplayCountry;

    return name.isEmpty ? code : name;
  }

  static final List<PhoneCountry> all = () {
    final countries = <PhoneCountry>[];

    for (final entry in metadataByIsoCode.entries) {
      final isoCode = entry.key;
      final dialCode = entry.value.countryCode;

      if (dialCode.isEmpty) continue;

      countries.add(
        PhoneCountry(
          isoCode: isoCode,
          name: nameForIso(isoCode),
          dialCode: '+$dialCode',
        ),
      );
    }

    countries.sort((a, b) => a.name.compareTo(b.name));

    return List<PhoneCountry>.unmodifiable(countries);
  }();

  static PhoneCountry byIso(IsoCode isoCode) {
    return all.firstWhere((country) => country.isoCode == isoCode);
  }
}

// ============================================================
// Public country selector
// ============================================================

Future<IsoCode?> showPhoneCountryBottomSheet({
  required BuildContext context,
  required IsoCode selectedCountry,
  InputDecoration? searchBoxDecoration,
}) {
  return showModalBottomSheet<IsoCode>(
    context: context,

    isScrollControlled: true,

    // Do not insert extra safe-area padding.
    useSafeArea: false,

    // Dragging is managed by DraggableScrollableSheet.
    enableDrag: false,
    showDragHandle: false,

    backgroundColor: Colors.transparent,

    builder: (context) {
      return _CountrySheet(
        selectedCountry: selectedCountry,
        searchBoxDecoration: searchBoxDecoration,
      );
    },
  );
}

// ============================================================
// Country selector
// ============================================================

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({
    required this.selectedCountry,
    this.searchBoxDecoration,
  });

  final IsoCode selectedCountry;
  final InputDecoration? searchBoxDecoration;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final TextEditingController _searchController = TextEditingController();

  final FocusNode _searchFocusNode = FocusNode();

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  String _query = '';

  // ==========================================================
  // Sheet configuration
  // ==========================================================

  static const double _initialSheetSize = 0.78;
  static const double _minimumSheetSize = 0.18;

  // Dismiss after dragging downward by 25%
  // of the selector's original height.
  static const double _dismissDragFraction = 0.2;

  static const double _dismissSheetSize =
      _initialSheetSize * (1 - _dismissDragFraction);

  static const Duration _returnDuration = Duration(milliseconds: 250);

  bool _handlingRelease = false;

  // ==========================================================
  // Lifecycle
  // ==========================================================

  @override
  void initState() {
    super.initState();

    // Automatically focus search when the selector opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();

    super.dispose();
  }

  // ==========================================================
  // Release-to-dismiss behavior
  // ==========================================================

  void _handlePointerRelease() {
    if (!mounted || !_sheetController.isAttached || _handlingRelease) {
      return;
    }

    final currentSize = _sheetController.size;

    // Ignore country taps and normal list scrolling.
    if (currentSize >= _initialSheetSize - 0.001) {
      return;
    }

    _handlingRelease = true;

    // Schedule the decision after pointer processing.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_sheetController.isAttached) {
        _handlingRelease = false;
        return;
      }

      try {
        if (currentSize <= _dismissSheetSize) {
          // Close the sheet and keyboard together.
          _searchFocusNode.unfocus();

          Navigator.of(context).pop();
          return;
        }

        // Did not cross halfway: return to expanded size.
        await _sheetController.animateTo(
          _initialSheetSize,
          duration: _returnDuration,
          curve: Curves.easeOutCubic,
        );
      } finally {
        if (mounted) {
          _handlingRelease = false;
        }
      }
    });
  }

  // ==========================================================
  // Dragging from the sheet handle
  // ==========================================================

  void _onHandleDragUpdate(DragUpdateDetails details) {
    if (!_sheetController.isAttached) return;

    final currentSize = _sheetController.size;

    final deltaSize = _sheetController.pixelsToSize(details.delta.dy);

    final nextSize = (currentSize - deltaSize).clamp(
      _minimumSheetSize,
      _initialSheetSize,
    );

    _sheetController.jumpTo(nextSize);

    // Do not unfocus search.
    // The keyboard should stay open while dragging.
  }

  // ==========================================================
  // Search field
  // ==========================================================

  Widget _buildSearchField() {
    final decoration = (widget.searchBoxDecoration ?? const InputDecoration())
        .copyWith(
          hintText:
              widget.searchBoxDecoration?.hintText ?? 'Search country or code',

          prefixIcon:
              widget.searchBoxDecoration?.prefixIcon ??
              const Icon(Icons.search),

          border:
              widget.searchBoxDecoration?.border ?? const OutlineInputBorder(),
        );

    return TextField(
      key: const Key('higo_country_search'),
      controller: _searchController,
      focusNode: _searchFocusNode,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      decoration: decoration,

      onChanged: (value) {
        setState(() {
          _query = value;
        });
      },
    );
  }

  // ==========================================================
  // Country list
  // ==========================================================

  Widget _buildCountryList(
    List<PhoneCountry> countries,
    ScrollController scrollController,
    double keyboardHeight,
  ) {
    return ListView.builder(
      key: const Key('higo_country_list'),

      // Critical:
      // Use the controller supplied by DraggableScrollableSheet.
      //
      // At the top of the list, a further downward drag
      // will resize the sheet instead of scrolling.
      controller: scrollController,

      // Keep keyboard open during scrolling.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,

      // Allows dragging even when the filtered list is short.
      physics: const AlwaysScrollableScrollPhysics(),

      // Extra scrollable space lets the last country
      // move above the keyboard instead of being hidden.
      //
      // This padding is inside the list, NOT around the sheet.
      padding: EdgeInsets.only(bottom: keyboardHeight + 16),

      itemCount: countries.isEmpty ? 1 : countries.length,

      itemBuilder: (context, index) {
        if (countries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: Text('No countries found')),
          );
        }

        final country = countries[index];

        final isSelected = country.isoCode == widget.selectedCountry;

        return ListTile(
          key: Key('higo_country_${country.isoCode.name}'),

          leading: Text(country.flag, style: const TextStyle(fontSize: 25)),

          title: Text(country.name),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.dialCode),

              if (isSelected) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check),
              ],
            ],
          ),

          onTap: () {
            // Selecting a country closes the sheet.
            // The search field is disposed with the sheet.
            _searchFocusNode.unfocus();

            Navigator.of(context).pop(country.isoCode);
          },
        );
      },
    );
  }

  // ==========================================================
  // Drag handle
  // ==========================================================

  Widget _buildDragHandle(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onVerticalDragUpdate: _onHandleDragUpdate,

      onVerticalDragEnd: (_) {
        _handlePointerRelease();
      },

      onVerticalDragCancel: () {
        _handlePointerRelease();
      },

      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),

              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // Build
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();

    final filtered = PhoneCountries.all.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.isoCode.name.toLowerCase().contains(query) ||
          country.dialCode.contains(query);
    }).toList();

    // Read the keyboard height for list padding.
    // Do not move the outer sheet above the keyboard.
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      controller: _sheetController,

      expand: false,

      initialChildSize: _initialSheetSize,
      minChildSize: _minimumSheetSize,
      maxChildSize: _initialSheetSize,

      // No intermediate snap position.
      snap: false,

      // The sheet must not automatically close
      // when it reaches its minimum height.
      shouldCloseOnMinExtent: false,

      builder: (context, scrollController) {
        return Listener(
          behavior: HitTestBehavior.deferToChild,

          // We only evaluate closing after pointer release.
          onPointerUp: (_) {
            _handlePointerRelease();
          },

          onPointerCancel: (_) {
            _handlePointerRelease();
          },

          child: Material(
            color: Theme.of(context).colorScheme.surface,

            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),

            clipBehavior: Clip.antiAlias,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,

              children: [
                // --------------------------------------------
                // Draggable handle
                // --------------------------------------------
                _buildDragHandle(context),

                // --------------------------------------------
                // Header + search
                // --------------------------------------------
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Select country',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),

                      const SizedBox(height: 16),

                      _buildSearchField(),
                    ],
                  ),
                ),

                // --------------------------------------------
                // Scrollable country list
                // --------------------------------------------
                Expanded(
                  child: _buildCountryList(
                    filtered,
                    scrollController,
                    keyboardHeight,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
