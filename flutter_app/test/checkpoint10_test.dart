import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/data/app_settings_store.dart';
import 'package:hindu_calendar/data/notification_service.dart';
import 'package:hindu_calendar/domain/civil_holidays.dart';
import 'package:hindu_calendar/domain/festival_descriptions.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';
import 'package:hindu_calendar/domain/models.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/domain/personal_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('district and region survive offline settings reload', () async {
    SharedPreferences.setMockInitialValues({});
    const location = GeoLocation(
        id: 'current',
        cityHi: 'हनुमानगढ़',
        cityEn: 'Hanumangarh',
        stateHi: 'राजस्थान',
        stateEn: 'Rajasthan',
        countryCode: 'IN',
        latitude: 29.63,
        longitude: 74.05);
    await const AppSettingsStore().saveLocation(location);
    final saved = (await const AppSettingsStore().load()).location;
    expect(saved.cityEn, 'Hanumangarh');
    expect(saved.cityHi, 'हनुमानगढ़');
    expect(holidayRegion(saved.stateEn, saved.countryCode), 'RJ');
  });
  test('year cache async results retain astronomical parity and reuse',
      () async {
    final engine = FestivalEngine(const PanchangEngine());
    final async = await engine.majorFestivalsAsync(2026, locations.first);
    expect(
        async.map((f) => f.localDate),
        engine
            .majorFestivalsForYear(2026, locations.first)
            .map((f) => f.localDate));
    expect(
        identical(
            async, await engine.majorFestivalsAsync(2026, locations.first)),
        isTrue);
  });
  test('all major festivals have Hindi and English explanations', () {
    for (final id in [
      ...majorRules.map((r) => r.id),
      'holi',
      'holika_dahan',
      'ekadashi',
      'purnima',
      'amavasya'
    ]) {
      expect(festivalDescription(id, true).length, greaterThan(30), reason: id);
      expect(festivalDescription(id, false).length, greaterThan(30),
          reason: id);
    }
  });
  test('state calendars stay year-specific and separate from Hindu selection',
      () {
    expect(holidayRegion('Delhi', 'IN'), 'DL');
    expect(holidayRegion('Rajasthan', 'US'), isNull);
    expect(holidayRegion('Unknown', 'IN'), isNull);
    expect(stateHolidays.every((h) => h.year == 2026), isTrue);
    final teja = stateHolidays.singleWhere((h) => h.id == 'RJ_teja');
    expect(teja.dateInYear(2026), DateTime.utc(2026, 9, 21));
    expect(stateHolidays.singleWhere((h) => h.id == 'DL_holi').dateInYear(2026),
        DateTime.utc(2026, 3, 4));
  });
  test(
      'offline notification content has date tithi festival and personal event',
      () {
    const event = PersonalEvent(
        id: 'test',
        title: 'Family puja',
        kind: PersonalEventKind.puja,
        basis: PersonalEventBasis.gregorian,
        repeatYearly: false,
        gregorianYear: 2026,
        gregorianMonth: 11,
        gregorianDay: 11);
    final result = notificationPayload((
      DateTime.utc(2026, 11, 11),
      locations.first,
      AppLanguage.en,
      <int, DateTime>{},
      [event]
    ));
    expect(result.length, 32);
    expect(result['2026-11-11']!['title'], '11 November 2026');
    expect(result['2026-11-11']!['body'], contains('Bhai Dooj'));
    expect(result['2026-11-11']!['events'], 'Family puja');
  });
}
