import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/data/daily_discoveries.dart';

void main() {
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
