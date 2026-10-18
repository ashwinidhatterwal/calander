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
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=in.hinducalendar.hindu_calendar';
  static Future<ui.Image>? _qr;
  static Future<ui.Image>? _icon;
  static Future<ui.Image> _assetImage(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

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
        final detail = panchang.buildDay(d, location);
        String time(DateTime utc) => panchang.time12(utc, location,
            amLabel: l.pick('पु.', 'AM'), pmLabel: l.pick('अप.', 'PM'));
        final nextDay =
            panchang.localDateOfUtc(detail.tithiEndUtc, location).isAfter(d);
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
          'hinduMonth':
              '${cell.adhik ? '${l.adhik} ' : ''}${l.pick(cell.month.hi, cell.month.en)}',
          'samvat': '${detail.vikramSamvat}',
          'nakshatra': l.pick(detail.nakshatra.hi, detail.nakshatra.en),
          'sunrise': time(detail.sunriseUtc),
          'sunset': time(detail.sunsetUtc),
          'tithiEnd': '${time(detail.tithiEndUtc)}${nextDay ? ' +1' : ''}',
        });
        if (day % 7 == 0) await Future<void>.delayed(Duration.zero);
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

  /// Portrait A4 at 144 dpi, with pre-shaped Indic text and a permanent
  /// store-listing QR rather than a URL tied to a particular release artifact.
  static Future<ui.Image> renderMonth(
      DateTime month,
      List<Map<String, String>> days,
      AppLanguage language,
      GeoLocation location) async {
    final qr = await (_qr ??= _assetImage('assets/branding/play_store_qr.png'));
    final icon = await (_icon ??= _assetImage('assets/branding/app_icon.png'));
    const width = 1190;
    const height = 1684;
    final l = L10n(language);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const ink = Color(0xFF442D23);
    const accent = Color(0xFFA8461B);
    const muted = Color(0xFF80695E);
    canvas.drawColor(const Color(0xFFFFFAF5), BlendMode.src);
    void text(String value, double x, double y, double w, double size,
        {Color color = ink,
        bool bold = false,
        int lines = 1,
        TextAlign align = TextAlign.left}) {
      final painter = TextPainter(
        text: TextSpan(
            text: value,
            style: TextStyle(
                fontFamily: 'CalendarPdf',
                fontSize: size,
                height: 1.18,
                color: color,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
        textDirection: TextDirection.ltr,
        textAlign: align,
        maxLines: lines,
        ellipsis: '…',
      )..layout(minWidth: w, maxWidth: w);
      painter.paint(canvas, Offset(x, y));
      painter.dispose();
    }

    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1190, 9), Paint()..color = accent);
    text(l.appName, 36, 26, 700, 23, color: accent, bold: true);
    text(l.pick(location.cityHi, location.cityEn), 760, 27, 394, 18,
        color: muted, align: TextAlign.right);
    final hinduMonths = days.map((d) => d['hinduMonth']!).toSet().join(' • ');
    text('$hinduMonths ${l.month}', 36, 65, 1118, 38, bold: true);
    final names = language == AppLanguage.hi ? monthNamesHi : monthNamesEn;
    text('${names[month.month - 1]} ${month.year}', 36, 116, 1118, 30,
        color: accent, bold: true);
    final years = days.map((d) => d['samvat']!).toSet().join('–');
    text(l.pick('विक्रम संवत $years', 'Vikram Samvat $years'), 36, 165, 600, 17,
        color: muted);
    text(l.pick('सूर्योदय की तिथि • भारतीय समय', 'Tithi at sunrise • IST'), 590,
        165, 564, 17,
        color: muted, align: TextAlign.right);
    const left = 36.0, top = 248.0, gap = 6.0;
    const cellW = (1118.0 - 6 * gap) / 7;
    final offset = month.weekday % 7;
    final rows = ((offset + days.length) / 7).ceil();
    final cellH = (1128.0 - (rows - 1) * gap) / rows;
    final weekdays = language == AppLanguage.hi ? shortWeekHi : shortWeekEn;
    for (var col = 0; col < 7; col++) {
      text(weekdays[col], left + col * (cellW + gap), 210, cellW, 19,
          color: col == 0 ? accent : muted,
          bold: true,
          align: TextAlign.center);
    }
    for (var i = 0; i < days.length; i++) {
      final slot = offset + i;
      final x = left + (slot % 7) * (cellW + gap);
      final y = top + (slot ~/ 7) * (cellH + gap);
      final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellW, cellH), const Radius.circular(10));
      canvas.drawRRect(rect, Paint()..color = const Color(0xFFFFF0E5));
      canvas.drawRRect(
          rect,
          Paint()
            ..color = const Color(0xFFE8D5C7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      final day = days[i];
      text(day['tithi']!, x + 8, y + 8, cellW - 16, 21, bold: true);
      text(day['paksha']!, x + 8, y + 36, cellW - 16, 12.5, color: muted);
      text(day['events']!, x + 8, y + 55, cellW - 16, 13,
          color: accent, bold: true, lines: 2);
      text('${l.pick('नक्षत्र', 'Nak.')} ${day['nakshatra']}', x + 8,
          y + cellH - 96, cellW - 16, 12,
          color: muted);
      text('${l.sunrise} ${day['sunrise']}', x + 8, y + cellH - 79, cellW - 16,
          12,
          color: muted);
      text(
          '${l.sunset} ${day['sunset']}', x + 8, y + cellH - 62, cellW - 16, 12,
          color: muted);
      text('${l.pick('तिथि अंत', 'Ends')} ${day['tithiEnd']}', x + 8,
          y + cellH - 45, cellW - 16, 11.5,
          color: muted);
      text(day['day']!, x + 8, y + cellH - 29, cellW - 16, 23,
          color: slot % 7 == 0 ? accent : ink,
          bold: true,
          align: TextAlign.right);
    }
    text(
        l.pick('तिथि सूर्योदय के समय की है। +1 का अर्थ अगला दिन है।',
            'Tithi is shown at sunrise. +1 means the following day.'),
        36,
        1394,
        1118,
        13,
        color: muted);

    // App promotion stays below the calendar, with a crisp, unbranded QR quiet zone.
    final footer = RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 1440, 1118, 220), const Radius.circular(20));
    canvas.drawRRect(footer, Paint()..color = const Color(0xFFFFE8D5));
    canvas.drawCircle(
        const Offset(94, 1498), 44, Paint()..color = const Color(0xFFFFD3A8));
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
        const Rect.fromLTWH(57, 1461, 74, 74), const Radius.circular(37)));
    canvas.drawImageRect(
        icon,
        Rect.fromLTWH(0, 0, icon.width.toDouble(), icon.height.toDouble()),
        const Rect.fromLTWH(57, 1461, 74, 74),
        Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
    text('आपका रोज़ का पंचांग, अब मोबाइल पर', 152, 1470, 766, 26,
        color: ink, bold: true);
    text('हिन्दू कैलेंडर ऐप डाउनलोड करें', 152, 1520, 766, 29,
        color: accent, bold: true);
    text('तिथि, पर्व और व्रत एक जगह। डाउनलोड करने के लिए QR स्कैन करें।', 152,
        1570, 766, 18,
        color: muted, lines: 2);
    canvas.drawImageRect(
        qr,
        Rect.fromLTWH(0, 0, qr.width.toDouble(), qr.height.toDouble()),
        const Rect.fromLTWH(946, 1452, 196, 196),
        Paint()..filterQuality = FilterQuality.none);
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
    final content = _add(_stream('', _ascii('q 595 0 0 842 0 0 cm /Im0 Do Q')));
    final link = _add(
      _ascii(
        '<< /Type /Annot /Subtype /Link /Rect [18 12 577 122] '
        '/Border [0 0 0] /A << /S /URI /URI '
        '(https://play.google.com/store/apps/details?id=in.hinducalendar.hindu_calendar) >> >>',
      ),
    );
    _pages.add(
      _add(
        _ascii(
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] '
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
