import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_theme.dart';
import '../core/localization.dart';
import '../core/locations.dart';
import '../domain/models.dart';

class AppSettings {
  const AppSettings({
    required this.language,
    required this.location,
    required this.theme,
  });

  final AppLanguage language;
  final GeoLocation location;
  final AppThemePreference theme;
}

class AppSettingsStore {
  const AppSettingsStore();

  static const _languageKey = 'settings.language';
  static const _locationKey = 'settings.location';
  static const _themeKey = 'settings.theme';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageName = prefs.getString(_languageKey);
    final locationId = prefs.getString(_locationKey);
    final themeName = prefs.getString(_themeKey);

    final language = AppLanguage.values.firstWhere(
      (x) => x.name == languageName,
      orElse: () => AppLanguage.hi,
    );
    final location = locations.firstWhere(
      (x) => x.id == locationId,
      orElse: () => locations.first,
    );
    final theme = AppThemePreference.values.firstWhere(
      (x) => x.name == themeName,
      orElse: () => AppThemePreference.light,
    );

    return AppSettings(
      language: language,
      location: location,
      theme: theme,
    );
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }

  Future<void> saveLocation(GeoLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey, location.id);
  }

  Future<void> saveTheme(AppThemePreference theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }
}
