import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
        final requests = <Map<Object?, Object?>>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          CalendarPdfService.channel,
          (call) async {
            expect(call.method, 'buildVector');
            final arguments = Map<Object?, Object?>.from(call.arguments as Map);
            requests.add(arguments);
            return Uint8List.fromList(ascii.encode('%PDF-native-test'));
          },
        );
        addTearDown(() => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(CalendarPdfService.channel, null));
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
            expect(ascii.decode(bytes), '%PDF-native-test');
            final count = yearly ? 12 : 1;
            final request = requests.last;
            final pages = request['pages'] as List;
            expect(pages.length, count);
            expect(progress, List.generate(count, (i) => i + 1));
            expect(request['playStoreUrl'], CalendarPdfService.playStoreUrl);
            final march = pages[yearly ? 2 : 0] as Map;
            expect(march['offset'], 5);
            expect((march['days'] as List).length, 31);
            expect((march['days'] as List).first['tithi'], isNotEmpty);
            expect(march['weekdays'], hasLength(7));
            if (yearly) {
              final february = pages[1] as Map;
              expect((february['days'] as List).length, 29);
            }
            final dir = Platform.environment['CALENDAR_PDF_PAYLOAD_DIR'];
            if (dir != null) {
              await Directory(dir).create(recursive: true);
              await File(
                      '$dir/${language.name}-${yearly ? 'year' : 'month'}.json')
                  .writeAsString(jsonEncode(request));
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
