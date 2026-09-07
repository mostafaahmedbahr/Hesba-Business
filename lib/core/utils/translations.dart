import 'package:flutter/material.dart';

/// Lightweight bilingual (Arabic / English) string lookup.
class Translations {
  static const supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  static const _ar = <String, String>{};
  static const _en = <String, String>{};

  /// Returns the localized string for [key] based on [locale].
  /// Falls back to Arabic if not found.
  static String of(BuildContext context, String key) {
    final locale = Localizations.localeOf(context).languageCode;
    final table = locale == 'en' ? _en : _ar;
    return table[key] ?? _ar[key] ?? key;
  }
}
