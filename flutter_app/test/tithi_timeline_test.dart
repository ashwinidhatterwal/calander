import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/domain/tithi_timeline.dart';
import 'package:hindu_calendar/core/locations.dart';

void main() {
  test('civil timeline is continuous and includes two-transition days', () {
    const engine = PanchangEngine();
    final location = locations.first;
    var foundThree = false;
    for (var i = 0; i < 366; i++) {
      final date = DateTime.utc(2026, 1, 1).add(Duration(days: i));
      final parts = civilTithiTimeline(engine, date, location);
      expect(parts.first.fromUtc, date.subtract(location.offset));
      expect(
        parts.last.toUtc,
        date.add(const Duration(days: 1)).subtract(location.offset),
      );
      expect(parts.where((e) => e.atSunrise).length, 1);
      for (var j = 0; j < parts.length; j++) {
        expect(parts[j].toUtc.isAfter(parts[j].fromUtc), isTrue);
        if (j > 0) {
          expect(parts[j].fromUtc, parts[j - 1].toUtc);
          expect(parts[j].state.rawIndex, parts[j - 1].state.rawIndex % 30 + 1);
        }
      }
      if (parts.length == 3) foundThree = true;
    }
    expect(foundThree, isTrue);
  });
}
