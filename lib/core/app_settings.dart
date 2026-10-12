import 'package:deal/core/constants/countries.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    ThemeMode themeMode = ThemeMode.light,
    Locale locale = const Locale('ar'),
  }) : _themeMode = themeMode,
       _locale = locale {
    _loadCountry();
  }

  static const String _countryKey = 'deal_selected_country';

  ThemeMode _themeMode;
  Locale _locale;
  String _countryCode = DealCountries.defaultCountryCode;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get countryCode => _countryCode;

  DealCountry get selectedCountry => DealCountries.byCode(_countryCode);

  Future<void> _loadCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_countryKey);

      if (savedCode == null) return;

      // Accept only supported countries.
      if (!DealCountries.items.any((country) => country.code == savedCode)) {
        return;
      }

      // Do not overwrite a selection made while loading.
      if (_countryCode != DealCountries.defaultCountryCode) return;

      _countryCode = savedCode;
      notifyListeners();
    } catch (e) {
      debugPrint('Country loading error: $e');
    }
  }

  Future<void> setCountry(String code) async {
    if (!DealCountries.items.any((country) => country.code == code)) {
      return;
    }

    if (_countryCode == code) return;

    _countryCode = code;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_countryKey, code);
    } catch (e) {
      debugPrint('Country saving error: $e');
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;

    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'ar'
        ? const Locale('en')
        : const Locale('ar');

    notifyListeners();
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AppSettingsController? of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();

    return scope?.notifier;
  }
}
