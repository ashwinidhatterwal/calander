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

  test('grid fills available height and preserves a readable minimum', () {
    for (final rows in [4, 5, 6]) {
      for (final height in [600.0, 900.0, 1400.0]) {
        final tile = calendarTileHeight(
          viewportHeight: height,
          rows: rows,
          textScale: 1,
        );
        expect(tile * rows + (rows - 1) * 5 + 12, closeTo(height, .02));
      }
      for (final scale in [1.0, 1.5, 2.0, 3.0]) {
        expect(
          calendarTileHeight(viewportHeight: 100, rows: rows, textScale: scale),
          52 * scale,
        );
      }
    }
    expect(
      calendarTileHeight(
        viewportHeight: double.infinity,
        rows: 6,
        textScale: 1,
      ),
      52,
    );
  });

  testWidgets('month transitions show their Hindu month on the matching date', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const HinduCalendarApp(
        holikaOverrides: {},
        initialLanguage: AppLanguage.en,
      ),
    );
    await settleCalendar(tester);
    final primary = find.byKey(const ValueKey('primary-vikram-samvat'));
    final secondary = find.byKey(const ValueKey('secondary-gregorian-year'));
    final hinduMonth = find.byKey(const ValueKey('primary-hindu-month'));
    expect(hinduMonth, findsOneWidget);
    expect(tester.getTopLeft(hinduMonth).dy, lessThan(tester.getTopLeft(secondary).dy));
    expect(primary, findsOneWidget);
    expect(secondary, findsOneWidget);
    expect(tester.widget<Text>(primary).data, startsWith('Vikram Samvat '));
    expect(tester.getTopLeft(primary).dy, lessThan(tester.getTopLeft(secondary).dy));
    expect(tester.widget<Text>(primary).style!.fontWeight, FontWeight.w900);
    final now = DateTime.now();
    final dates = monthGridDates(DateTime.utc(now.year, now.month));
    const engine = PanchangEngine();
    for (final d in dates.where((d) => d.month == now.month)) {
      final cell = engine.monthCell(d, locations.first);
      final previous = engine.monthCell(
        d.subtract(const Duration(days: 1)),
        locations.first,
      );
      final changed =
          cell.month.index != previous.month.index ||
          cell.adhik != previous.adhik;
      final label = find.byKey(
        ValueKey('hindu-month-start-${d.year}-${d.month}-${d.day}'),
      );
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
  for (final size in [
    const Size(360, 740),
    const Size(400, 800),
    const Size(480, 1200),
  ]) {
    for (final language in AppLanguage.values) {
      testWidgets('six weeks fit ${size.width}x${size.height} ${language.name}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          HinduCalendarApp(holikaOverrides: {}, initialLanguage: language),
        );
        await settleCalendar(tester);
        final now = DateTime.now();
        var month = DateTime.utc(now.year, now.month);
        for (var step = 0; step < 14; step++) {
          final dates = monthGridDates(month);
          final grid = find.byType(GridView).first;
          final scroll = find.descendant(
            of: grid,
            matching: find.byType(Scrollable),
          );
          final state = tester.state<ScrollableState>(scroll);
          expect(
            state.position.maxScrollExtent,
            0,
            reason:
                'The final week must fit without scrolling at normal text size',
          );
          if (dates.length == 42) {
            final last = dates.last;
            final today =
                last.year == now.year &&
                last.month == now.month &&
                last.day == now.day;
            final tile = find.byKey(
              ValueKey(
                'calendar-cell-${last.year}-${last.month}-${last.day}-$today',
              ),
            );
            expect(tile, findsOneWidget);
            expect(
              tester.getBottomRight(tile).dy,
              lessThanOrEqualTo(tester.getBottomRight(grid).dy),
            );
            expect(tester.takeException(), isNull);
            break;
          }
          await tester.tap(
            find.widgetWithIcon(IconButton, Icons.chevron_right).first,
          );
          await settleCalendar(tester);
          month = DateTime.utc(month.year, month.month + 1);
          if (step == 13) fail('Did not reach a six-row month');
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
