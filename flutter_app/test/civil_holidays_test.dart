import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/domain/civil_holidays.dart';

void main() {
  test('three bilingual national holidays repeat on fixed civil dates', () {
    expect(nationalHolidays.length, 3);
    for (final year in [2024, 2026, 2027, 2100]) {
      expect(nationalHolidays.map((h) => h.dateInYear(year)), [
        DateTime.utc(year, 1, 26),
        DateTime.utc(year, 8, 15),
        DateTime.utc(year, 10, 2),
      ]);
      for (final holiday in nationalHolidays) {
        expect(holiday.nameHi, isNotEmpty);
        expect(holiday.nameEn, isNotEmpty);
        expect(holiday.occursOn(holiday.dateInYear(year)), isTrue);
        expect(
          holiday.occursOn(
            holiday.dateInYear(year).add(const Duration(days: 1)),
          ),
          isFalse,
        );
      }
    }
  });
}
