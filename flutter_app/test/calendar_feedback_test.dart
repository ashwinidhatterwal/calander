import 'async_calendar_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/main.dart';
import 'package:hindu_calendar/core/localization.dart';

void main() {
  testWidgets('tap-return and month navigation preserve Today only', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const HinduCalendarApp(holikaOverrides: {}));
    await settleCalendar(tester);
    final now = DateTime.now();
    final other = now.day == 1 ? 2 : 1;
    final todayKey = ValueKey(
      'calendar-cell-${now.year}-${now.month}-${now.day}-true',
    );
    final otherKey = ValueKey(
      'calendar-cell-${now.year}-${now.month}-$other-false',
    );
    expect(find.byKey(todayKey), findsOneWidget);
    await tester.ensureVisible(find.byKey(otherKey));
    await tester.tap(find.byKey(otherKey));
    await settleCalendar(tester);
    final context = tester.element(find.byType(BackButton).first);
    Navigator.of(context).pop();
    await settleCalendar(tester);
    expect(find.byKey(todayKey), findsOneWidget);
    expect(find.byKey(otherKey), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('today-panchang-card')),
        matching: find.textContaining('आज ·')), findsOneWidget);
    await tester.tap(find.widgetWithIcon(IconButton, Icons.chevron_right).first);
    await settleCalendar(tester);
    final next = DateTime.utc(now.year, now.month + 1, 1);
    expect(
      find.byKey(ValueKey('calendar-cell-${next.year}-${next.month}-1-false')),
      findsOneWidget,
    );
    expect(
      find.byKey(ValueKey('calendar-cell-${next.year}-${next.month}-1-true')),
      findsNothing,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('national holidays have their own bilingual category', (
    tester,
  ) async {
    await tester.pumpWidget(const HinduCalendarApp(holikaOverrides: {}));
    await settleCalendar(tester);
    await tester.tap(find.byIcon(Icons.celebration_outlined));
    await settleCalendar(tester);
    await tester.tap(find.text('अवकाश'));
    await tester.tap(find.text('पूरा वर्ष'));
    await settleCalendar(tester);
    expect(find.text('गणतंत्र दिवस'), findsOneWidget);
    expect(find.text('स्वतंत्रता दिवस'), findsOneWidget);
    expect(find.text('गांधी जयंती'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('month/year picker does not highlight its first day', (tester) async {
    await tester.binding.setSurfaceSize(const Size(480, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const HinduCalendarApp(holikaOverrides: {},
        initialLanguage: AppLanguage.en));
    await settleCalendar(tester);
    await tester.tap(find.byIcon(Icons.arrow_drop_down).first);
    await settleCalendar(tester);
    final now = DateTime.now();
    final month = now.month == 12 ? 11 : now.month + 1;
    const names = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    await tester.tap(find.text(names[month - 1]).last);
    await settleCalendar(tester);
    expect(find.byKey(ValueKey('calendar-cell-${now.year}-$month-1-false')), findsOneWidget);
    expect(find.byKey(ValueKey('calendar-cell-${now.year}-$month-1-true')), findsNothing);
    expect(find.descendant(of: find.byKey(const ValueKey('today-panchang-card')),
        matching: find.textContaining('Today ·')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

}
