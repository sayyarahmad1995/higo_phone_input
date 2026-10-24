import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:phone_numbers_parser/metadata.dart';
import 'package:locale_names/locale_names.dart';

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
      final code = entry.key;
      final dial = entry.value.countryCode;

      if (dial.isEmpty) continue;

      countries.add(
        PhoneCountry(isoCode: code, name: nameForIso(code), dialCode: '+$dial'),
      );
    }

    countries.sort((a, b) => a.name.compareTo(b.name));

    return List<PhoneCountry>.unmodifiable(countries);
  }();

  static PhoneCountry byIso(IsoCode isoCode) {
    return all.firstWhere((country) => country.isoCode == isoCode);
  }
}

Future<IsoCode?> showPhoneCountryBottomSheet({
  required BuildContext context,
  required IsoCode selectedCountry,
}) {
  return showModalBottomSheet<IsoCode>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    builder: (context) {
      return _CountrySheet(selectedCountry: selectedCountry);
    },
  );
}

class _CountrySheet extends StatefulWidget {
  const _CountrySheet({required this.selectedCountry});

  final IsoCode selectedCountry;

  @override
  State<_CountrySheet> createState() => _CountrySheetState();
}

class _CountrySheetState extends State<_CountrySheet> {
  final TextEditingController _searchController = TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();

    final filtered = PhoneCountries.all.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.isoCode.name.toLowerCase().contains(query) ||
          country.dialCode.contains(query);
    }).toList();

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select country',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('higo_country_search'),
                  controller: _searchController,
                  autofocus: false,
                  decoration: const InputDecoration(
                    hintText: 'Search country or code',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _query = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No countries found'))
                : ListView.builder(
                    key: const Key('higo_country_list'),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final country = filtered[index];
                      final selected =
                          country.isoCode == widget.selectedCountry;

                      return ListTile(
                        key: Key('higo_country_${country.isoCode.name}'),
                        leading: Text(
                          country.flag,
                          style: const TextStyle(fontSize: 25),
                        ),
                        title: Text(country.name),
                        subtitle: Text(country.isoCode.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(country.dialCode),
                            if (selected) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check),
                            ],
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pop(country.isoCode);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
