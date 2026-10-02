import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/data/district_lookup.dart';
import 'package:hindu_calendar/data/current_location_service.dart';
import 'package:hindu_calendar/domain/civil_holidays.dart';
import 'package:hindu_calendar/domain/models.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('district fallback distinguishes Hanumangarh from Bikaner division', () {
    final raw = File('assets/data/district_boundaries.json').readAsStringSync();
    expect(findDistrict((raw, 29.58, 74.29)), 'Hanumangarh');
    expect(findDistrict((raw, 28.02, 73.31)), 'Bikaner');
    expect(findDistrict((raw, 0, 0)), isNull);
    expect(isDivisionLabel('Bikaner Division'), isTrue);
    expect(isDivisionLabel('बीकानेर संभाग'), isTrue);
    for (final label in ['बीकानेर डिवीजन', 'बीकानेर डिविजन',
        'बीकानेर डीवीजन', 'बीकानेर डिवीज़न']) {
      expect(isDivisionLabel(label), isTrue, reason: label);
    }
    expect(isDivisionLabel('Hanumangarh'), isFalse);
    expect(isDivisionLabel('मंडला'), isFalse);
  });
  test('Hindi-only division label repairs the saved district', () async {
    const saved = GeoLocation(id: 'current', cityHi: 'बीकानेर डिवीजन',
        cityEn: 'Hanumangarh', stateHi: 'राजस्थान', stateEn: 'Rajasthan',
        latitude: 29.58, longitude: 74.29);
    final repaired = await const CurrentLocationService().repairSavedDistrict(saved);
    expect(repaired.cityHi, 'हनुमानगढ़');
    expect(repaired.cityEn, 'Hanumangarh');
    expect(repaired.cacheKey, saved.cacheKey);
  });
  test('12-hour display applies local offset and handles noon and midnight', () {
    final engine = PanchangEngine();
    const location = GeoLocation(id: 'test', cityHi: '', cityEn: '',
        latitude: 29.58, longitude: 74.29);
    expect(engine.time12(DateTime.utc(2026, 10, 2, 12, 48), location), '6:18 PM');
    expect(engine.time12(DateTime.utc(2026, 10, 2, 6, 30), location), '12:00 PM');
    expect(engine.time12(DateTime.utc(2026, 10, 1, 18, 30), location), '12:00 AM');
    expect(engine.time12(null, location), '—');
  });
  test('valid saved district does not require lookup or GPS', () async {
    const saved = GeoLocation(id: 'current', cityHi: 'हनुमानगढ़',
        cityEn: 'Hanumangarh', stateHi: 'राजस्थान', stateEn: 'Rajasthan',
        latitude: 29.58, longitude: 74.29);
    expect(identical(saved,
        await const CurrentLocationService().repairSavedDistrict(saved)), isTrue);
  });
  test('holiday lists cover 36 states and UTs, are sorted and year scoped', () {
    final regions = stateHolidays.map((h) => h.stateCode).toSet();
    expect(regions.length, 36);
    for (final region in regions) {
      final items = holidaysForRegion(2026, region);
      expect(items.where((h) => h.stateCode == region), isNotEmpty);
      expect(items.where((h) => h.id == 'republic_day').length, 1);
      for (var i = 1; i < items.length; i++) {
        expect(items[i].dateInYear(2026).isBefore(items[i - 1].dateInYear(2026)), isFalse);
      }
      expect(holidaysForRegion(2027, region).length, 3);
    }
  });
}
