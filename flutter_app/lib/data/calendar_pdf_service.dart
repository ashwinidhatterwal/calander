import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization.dart';
import '../domain/civil_holidays.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';

/// Uses the same sunrise calculations as the month grid. Personal events are
/// deliberately excluded from a calendar intended for sharing.
class CalendarPdfService {
  static const channel = MethodChannel('in.hinducalendar/calendar_pdf');
  static Future<void>? _font;
  static Future<void> loadFont() => _font ??= _loadFont();
  static Future<void> _loadFont() async {
    await (FontLoader('CalendarPdf')
          ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari.ttf')))
        .load();
    LicenseRegistry.addLicense(() async* {
      yield LicenseEntryWithLineBreaks(['Noto Sans Devanagari'],
          await rootBundle.loadString('assets/fonts/OFL.txt'));
    });
  }

  static Future<Uint8List> build({
    required DateTime month,
    required bool yearly,
    required AppLanguage language,
    required GeoLocation location,
    required PanchangEngine panchang,
    required FestivalEngine festival,
    ValueChanged<int>? onProgress,
  }) async {
    await loadFont();
    final l = L10n(language);
    final major = await festival.majorFestivalsAsync(month.year, location);
    final pdf = _ImagePdf();
    for (var index = 0; index < (yearly ? 12 : 1); index++) {
      final date = DateTime.utc(month.year, yearly ? index + 1 : month.month);
      final days = <Map<String, String>>[];
      for (var day = 1;
          day <= DateTime.utc(date.year, date.month + 1, 0).day;
          day++) {
        final d = DateTime.utc(date.year, date.month, day);
        final cell = panchang.monthCell(d, location);
        final raw =
            cell.tithi.index + (cell.pakshaHi.startsWith('शुक्ल') ? 0 : 15);
        final events = major
            .where(
              (x) =>
                  x.localDate.year == d.year &&
                  x.localDate.month == d.month &&
                  x.localDate.day == d.day,
            )
            .toList();
        final recurring = sunriseObservances(
          d,
          TithiState(cell.tithi, cell.pakshaHi, cell.pakshaEn, raw),
          cell.month,
        );
        final names = <String>{
          for (final e in events) l.pick(e.nameHi, e.nameEn),
          if (events.isEmpty)
            for (final e in recurring) l.pick(e.nameHi, e.nameEn),
          for (final h in nationalHolidays.where((h) => h.occursOn(d)))
            l.pick(h.nameHi, h.nameEn),
        };
        days.add({
          'day': '$day',
          'tithi': l.pick(cell.tithi.hi, cell.tithi.en),
          'paksha': l.pick(cell.pakshaHi, cell.pakshaEn),
          'events': names.join(' · '),
        });
      }
      final image = await renderMonth(date, days, language, location);
      try {
        final rgba = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        pdf.addPage(
          image.width,
          image.height,
          rgba.buffer.asUint8List(rgba.offsetInBytes, rgba.lengthInBytes),
        );
      } finally {
        image.dispose();
      }
      onProgress?.call(index + 1);
      // Let progress paint, and release the previous month's image before the next.
      await Future<void>.delayed(Duration.zero);
    }
    return pdf.save();
  }

  static Future<void> share(Uint8List bytes, String filename) => channel
      .invokeMethod<void>('share', {'bytes': bytes, 'filename': filename});

  /// A4 landscape at 144 dpi. Text is shaped by Flutter with a bundled Hindi
  /// font before embedding, so exported matras never depend on a PDF viewer.
  static Future<ui.Image> renderMonth(
    DateTime month,
    List<Map<String, String>> days,
    AppLanguage language,
    GeoLocation location,
  ) async {
    const width = 1684;
    const height = 1190;
    final l = L10n(language);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const ink = Color(0xFF442D23);
    const accent = Color(0xFFA8461B);
    const muted = Color(0xFF80695E);
    canvas.drawColor(const Color(0xFFFFFAF5), BlendMode.src);
    void text(
      String value,
      double x,
      double y,
      double w,
      double size, {
      Color color = ink,
      bool bold = false,
      int lines = 1,
      TextAlign align = TextAlign.left,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontFamily: 'CalendarPdf',
            fontSize: size,
            height: 1.18,
            color: color,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: align,
        maxLines: lines,
        ellipsis: '…',
      )..layout(minWidth: w, maxWidth: w);
      painter.paint(canvas, Offset(x, y));
      painter.dispose();
    }

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 1684, 10),
      Paint()..color = accent,
    );
    text(l.appName, 44, 29, 1000, 23, color: accent, bold: true);
    final names = language == AppLanguage.hi ? monthNamesHi : monthNamesEn;
    text(
      '${names[month.month - 1]} ${month.year}',
      44,
      65,
      1100,
      49,
      bold: true,
    );
    text(
      l.pick(location.cityHi, location.cityEn),
      1150,
      51,
      490,
      24,
      color: muted,
      align: TextAlign.right,
    );
    text(
      l.pick('सूर्योदय की तिथि • भारतीय समय', 'Tithi at sunrise • IST'),
      1040,
      90,
      600,
      18,
      color: muted,
      align: TextAlign.right,
    );
    const left = 44.0;
    const top = 182.0;
    const gap = 8.0;
    const cellW = (1596.0 - 6 * gap) / 7;
    final offset = month.weekday % 7;
    final rows = ((offset + days.length) / 7).ceil();
    final cellH = (880.0 - (rows - 1) * gap) / rows;
    final weekdays = language == AppLanguage.hi ? shortWeekHi : shortWeekEn;
    for (var col = 0; col < 7; col++) {
      text(
        weekdays[col],
        left + col * (cellW + gap),
        143,
        cellW,
        22,
        color: col == 0 ? accent : muted,
        bold: true,
        align: TextAlign.center,
      );
    }
    for (var i = 0; i < days.length; i++) {
      final slot = offset + i;
      final x = left + (slot % 7) * (cellW + gap);
      final y = top + (slot ~/ 7) * (cellH + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, cellW, cellH),
        const Radius.circular(12),
      );
      canvas.drawRRect(rect, Paint()..color = const Color(0xFFFFF0E5));
      canvas.drawRRect(
        rect,
        Paint()
          ..color = const Color(0xFFE8D5C7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      final day = days[i];
      text(day['tithi']!, x + 10, y + 9, cellW - 20, 24, bold: true, lines: 1);
      text(day['paksha']!, x + 10, y + 41, cellW - 20, 14, color: muted);
      if (day['events']!.isNotEmpty) {
        text(
          day['events']!,
          x + 10,
          y + 64,
          cellW - 20,
          16,
          color: accent,
          bold: true,
          lines: 2,
        );
      }
      text(
        day['day']!,
        x + 10,
        y + cellH - 40,
        cellW - 20,
        29,
        color: slot % 7 == 0 ? accent : ink,
        bold: true,
        align: TextAlign.right,
      );
    }
    canvas.drawLine(
      const Offset(44, 1090),
      const Offset(1640, 1090),
      Paint()..color = const Color(0xFFE8D5C7),
    );
    text(
      l.pick(
        'हिन्दू कैलेंडर • पंचांग, पर्व और तिथि अनुस्मारक',
        'Hindu Calendar • Panchang, festivals & tithi reminders',
      ),
      44,
      1107,
      1150,
      20,
      color: accent,
      bold: true,
    );
    text(
      l.pick(
        'Google Play पर हिन्दू कैलेंडर खोजें',
        'Find Hindu Calendar on Google Play',
      ),
      44,
      1140,
      1200,
      16,
      color: muted,
    );
    text(
      '${names[month.month - 1]} ${month.year}',
      1250,
      1120,
      390,
      18,
      color: muted,
      align: TextAlign.right,
    );
    final picture = recorder.endRecording();
    try {
      return await picture.toImage(width, height);
    } finally {
      picture.dispose();
    }
  }
}

