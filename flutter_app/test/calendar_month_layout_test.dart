import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/calendar_layout.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/main.dart';
import 'async_calendar_helper.dart';

void main() {
  test('four, five and six-row months stop after their last occupied week', () {
    expect(monthGridDates(DateTime.utc(2026, 2)).length, 28);
    expect(monthGridDates(DateTime.utc(2024, 2)).length, 35);
    expect(monthGridDates(DateTime.utc(2024, 3)).length, 42);
    for (var year = 2024; year <= 2036; year++) {
      for (var month = 1; month <= 12; month++) {
        final dates = monthGridDates(DateTime.utc(year, month));
        final last = DateTime.utc(year, month + 1, 0);
        expect(dates.first.weekday, DateTime.sunday);
        expect(dates.last.weekday, DateTime.saturday);
        expect(dates.contains(last), isTrue);
        expect(dates.last.difference(last).inDays, inInclusiveRange(0, 6));
        expect(dates.where((d) => d.month == month).length, last.day);
        expect(dates.length % 7, 0);
      }
    }
  });

  testWidgets('month transitions show their Hindu month on the matching date',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const HinduCalendarApp(
        holikaOverrides: {}, initialLanguage: AppLanguage.en));
    await settleCalendar(tester);
    final now = DateTime.now();
    final dates = monthGridDates(DateTime.utc(now.year, now.month));
    const engine = PanchangEngine();
    for (final d in dates.where((d) => d.month == now.month)) {
      final cell = engine.monthCell(d, locations.first);
      final previous = engine.monthCell(
          d.subtract(const Duration(days: 1)), locations.first);
      final changed = cell.month.index != previous.month.index ||
          cell.adhik != previous.adhik;
      final label = find
          .byKey(ValueKey('hindu-month-start-${d.year}-${d.month}-${d.day}'));
      expect(label, changed ? findsOneWidget : findsNothing);
      if (changed) {
        expect(tester.widget<Text>(label).data, contains(cell.month.en));
      }
    }
    final grid = tester.widget<GridView>(find.byType(GridView).first);
    final delegate = grid.childrenDelegate as SliverChildBuilderDelegate;
    expect(delegate.childCount, dates.length);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
