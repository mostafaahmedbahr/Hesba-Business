import 'package:shared_preferences/shared_preferences.dart';

import '../repos/preferences_repo.dart';

class PreferencesRepoImpl implements PreferencesRepo {
  final SharedPreferences _prefs;

  PreferencesRepoImpl(this._prefs);

  static const _kThemeMode = 'theme_mode';

  @override
  Future<String?> getThemeMode() async {
    return _prefs.getString(_kThemeMode);
  }

  @override
  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_kThemeMode, mode);
  }
}