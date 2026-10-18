import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/data/calendar_pdf_service.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';

// Standalone engine verification also works without a test-runner network port.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final output = Directory(Platform.environment['CALENDAR_PDF_PREVIEW_DIR'] ??
        '/tmp/calendar-pdf-preview');
    await output.create(recursive: true);
    final engine = PanchangEngine();
    final festivals = FestivalEngine(engine);
    for (final language in AppLanguage.values) {
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
        final data = latin1.decode(bytes);
        final expected = yearly ? 12 : 1;
        if (RegExp(r'/Type /Page\s').allMatches(data).length != expected ||
            progress.length != expected ||
            !data.startsWith('%PDF-1.4')) {
          throw StateError('PDF page count or export progress failed');
        }
        final file = File(
            '${output.path}/${language.name}-${yearly ? 'year' : 'month'}.pdf');
        await file.writeAsBytes(bytes);
        stdout.writeln(
            'PASS ${language.name} $expected pages, ${bytes.length} bytes');
      }
    }
    exit(0);
  } catch (error, stack) {
    stdout.writeln('$error\n$stack');
    exit(1);
  }
}
