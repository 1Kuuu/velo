import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'settings': 'Settings',
      'profile': 'Profile',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'notification': 'Notification',
      'helpAndSupport': 'Help & Support',
      'termsAndCondition': 'Terms & Condition',
      'about': 'About',
      'logout': 'Logout',
      'editProfile': 'Edit Profile',
      'saved': 'Saved',
      'content': 'Content',
      'general': 'General',
      'confirmLogout': 'Confirm Logout',
      'logoutConfirmMessage': 'Are you sure you want to log out?',
      'yes': 'Yes',
      'no': 'No',
      'noBioAvailable': 'No bio available',
      'noName': 'No Name',
      'noEmail': 'No Email',
      'suggestedLanguages': 'SUGGESTED LANGUAGES',
      'default': 'Default',
      'languageReminder':
          'Reminders will use the first language that it supports from Language & Region settings. You can select a different language that you prefer to use.',
    },
    'en_UK': {
      'settings': 'Settings',
      'profile': 'Profile',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'notification': 'Notification',
      'helpAndSupport': 'Help & Support',
      'termsAndCondition': 'Terms & Condition',
      'about': 'About',
      'logout': 'Logout',
      'editProfile': 'Edit Profile',
      'saved': 'Saved',
      'content': 'Content',
      'general': 'General',
      'confirmLogout': 'Confirm Logout',
      'logoutConfirmMessage': 'Are you sure you want to log out?',
      'yes': 'Yes',
      'no': 'No',
      'noBioAvailable': 'No bio available',
      'noName': 'No Name',
      'noEmail': 'No Email',
      'suggestedLanguages': 'SUGGESTED LANGUAGES',
      'default': 'Default',
      'languageReminder':
          'Reminders will use the first language that it supports from Language & Region settings. You can select a different language that you prefer to use.',
    },
    'fil': {
      'settings': 'Mga Setting',
      'profile': 'Profile',
      'language': 'Wika',
      'darkMode': 'Dark Mode',
      'notification': 'Abiso',
      'helpAndSupport': 'Tulong at Suporta',
      'termsAndCondition': 'Mga Tuntunin at Kondisyon',
      'about': 'Tungkol Sa',
      'logout': 'Mag-logout',
      'editProfile': 'I-edit ang Profile',
      'saved': 'Naka-save',
      'content': 'Nilalaman',
      'general': 'Pangkalahatan',
      'confirmLogout': 'Kumpirmahin ang Pag-logout',
      'logoutConfirmMessage': 'Sigurado ka bang gusto mong mag-logout?',
      'yes': 'Oo',
      'no': 'Hindi',
      'noBioAvailable': 'Walang bio',
      'noName': 'Walang Pangalan',
      'noEmail': 'Walang Email',
      'suggestedLanguages': 'MGA IMINUMUNGKAHING WIKA',
      'default': 'Default',
      'languageReminder':
          'Ang mga paalala ay gagamit ng unang wikang sinusuportahan nito mula sa mga setting ng Wika at Rehiyon. Maaari kang pumili ng ibang wikang nais mong gamitin.',
    },
  };

  String translate(String key) {
    String languageCode = locale.languageCode;
    if (locale.toString() == 'en_UK') {
      languageCode = 'en_UK';
    } else if (languageCode == 'en') {
      languageCode = 'en';
    } else if (languageCode == 'fil') {
      languageCode = 'fil';
    }

    return _localizedValues[languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'fil'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
