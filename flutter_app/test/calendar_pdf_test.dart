import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/data/calendar_pdf_service.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/main.dart';

import 'async_calendar_helper.dart';

void main() {
  for (final language in AppLanguage.values) {
    testWidgets(
      'PDF ${language.name}: six-row month and leap-year 12-page export',
      (tester) async {
        await tester.runAsync(() async {
          final engine = PanchangEngine();
          final festivals = FestivalEngine(engine);
          for (final yearly in [false, true]) {
            final progress = <int>[];
            final bytes = await CalendarPdfService.build(
              month: DateTime.utc(2024, 3),
              yearly: yearly,
              language: language,
              location: locations.first,
              panchang: engine,
              festival: festivals,
              onProgress: progress.add,
            );
            final text = latin1.decode(bytes);
            final count = yearly ? 12 : 1;
            expect(text.startsWith('%PDF-1.4'), isTrue);
            expect(RegExp(r'/Type /Page\s').allMatches(text).length, count);
            expect(progress, List.generate(count, (i) => i + 1));
            expect(text, contains('/Count $count '));
            expect(text, contains('/MediaBox [0 0 842 595]'));
            expect(
              text,
              contains(
                'play.google.com/store/apps/details?id=in.hinducalendar.hindu_calendar',
              ),
            );
            // This date forces six rows; leap-year yearly export includes Feb 29.
            final previewDir = Platform.environment['CALENDAR_PDF_PREVIEW_DIR'];
            if (previewDir != null) {
              await Directory(previewDir).create(recursive: true);
              await File(
                '$previewDir/${language.name}-${yearly ? 'year' : 'month'}.pdf',
              ).writeAsBytes(bytes);
            }
          }
        });
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  }

  testWidgets(
    'month card puts bold tithi above bottom date and offers PDF choices',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const HinduCalendarApp(
          holikaOverrides: {},
          initialLanguage: AppLanguage.en,
        ),
      );
      await settleCalendar(tester);
      final now = DateTime.now();
      final cell = find.byKey(
        ValueKey('calendar-cell-${now.year}-${now.month}-1-${now.day == 1}'),
      );
      final labels = find.descendant(of: cell, matching: find.byType(Text));
      final tithi = labels.first;
      final date = find.descendant(of: cell, matching: find.text('1'));
      expect(tester.getTopLeft(tithi).dy, lessThan(tester.getTopLeft(date).dy));
      expect(tester.widget<Text>(tithi).style!.fontWeight, FontWeight.w800);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share calendar PDF'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly calendar'), findsOneWidget);
      expect(find.text('Yearly calendar'), findsOneWidget);
      expect(find.textContaining('12 pages'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
