import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repos/preferences_repo.dart';
import '../states/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final PreferencesRepo _repo;

  SettingsCubit({required PreferencesRepo repo})
      : _repo = repo,
        super(const SettingsState());

  /// Load persisted preferences once at startup.
  Future<void> load() async {
    final savedTheme = await _repo.getThemeMode();
    final savedLocale = await _repo.getLocale();

    emit(
      SettingsState(
        themeMode: _themeModeFromString(savedTheme),
        locale: _localeFromString(savedLocale),
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state.themeMode) return;
    emit(state.copyWith(themeMode: mode));
    await _repo.setThemeMode(mode.name);
  }

  Future<void> toggleTheme() {
    return setThemeMode(
      state.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> setLocale(Locale locale) async {
    if (locale == state.locale) return;
    emit(state.copyWith(locale: locale));
    await _repo.setLocale(locale.languageCode);
  }

  ThemeMode _themeModeFromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  Locale _localeFromString(String? value) {
    switch (value) {
      case 'en':
        return const Locale('en');
      default:
        return const Locale('ar');
    }
  }
}
