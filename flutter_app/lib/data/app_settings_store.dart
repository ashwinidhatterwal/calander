import 'package:shared_preferences/shared_preferences.dart';

import '../core/localization.dart';
import '../core/locations.dart';
import '../domain/models.dart';

class AppSettings {
  const AppSettings({required this.language, required this.location});

  final AppLanguage language;
  final GeoLocation location;
}

class AppSettingsStore {
  const AppSettingsStore();

  static const _languageKey = 'settings.language';
  static const _locationKey = 'settings.location';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final languageName = prefs.getString(_languageKey);
    final locationId = prefs.getString(_locationKey);

    final language = AppLanguage.values.firstWhere(
      (x) => x.name == languageName,
      orElse: () => AppLanguage.hi,
    );
    final location = locations.firstWhere(
      (x) => x.id == locationId,
      orElse: () => locations.first,
    );
    return AppSettings(language: language, location: location);
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }

  Future<void> saveLocation(GeoLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey, location.id);
  }
}
