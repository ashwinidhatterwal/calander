import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/data/daily_discoveries.dart';

void main() {
  test(
      'three daily sections remain distinct and rotate with specific wisdom readings',
      () {
    expect(DailyDiscoveries.entries.length, 137);
    String? previousPhilosophy, previousFact;
    for (var i = 0; i < 365; i++) {
      final date = DateTime(2026, 1, 1).add(Duration(days: i));
      final sections = DailyDiscoveries.dailySections(
          date: date, hinduMonth: 8, rawTithi: 5);
      expect(
          {sections.spiritual.id, sections.philosophy.id, sections.fact.id}
              .length,
          3);
      expect(
          DailyDiscoveries.philosophyIds.contains(sections.philosophy.id) ||
              sections.philosophy.section == 'philosophy',
          isTrue);
      expect(sections.philosophy.id, isNot(previousPhilosophy));
      if (sections.anniversary) {
        expect(sections.fact.month, date.month);
        expect(sections.fact.day, date.day);
      } else {
        expect(sections.fact.isDated, isFalse);
        expect(sections.fact.id, isNot(previousFact));
      }
      previousPhilosophy = sections.philosophy.id;
      previousFact = sections.fact.id;
    }
  });

  test('every new reading is reachable and attributed, with varied teachers',
      () {
    final expected =
        DailyDiscoveries.entries.where((e) => e.section.isNotEmpty);
    expect(expected.length, 48);
    final seen = <String>{};
    String? previousGroup;
    for (var i = 0; i < 360; i++) {
      final sections = DailyDiscoveries.dailySections(
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
          hinduMonth: 0,
          rawTithi: 0);
      seen.addAll([sections.spiritual.id, sections.philosophy.id]);
      final group = sections.philosophy.group.isEmpty
          ? 'gita'
          : sections.philosophy.group;
      expect(group, isNot(previousGroup));
      previousGroup = group;
    }
    for (final entry in expected) {
      expect(seen, contains(entry.id), reason: 'unreachable reading');
      expect(
          [
            entry.teacherHi,
            entry.teacherEn,
            entry.reference,
            entry.promptHi,
            entry.promptEn
          ].every((value) => value.isNotEmpty),
          isTrue);
      expect(Uri.parse(entry.url).scheme, 'https');
      expect(entry.isDated, isFalse);
    }
    expect(expected.where((e) => e.group == 'kautilya').length, 10);
  });

  test('spiritual section still prioritizes actual festival and tithi', () {
    final festival = DailyDiscoveries.dailySections(
        date: DateTime(2026, 3, 27),
        hinduMonth: 1,
        rawTithi: 3,
        festivals: {'rama_navami'});
    expect(festival.spiritual.id, 'rama-reading');
    final tithi = DailyDiscoveries.dailySections(
        date: DateTime(2026, 3, 27), hinduMonth: 1, rawTithi: 3);
    expect(tithi.spiritual.id, 'gangaur');
  });

  test('each month has content; hierarchy and deduplication are stable', () {
    for (var month = 1; month <= 12; month++) {
      final selected = DailyDiscoveries.select(
        date: DateTime(2026, 1, 8),
        hinduMonth: month,
        rawTithi: 6,
      );
      expect(selected.first.reason, 'month');
      expect(selected.first.entry.hinduMonths, contains(month));
      expect(selected.map((e) => e.entry.id).toSet().length, selected.length);
    }
    final selected = DailyDiscoveries.select(
      date: DateTime(2026, 3, 27),
      hinduMonth: 1,
      rawTithi: 3,
      festivals: {'rama_navami'},
    );
    expect(selected.first.entry.id, 'rama-reading');
    expect(selected.first.reason, 'festival');
    expect(selected.firstWhere((e) => e.entry.id == 'gangaur').reason, 'tithi');
  });
  test('adhik month does not label annual tithi as today’s observance', () {
    final selected = DailyDiscoveries.select(
      date: DateTime(2026, 1, 8),
      hinduMonth: 1,
      rawTithi: 3,
      adhik: true,
    );
    expect(selected.any((e) => e.reason == 'tithi'), isFalse);
  });
  test('unknown month falls back to daily cultural reading', () {
    final selected = DailyDiscoveries.select(
      date: DateTime(2026, 1, 8),
      hinduMonth: 0,
      rawTithi: 0,
    );
    expect(selected.first.reason, 'general');
    expect(selected.length, greaterThanOrEqualTo(75));
  });
}
