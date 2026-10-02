import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/data/app_settings_store.dart';
import 'package:hindu_calendar/domain/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = AppSettingsStore();
  const current = GeoLocation(
    id: 'current',
    cityHi: 'वर्तमान स्थान',
    cityEn: 'Current location',
    latitude: 28.7,
    longitude: 74.3,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'existing predefined city preferences migrate without changes',
    () async {
      SharedPreferences.setMockInitialValues({'settings.location': 'jaipur'});
      expect((await store.load()).location.id, 'jaipur');
    },
  );

  test(
    'coordinates and offset survive restart; manual city remains available',
    () async {
      await store.saveLocation(current);
      final saved = await const AppSettingsStore().load();
      expect(saved.location.cacheKey, current.cacheKey);
      expect(saved.location.id, 'current');
      await store.saveLocation(locations[1]);
      expect((await store.load()).location.id, 'jaipur');
    },
  );

  test(
    'refresh changes effective cache key even when ID stays current',
    () async {
      const refreshed = GeoLocation(
        id: 'current',
        cityHi: '',
        cityEn: '',
        latitude: 26.9,
        longitude: 75.8,
      );
      await store.saveLocation(current);
      final previous = (await store.load()).location.cacheKey;
      await store.saveLocation(refreshed);
      expect((await store.load()).location.cacheKey, isNot(previous));
    },
  );

  test('corrupt and out-of-range custom data safely fall back', () async {
    for (final payload in [
      '{broken',
      '{}',
      jsonEncode({'latitude': 91, 'longitude': 74, 'utcOffsetMinutes': 330}),
      jsonEncode({'latitude': 28, 'longitude': 74, 'utcOffsetMinutes': 900}),
    ]) {
      SharedPreferences.setMockInitialValues({
        'settings.location': 'current',
        'settings.customLocation.v1': payload,
      });
      expect((await store.load()).location.id, locations.first.id);
    }
  });

  test('invalid coordinates cannot replace a valid saved location', () async {
    await store.saveLocation(current);
    const invalid = GeoLocation(
      id: 'current',
      cityHi: '',
      cityEn: '',
      latitude: double.nan,
      longitude: 74,
    );
    await expectLater(store.saveLocation(invalid), throwsArgumentError);
    expect((await store.load()).location.cacheKey, current.cacheKey);
  });

  test('first-use offer is remembered', () async {
    expect((await store.load()).offerCurrentLocation, isTrue);
    await store.markLocationOfferSeen();
    expect((await store.load()).offerCurrentLocation, isFalse);
  });
}