/// Small PDF 1.4 writer: one losslessly compressed RGB image per A4 page.
/// The image approach preserves Indic shaping across all PDF viewers.
class _ImagePdf {
  final _objects = <Uint8List>[];
  final _pages = <int>[];
  _ImagePdf() {
    _objects.add(Uint8List(0)); // Catalog, filled when saving.
    _objects.add(Uint8List(0)); // Page tree.
  }
  Uint8List _ascii(String s) => Uint8List.fromList(ascii.encode(s));
  int _add(Uint8List bytes) {
    _objects.add(bytes);
    return _objects.length;
  }

  Uint8List _stream(String dict, List<int> bytes) => (BytesBuilder(copy: false)
        ..add(_ascii('<< $dict /Length ${bytes.length} >>\nstream\n'))
        ..add(bytes)
        ..add(_ascii('\nendstream')))
      .takeBytes();

  void addPage(int width, int height, Uint8List rgba) {
    final rgb = Uint8List(width * height * 3);
    for (var src = 0, dst = 0; src < rgba.length; src += 4) {
      rgb[dst++] = rgba[src];
      rgb[dst++] = rgba[src + 1];
      rgb[dst++] = rgba[src + 2];
    }
    final image = _add(
      _stream(
        '/Type /XObject /Subtype /Image /Width $width '
        '/Height $height /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode',
        zlib.encode(rgb),
      ),
    );
    final content = _add(_stream('', _ascii('q 842 0 0 595 0 0 cm /Im0 Do Q')));
    final link = _add(
      _ascii(
        '<< /Type /Annot /Subtype /Link /Rect [22 12 620 46] '
        '/Border [0 0 0] /A << /S /URI /URI '
        '(https://play.google.com/store/apps/details?id=in.hinducalendar.hindu_calendar) >> >>',
      ),
    );
    _pages.add(
      _add(
        _ascii(
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 842 595] '
          '/Resources << /XObject << /Im0 $image 0 R >> >> /Contents $content 0 R /Annots [$link 0 R] >>',
        ),
      ),
    );
  }

  Uint8List save() {
    _objects[0] = _ascii('<< /Type /Catalog /Pages 2 0 R >>');
    _objects[1] = _ascii(
      '<< /Type /Pages /Count ${_pages.length} /Kids '
      '[${_pages.map((p) => '$p 0 R').join(' ')}] >>',
    );
    final out = BytesBuilder(copy: false)..add(_ascii('%PDF-1.4\n'));
    final offsets = <int>[0];
    for (var i = 0; i < _objects.length; i++) {
      offsets.add(out.length);
      out
        ..add(_ascii('${i + 1} 0 obj\n'))
        ..add(_objects[i])
        ..add(_ascii('\nendobj\n'));
    }
    final xref = out.length;
    out.add(_ascii('xref\n0 ${offsets.length}\n0000000000 65535 f \n'));
    for (final offset in offsets.skip(1)) {
      out.add(_ascii('${offset.toString().padLeft(10, '0')} 00000 n \n'));
    }
    out.add(
      _ascii(
        'trailer\n<< /Size ${offsets.length} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF\n',
      ),
    );
    return out.takeBytes();
  }
}
