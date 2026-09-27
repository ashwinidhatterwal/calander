import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';

void main() {
  const engine = PanchangEngine();
  final byId = {for (final x in locations) x.id: x};

  test('Dart Panchang engine matches Python reference fixtures', () {
    final rows = (jsonDecode(File('test/fixtures/panchang_reference.json').readAsStringSync()) as List).cast<Map<String, dynamic>>();
    for (final row in rows) {
      final loc = byId[row['location_key']]!;
      final d = DateTime.parse(row['local_date'] as String);
      final actual = engine.buildDay(DateTime.utc(d.year, d.month, d.day), loc);
      expect(actual.weekdayEn, row['weekday_en'], reason: '${row['local_date']} weekday');
      expect(actual.tithi.en, row['tithi']['en'], reason: '${row['local_date']} tithi');
      expect(actual.pakshaEn, row['paksha_en'], reason: '${row['local_date']} paksha');
      expect(actual.nakshatra.en, row['nakshatra']['en'], reason: '${row['local_date']} nakshatra');
      expect(actual.yoga.en, row['yoga']['en'], reason: '${row['local_date']} yoga');
      expect(actual.karana.en, row['karana']['en'], reason: '${row['local_date']} karana');
      expect(actual.amantaMonth.en, row['amanta_month']['en'], reason: '${row['local_date']} amanta');
      expect(actual.purnimantaMonth.en, row['purnimanta_month']['en'], reason: '${row['local_date']} purnimanta');
      expect(actual.adhikMonth, row['adhik_month'], reason: '${row['local_date']} adhik');
      expect(actual.tithiStatus, row['tithi_status'], reason: '${row['local_date']} anomaly');
      expect(actual.vikramSamvat, row['vikram_samvat']);
      expect(actual.shakaSamvat, row['shaka_samvat']);
      expect(actual.sunRashi.en, row['sun_rashi']['en']);
      expect(actual.moonRashi.en, row['moon_rashi']['en']);

      void near(DateTime got, String expected, String label, {int toleranceSeconds = 5}) {
        final want = DateTime.parse(expected).toUtc();
        expect(got.toUtc().difference(want).inSeconds.abs(), lessThanOrEqualTo(toleranceSeconds), reason: '${row['local_date']} $label');
      }
      near(actual.sunriseUtc, row['sunrise'], 'sunrise', toleranceSeconds: 2);
      near(actual.sunsetUtc, row['sunset'], 'sunset', toleranceSeconds: 2);
      near(actual.tithiEndUtc, row['tithi_end'], 'tithi end', toleranceSeconds: 2);
      near(actual.nakshatraEndUtc, row['nakshatra_end'], 'nakshatra end', toleranceSeconds: 2);
      near(actual.yogaEndUtc, row['yoga_end'], 'yoga end', toleranceSeconds: 2);
      near(actual.karanaEndUtc, row['karana_end'], 'karana end', toleranceSeconds: 2);
      if (row['moonrise'] != null && actual.moonriseUtc != null) near(actual.moonriseUtc!, row['moonrise'], 'moonrise', toleranceSeconds: 4);
      if (row['moonset'] != null && actual.moonsetUtc != null) near(actual.moonsetUtc!, row['moonset'], 'moonset', toleranceSeconds: 4);
    }
  });

  test('J2000 Julian Day reference', () {
    expect((engine.julianDay(DateTime.utc(2000, 1, 1, 12)) - 2451545.0).abs(), lessThan(1e-9));
  });
}
