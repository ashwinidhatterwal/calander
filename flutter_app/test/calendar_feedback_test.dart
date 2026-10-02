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

  for (final language in AppLanguage.values) {
    testWidgets('combined Holidays list shows national entries in ${language.name}',
        (tester) async {
      await tester.pumpWidget(HinduCalendarApp(
        holikaOverrides: {}, initialLanguage: language,
      ));
      await settleCalendar(tester);
      await tester.tap(find.byIcon(Icons.celebration_outlined));
      await settleCalendar(tester);
      final hindi = language == AppLanguage.hi;
      await tester.tap(find.text(hindi ? 'अवकाश' : 'Holidays'));
      await tester.tap(find.text(hindi ? 'पूरा वर्ष' : 'Full year'));
      await settleCalendar(tester);
      final scrollable = find.descendant(
        of: find.byType(ListView), matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);
      for (final name in hindi
          ? ['गणतंत्र दिवस', 'स्वतंत्रता दिवस', 'गांधी जयंती']
          : ['Republic Day', 'Independence Day', 'Gandhi Jayanti']) {
        // The combined regional list builds off-screen entries lazily.
        await tester.scrollUntilVisible(
          find.text(name), 200, scrollable: scrollable, maxScrolls: 60,
        );
        await tester.pumpAndSettle();
        expect(find.text(name), findsOneWidget);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final language in AppLanguage.values) {
    testWidgets('Today sunrise and sunset use local 12-hour suffixes in ${language.name}',
        (tester) async {
      await tester.pumpWidget(HinduCalendarApp(
          holikaOverrides: {}, initialLanguage: language));
      await settleCalendar(tester);
      final hindi = language == AppLanguage.hi;
      final card = find.byKey(const ValueKey('today-panchang-card'));
      expect(find.descendant(of: card, matching: find.textContaining(
          RegExp(hindi ? r'सूर्योदय [0-9]{1,2}:[0-9]{2} पु\.'
              : r'Sunrise [0-9]{1,2}:[0-9]{2} AM'))), findsOneWidget);
      expect(find.descendant(of: card, matching: find.textContaining(
          RegExp(hindi ? r'सूर्यास्त [0-9]{1,2}:[0-9]{2} अप\.'
              : r'Sunset [0-9]{1,2}:[0-9]{2} PM'))), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }

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
