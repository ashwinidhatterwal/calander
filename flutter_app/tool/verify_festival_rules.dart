// Published North India fixtures; source links and scope: docs/CHECKPOINT_26.md.
// Uses the production synchronous calculation code, without mocking astronomy.
import 'dart:io';
import '../lib/domain/festival_engine.dart';
import '../lib/domain/models.dart';
import '../lib/domain/panchang_engine.dart';

void _check(bool ok, String message) {
  if (!ok) {
    throw StateError(message);
  }
}

int verifyFestivalRules() {
  const p = PanchangEngine();
  const locations = [
    GeoLocation(
      id: 'hanumangarh',
      cityHi: 'हनुमानगढ़',
      cityEn: 'Hanumangarh',
      latitude: 29.58,
      longitude: 74.29,
    ),
    GeoLocation(
      id: 'delhi',
      cityHi: 'दिल्ली',
      cityEn: 'Delhi',
      latitude: 28.6139,
      longitude: 77.209,
    ),
    GeoLocation(
      id: 'jaipur',
      cityHi: 'जयपुर',
      cityEn: 'Jaipur',
      latitude: 26.9124,
      longitude: 75.7873,
    ),
  ];
  const references = [
    ('vijayadashami', 2025, 10, 2),
    ('vijayadashami', 2026, 10, 20),
    ('vijayadashami', 2027, 10, 9),
    ('vijayadashami', 2028, 9, 27),
    ('sharad_purnima', 2025, 10, 6),
    ('sharad_purnima', 2026, 10, 25),
    ('sharad_purnima', 2027, 10, 14),
    ('sharad_purnima', 2028, 10, 2),
    ('karwa_chauth', 2025, 10, 10),
    ('govardhan_puja', 2028, 10, 18),
    ('govardhan_puja', 2029, 11, 6),
    ('dhanteras', 2029, 11, 4),
    ('janmashtami', 2025, 8, 15),
  ];
  var checks = 0;
  for (final loc in locations) {
    final f = FestivalEngine(
      p,
      holikaOverrides: {2026: DateTime.utc(2026, 3, 3)},
    );
    for (final (id, year, month, day) in references) {
      final actual = f.findMajor(year, loc, id).localDate;
      _check(
        actual == DateTime.utc(year, month, day),
        '${loc.cityEn} $year $id: $actual',
      );
      checks++;
    }
    final major = f.majorFestivalsForYear(2026, loc);
    final purnimaDay = DateTime.utc(2026, 10, 25);
    _check(
      f
          .lightweightForDate(purnimaDay, loc, major: major)
          .any((x) => x.id == 'sharad_purnima'),
      'Sharad festival missing',
    );
    final full = p.tithisForDay(purnimaDay, loc);
    _check(
      full.first.tithi.en == 'Chaturdashi' && full[1].tithi.en == 'Purnima',
      'Sharad day transitions',
    );
    final d = p.tithisForDay(DateTime.utc(2026, 10, 20), loc);
    _check(
      d.first.tithi.en == 'Navami' && d[1].tithi.en == 'Dashami',
      'Dussehra day transitions',
    );
    _check(
      major.singleWhere((x) => x.id == 'vijayadashami').localDate ==
          DateTime.utc(2026, 10, 20),
      'Do not shift Dussehra to the sunrise Dashami day',
    );
    checks += 4;
    for (var year = 2024; year <= 2030; year++) {
      final list = f.majorFestivalsForYear(year, loc);
      for (final rule in majorRules) {
        _check(
          list.where((x) => x.id == rule.id).length == 1,
          '${loc.cityEn} $year ${rule.id} missing/duplicated',
        );
        checks++;
      }
    }
    // Include vriddhi/kshaya boundaries: every displayed sequence must follow
    // real transitions and remain within the selected sunrise-to-sunrise day.
    for (var i = 0; i < 366; i++) {
      final date = DateTime.utc(2026, 1, 1).add(Duration(days: i));
      final parts = p.tithisForDay(date, loc);
      final end = p.sunriseSunset(p.nextCivilDay(date), loc)[0];
      _check(
        parts.isNotEmpty &&
            parts.first.startsUtc == p.sunriseSunset(date, loc)[0],
        'Timeline sunrise',
      );
      _check(!parts.last.endsUtc.isBefore(end), 'Timeline does not cover day');
      for (var j = 1; j < parts.length; j++) {
        _check(
          parts[j].startsUtc.difference(parts[j - 1].endsUtc).inMilliseconds ==
              1,
          'Timeline boundary',
        );
        _check(
          parts[j].startsUtc.isBefore(end),
          'Next-day tithi included too early',
        );
      }
      checks++;
    }
  }
  return checks;
}

void main() {
  stdout.writeln(
    'PASS ${verifyFestivalRules()} published-date, completeness and transition checks',
  );
}
