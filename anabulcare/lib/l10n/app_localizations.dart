import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static const supportedLocales = [Locale('en'), Locale('id')];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'profileTitle': 'User Profile',
      'settingsTitle': 'Settings',
      'darkMode': 'Dark Mode',
      'language': 'Language',
      'logout': 'Logout',
      'editProfile': 'Edit Profile',
      'history': 'History',
      'noFavorites': 'No favorite coffee shops yet.',
    },
    'id': {
      'profileTitle': 'Profil Pengguna',
      'settingsTitle': 'Pengaturan',
      'darkMode': 'Mode Gelap',
      'language': 'Bahasa',
      'logout': 'Keluar',
      'editProfile': 'Edit Profil',
      'history': 'Riwayat',
      'noFavorites':
          'Belum ada coffee shop favorit. Tambahkan dari halaman detail.',
    },
  };

  String get profileTitle =>
      _localizedValues[locale.languageCode]?['profileTitle'] ?? 'User Profile';
  String get settingsTitle =>
      _localizedValues[locale.languageCode]?['settingsTitle'] ?? 'Settings';
  String get darkMode =>
      _localizedValues[locale.languageCode]?['darkMode'] ?? 'Dark Mode';
  String get language =>
      _localizedValues[locale.languageCode]?['language'] ?? 'Language';
  String get logout =>
      _localizedValues[locale.languageCode]?['logout'] ?? 'Logout';
  String get editProfile =>
      _localizedValues[locale.languageCode]?['editProfile'] ?? 'Edit Profile';
  String get history =>
      _localizedValues[locale.languageCode]?['history'] ?? 'History';
  String get noFavorites =>
      _localizedValues[locale.languageCode]?['noFavorites'] ??
      'No favorite coffee shops yet.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

