import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _selectedLanguage = 'English';
  Locale _locale = const Locale('en');

  String get selectedLanguage => _selectedLanguage;
  Locale get locale => _locale;

  Future<void> loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    _setLocaleFromLanguage(_selectedLanguage);
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    _selectedLanguage = language;
    _setLocaleFromLanguage(language);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
    notifyListeners();
  }

  void _setLocaleFromLanguage(String language) {
    switch (language) {
      case 'English':
        _locale = const Locale('en');
        break;
      case 'English (UK)':
        _locale = const Locale('en', 'UK');
        break;
      case 'Filipino/Tagalog':
        _locale = const Locale('fil');
        break;
      default:
        _locale = const Locale('en');
    }
  }
}
