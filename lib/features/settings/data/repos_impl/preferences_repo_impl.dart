import 'package:shared_preferences/shared_preferences.dart';

import '../repos/preferences_repo.dart';

class PreferencesRepoImpl implements PreferencesRepo {
  final SharedPreferences _prefs;

  PreferencesRepoImpl(this._prefs);

  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';

  @override
  Future<String?> getThemeMode() async {
    return _prefs.getString(_kThemeMode);
  }

  @override
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_kThemeMode, mode);
  }

  @override
  Future<String?> getLocale() async {
    return _prefs.getString(_kLocale);
  }

  @override
  Future<void> setLocale(String locale) async {
    await _prefs.setString(_kLocale, locale);
  }
}
