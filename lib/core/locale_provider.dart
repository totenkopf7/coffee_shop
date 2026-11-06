// lib/core/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the chosen language. Defaults to Kurdish (Badini) on first run.
///
/// Uses an InheritedNotifier-free approach: the app passes this instance
/// directly to [CoffeeShopApp], which rebuilds MaterialApp on change.
class LocaleProvider extends ChangeNotifier {
  static const _kLangKey = 'app_language_code';

  Locale _locale = const Locale('ku');
  Locale get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey);
    if (code != null && (code == 'en' || code == 'ku')) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(String code) async {
    if (code != 'en' && code != 'ku') return;
    if (_locale.languageCode == code) return;
    _locale = Locale(code);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, code);
  }

  bool get isKurdish => _locale.languageCode == 'ku';
}

/// Global singleton — lets any screen call
/// `showLanguagePicker(context, localeProviderInstance)` without threading
/// the provider through the widget tree.
final LocaleProvider localeProviderInstance = LocaleProvider();
