import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';

void main() {
  const panchang = PanchangEngine();
  final delhi = locations.firstWhere((x) => x.id == 'delhi');
  final overrides = <int, DateTime>{2026: DateTime.utc(2026, 3, 3)};
  final festivals = FestivalEngine(panchang, holikaOverrides: overrides);
  final reference = jsonDecode(File('test/fixtures/festival_reference.json').readAsStringSync()) as Map<String, dynamic>;

  for (final year in [2026, 2027]) {
    test('$year major festivals match Python reference engine', () {
      final expected = <String, String>{for (final x in (reference['$year'] as List).cast<Map<String, dynamic>>()) x['id'] as String: x['local_date'] as String};
      final actual = {for (final x in festivals.majorFestivalsForYear(year, delhi)) x.id: '${x.localDate.year.toString().padLeft(4,'0')}-${x.localDate.month.toString().padLeft(2,'0')}-${x.localDate.day.toString().padLeft(2,'0')}'};
      for (final entry in expected.entries) {
        expect(actual[entry.key], entry.value, reason: entry.key);
      }
    });
  }
}
