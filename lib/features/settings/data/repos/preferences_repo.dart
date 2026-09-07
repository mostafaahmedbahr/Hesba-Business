/// Data source for persisted user preferences (theme & language).
abstract class PreferencesRepo {
  Future<String?> getThemeMode();
  Future<void> setThemeMode(String mode);

  Future<String?> getLocale();
  Future<void> setLocale(String locale);
}
