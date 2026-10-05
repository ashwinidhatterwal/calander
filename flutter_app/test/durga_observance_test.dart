import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/domain/models.dart';

void main() {
  const panchang = PanchangEngine();
  const hanumangarh = GeoLocation(
      id: 'test_hanumangarh',
      cityHi: 'हनुमानगढ़',
      cityEn: 'Hanumangarh',
      latitude: 29.58,
      longitude: 74.32);
  for (final loc in [
    locations.firstWhere((x) => x.id == 'delhi'),
    hanumangarh
  ]) {
    final festival = FestivalEngine(panchang,
        holikaOverrides: {2026: DateTime.utc(2026, 3, 3)});
    for (final (year, date) in [
      (2026, DateTime.utc(2026, 10, 19)),
      (2027, DateTime.utc(2027, 10, 7))
    ]) {
      test(
          '${loc.cityEn} Durga Ashtami $year matches published date and has no duplicate monthly label',
          () {
        final major = festival.majorFestivalsForYear(year, loc);
        expect(
            major.singleWhere((x) => x.id == 'durga_ashtami').localDate, date);
        final events = festival.lightweightForDate(date, loc, major: major);
        expect(events.where((x) => x.id.contains('ashtami')).length, 1);
        expect(events.any((x) => x.id == 'masik_durgashtami'), false);
      });
    }
    test('${loc.cityEn} Chaitra Ashtami and Navratri are included', () {
      expect(festival.findMajor(2026, loc, 'chaitra_durga_ashtami').localDate,
          DateTime.utc(2026, 3, 26));
      expect(festival.findMajor(2026, loc, 'chaitra_navratri').localDate,
          DateTime.utc(2026, 3, 19));
    });
  }
  test('Ordinary Shukla and Krishna Ashtami have no monthly festival label', () {
    const ashtami = NamedValue(8, 'अष्टमी', 'Ashtami');
    const month = NamedValue(2, 'वैशाख', 'Vaishakha');
    final date = DateTime.utc(2026, 4, 24);
    expect(sunriseObservances(date, const TithiState(ashtami, 'शुक्ल', 'Shukla', 8), month), isEmpty);
    expect(sunriseObservances(date, const TithiState(ashtami, 'कृष्ण', 'Krishna', 23), month), isEmpty);
  });
}
