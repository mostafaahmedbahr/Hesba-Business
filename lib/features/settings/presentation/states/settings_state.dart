import 'package:flutter/material.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('ar'),
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}
