import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/data/daily_discoveries.dart';
import 'package:hindu_calendar/screens/discover_screen.dart';

void main() {
  test('anniversaries match dates and never appear before their event', () {
    expect(
      DailyDiscoveries.onThisDay(DateTime(2026, 10, 29)).single.id,
      'internet',
    );
    expect(DailyDiscoveries.onThisDay(DateTime(1968, 10, 29)), isEmpty);
    expect(DailyDiscoveries.onThisDay(DateTime(2026, 8, 23)).single.id, 'moon');
    expect(DailyDiscoveries.onThisDay(DateTime(2026, 10, 30)), isEmpty);
  });

  test('every civil day including leap day has a stable cultural card', () {
    final ids = <String>{};
    for (var i = 0; i < 366; i++) {
      final day = DateTime.utc(2028, 1, 1).add(Duration(days: i));
      final fact = DailyDiscoveries.cultureFor(day);
      expect(fact.isDated, isFalse);
      expect(
        fact.id,
        DailyDiscoveries.cultureFor(DateTime(day.year, day.month, day.day, 23))
            .id,
      );
      expect(
        fact.id,
        isNot(DailyDiscoveries.cultureFor(day.add(const Duration(days: 1))).id),
      );
      ids.add(fact.id);
    }
    expect(
      ids.length,
      DailyDiscoveries.entries.where((e) => !e.isDated).length,
    );
  });

  test(
    'editorial records have unique IDs, bilingual copy and HTTPS sources',
    () {
      expect(
        DailyDiscoveries.entries.map((e) => e.id).toSet().length,
        DailyDiscoveries.entries.length,
      );
      for (final fact in DailyDiscoveries.entries) {
        expect([
          fact.titleHi,
          fact.titleEn,
          fact.bodyHi,
          fact.bodyEn,
          fact.source,
        ], everyElement(isNotEmpty));
        expect(Uri.parse(fact.url).scheme, 'https');
        if (fact.isDated) {
          final date = DateTime(2028, fact.month!, fact.day!);
          expect(date.month, fact.month);
          expect(date.day, fact.day);
        }
      }
    },
  );

  testWidgets(
    'compact screen scrolls at large text and refreshes when reopened',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026, 10, 29, 12);
      DateTime clock() => now;
      Widget app(bool active, AppLanguage language) => MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: DiscoverScreen(
              language: language,
              active: active,
              clock: clock,
            ),
          ),
        ),
      );
      await tester.pumpWidget(app(true, AppLanguage.en));
      await tester.scrollUntilVisible(
        find.text('An early step towards the internet'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('An early step towards the internet'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(app(false, AppLanguage.en));
      now = DateTime(2026, 10, 30, 12);
      await tester.pumpWidget(app(true, AppLanguage.hi));
      await tester.scrollUntilVisible(find.text('आज का ज्ञान'), -300, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      expect(find.text('आज का ज्ञान'), findsOneWidget);
      expect(find.text('An early step towards the internet'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
