/// Data source for persisted user preferences (theme).
abstract class PreferencesRepo {
  Future<String?> getThemeMode();
  Future<void> setThemeMode(String mode);
}