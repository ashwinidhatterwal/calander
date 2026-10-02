import 'dart:convert';

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
    this.offerCurrentLocation = false,
  });

  final AppLanguage language;
  final GeoLocation location;
  final AppThemePreference theme;
  final bool offerCurrentLocation;
}

class AppSettingsStore {
  const AppSettingsStore();

  static const _languageKey = 'settings.language';
  static const _locationKey = 'settings.location';
  static const _customLocationKey = 'settings.customLocation.v1';
  static const _locationOfferKey = 'settings.locationOfferSeen';
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
    var location = locations.firstWhere(
      (x) => x.id == locationId,
      orElse: () => locations.first,
    );
    if (locationId == 'current') {
      try {
        final data = jsonDecode(
          prefs.getString(_customLocationKey) ?? '',
        ) as Map<String, dynamic>;
        final custom = GeoLocation(
          id: 'current',
          cityHi: data['cityHi'] as String? ?? 'सहेजा हुआ स्थान',
          cityEn: data['cityEn'] as String? ?? 'Saved location',
          stateHi: data['stateHi'] as String? ?? '',
          stateEn: data['stateEn'] as String? ?? '',
          countryCode: data['countryCode'] as String? ?? '',
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          utcOffsetMinutes: data['utcOffsetMinutes'] as int,
        );
        if (custom.hasValidCoordinates) location = custom;
      } catch (_) {
        // Invalid or incomplete custom data falls back to the original city.
      }
    }
    final theme = AppThemePreference.values.firstWhere(
      (x) => x.name == themeName,
      orElse: () => AppThemePreference.light,
    );

    return AppSettings(
      language: language,
      location: location,
      theme: theme,
      offerCurrentLocation: !(prefs.getBool(_locationOfferKey) ?? false),
    );
  }

  Future<void> saveLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.name);
  }

  Future<void> saveLocation(GeoLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    if (!location.hasValidCoordinates) {
      throw ArgumentError('Invalid coordinates');
    }
    if (location.id == 'current') {
      // Write the complete payload before pointing the selected ID at it.
      final payloadSaved = await prefs.setString(
        _customLocationKey,
        jsonEncode({
          'cityHi': location.cityHi,
          'cityEn': location.cityEn,
          'stateHi': location.stateHi,
          'stateEn': location.stateEn,
          'countryCode': location.countryCode,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'utcOffsetMinutes': location.utcOffsetMinutes,
        }),
      );
      if (!payloadSaved) throw StateError('Location payload write failed');
    } else if (!locations.any((x) => x.id == location.id)) {
      throw ArgumentError('Unknown manual location');
    }
    if (!await prefs.setString(_locationKey, location.id)) {
      throw StateError('Location selection write failed');
    }
  }

  Future<void> markLocationOfferSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationOfferKey, true);
  }

  Future<void> saveTheme(AppThemePreference theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.name);
  }
}
