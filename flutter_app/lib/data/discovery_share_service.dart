import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/tithi_timeline.dart';
import 'calendar_pdf_service.dart';
import 'daily_discoveries.dart';

/// One immutable snapshot feeds both the poster preview and the shared bytes.
/// District/city is useful for Panchang; coordinates and personal events are
/// deliberately not included in the public image.
class DiscoveryPosterData {
  const DiscoveryPosterData({
    required this.entry,
    required this.language,
    required this.date,
    required this.place,
    required this.hinduDate,
    required this.samvat,
    required this.sunrise,
    required this.sunset,
    required this.nakshatra,
    required this.yoga,
    required this.tithiTimeline,
  });
  final DailyDiscovery entry;
  final AppLanguage language;
  final DateTime date;
  final String place, hinduDate, samvat, sunrise, sunset, nakshatra, yoga;
  final List<String> tithiTimeline;

  factory DiscoveryPosterData.forDay({
    required DailyDiscovery entry,
    required AppLanguage language,
    required DateTime date,
    required GeoLocation location,
    PanchangEngine engine = const PanchangEngine(),
  }) {
    final l = L10n(language);
    final detail = engine.buildDay(date, location);
    final cell = engine.monthCell(date, location);
    String time(DateTime value) => engine.time12(value, location,
        amLabel: l.pick('पु.', 'AM'), pmLabel: l.pick('अप.', 'PM'));
    final timeline = civilTithiTimeline(engine, date, location);
    return DiscoveryPosterData(
      entry: entry,
      language: language,
      date: DateTime(date.year, date.month, date.day),
      place: l.pick(location.cityHi, location.cityEn),
      hinduDate:
          '${cell.adhik ? '${l.adhik} ' : ''}${l.pick(cell.month.hi, cell.month.en)} · ${l.pick(cell.pakshaHi, cell.pakshaEn)} ${l.pick(cell.tithi.hi, cell.tithi.en)}',
      samvat: l.pick('विक्रम संवत् ${detail.vikramSamvat}',
          'Vikram Samvat ${detail.vikramSamvat}'),
      sunrise: time(detail.sunriseUtc),
      sunset: time(detail.sunsetUtc),
      nakshatra: l.pick(detail.nakshatra.hi, detail.nakshatra.en),
      yoga: l.pick(detail.yoga.hi, detail.yoga.en),
      tithiTimeline: [
        for (var i = 0; i < timeline.length; i++)
          '${l.pick(timeline[i].state.pakshaHi, timeline[i].state.pakshaEn)} ${l.pick(timeline[i].state.value.hi, timeline[i].state.value.en)} · ${i == 0 ? l.pick('दिन शुरू होने से', 'From day start') : time(timeline[i].fromUtc)} — ${i == timeline.length - 1 ? l.pick('दिन समाप्ति तक', 'until day end') : time(timeline[i].toUtc)}${timeline[i].atSunrise ? l.pick(' (सूर्योदय)', ' (at sunrise)') : ''}',
      ],
    );
  }
}

class DiscoveryShareService {
  static const channel = MethodChannel('in.hinducalendar/discovery_share');
  static Future<void>? _fonts;

  static Future<void> _loadFont() => _fonts ??= (FontLoader('CalendarHindi')
        ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari.ttf')))
      .load();

  static Future<Uint8List> build(DiscoveryPosterData data) async {
    await _loadFont();
    final l = L10n(data.language);
    final entry = data.entry;
    final p = _PosterLayout();
    final logo = await _assetImage('assets/branding/app_icon.png');
    final qr = await _assetImage('assets/branding/play_store_qr.png');
    try {
      p.image(logo, const Rect.fromLTWH(64, 60, 96, 96));
      p.y = 56;
      p.text(l.appName, x: 184, width: 830, size: 44, bold: true);
      p.text(
          l.pick('अपनी तिथि · अपनी परंपरा', 'Your Panchang. Your traditions.'),
          x: 184,
          width: 830,
          size: 27,
          color: _PosterLayout.muted);
      p.y = p.y < 185 ? 185 : p.y + 24;
      final weekday = l.pick(
        const [
          'सोमवार',
          'मंगलवार',
          'बुधवार',
          'गुरुवार',
          'शुक्रवार',
          'शनिवार',
          'रविवार'
        ][data.date.weekday - 1],
        const [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ][data.date.weekday - 1],
      );
      p.text(
          '${data.date.day} ${l.isHindi ? monthNamesHi[data.date.month - 1] : monthNamesEn[data.date.month - 1]} ${data.date.year} · $weekday',
          size: 30,
          color: _PosterLayout.muted);
      p.gap(22);
      final readingStart = p.y;
      final readingLayer = p.commands.length;
      p.y += 34;
      if (entry.teacherHi.isNotEmpty) {
        p.text(l.pick(entry.teacherHi, entry.teacherEn),
            x: 98,
            width: 884,
            size: 29,
            bold: true,
            color: _PosterLayout.saffron);
        p.gap(12);
      }
      p.text(l.pick(entry.titleHi, entry.titleEn),
          x: 98, width: 884, size: 47, bold: true);
      if (entry.contextHi.isNotEmpty) {
        p.gap(16);
        p.text(l.pick(entry.contextHi, entry.contextEn),
            x: 98,
            width: 884,
            size: 29,
            bold: true,
            color: _PosterLayout.saffron);
      }
      if (entry.quote.isNotEmpty) {
        p.gap(22);
        p.text(entry.quote,
            x: 98,
            width: 884,
            size: 39,
            bold: true,
            color: _PosterLayout.saffron);
        p.gap(14);
        p.text(l.pick('भावार्थ', 'Meaning'),
            x: 98,
            width: 884,
            size: 26,
            bold: true,
            color: _PosterLayout.muted);
      }
      if (entry.quote.isEmpty && entry.reference.isNotEmpty) {
        p.gap(12);
        p.text(
            entry.kind == 'story'
                ? l.pick('कथा-सार', 'Story retelling')
                : l.pick('भावार्थ', 'Paraphrase'),
            x: 98,
            width: 884,
            size: 26,
            bold: true,
            color: _PosterLayout.muted);
      }
      p.gap(16);
      p.text(l.pick(entry.bodyHi, entry.bodyEn),
          x: 98, width: 884, size: 36, height: 1.55);
      p.gap(20);
      final reference = l.isHindi && entry.referenceHi.isNotEmpty
          ? entry.referenceHi
          : entry.reference;
      final source = reference.isEmpty ? entry.source : reference;
      p.text('${l.pick('स्रोत', 'Source')}: $source',
          x: 98, width: 884, size: 25, color: _PosterLayout.muted);
      p.text(Uri.parse(entry.url).host,
          x: 98, width: 884, size: 22, color: _PosterLayout.muted);
      p.y += 30;
      p.panel(readingLayer, readingStart, p.y - readingStart);
      p.gap(32);
      p.text(l.pick('आज का पंचांग', 'Today’s Panchang'), size: 38, bold: true);
      p.text(data.samvat, size: 33, bold: true, color: _PosterLayout.saffron);
      p.text(data.hinduDate, size: 32, bold: true);
      p.text('${l.location}: ${data.place}',
          size: 26, color: _PosterLayout.muted);
      p.gap(16);
      p.text('${l.sunrise}  ${data.sunrise}     ${l.sunset}  ${data.sunset}',
          size: 29);
      p.text('${l.nakshatra}: ${data.nakshatra} · ${l.yoga}: ${data.yoga}',
          size: 29);
      p.gap(12);
      p.text(l.pick('दिन में तिथि का क्रम', 'Tithi through the day'),
          size: 26, bold: true, color: _PosterLayout.muted);
      for (final interval in data.tithiTimeline) {
        p.text(interval, size: 25, height: 1.5);
      }
      p.gap(32);
      final footer = p.y;
      p.image(qr, Rect.fromLTWH(64, footer, 148, 148));
      p.text(l.appName, x: 238, width: 778, size: 34, bold: true);
      p.text(
          l.pick('पंचांग, पर्व और शास्त्र-वाणी—हर दिन साथ।',
              'Panchang, festivals and sacred wisdom, every day.'),
          x: 238,
          width: 778,
          size: 28);
      p.text(
          l.pick('Google Play पर पाएँ · QR स्कैन करें',
              'Get it on Google Play · Scan the QR'),
          x: 238,
          width: 778,
          size: 25,
          color: _PosterLayout.saffron);
      p.y = (p.y > footer + 148 ? p.y : footer + 148) + 56;
      return await p.png();
    } finally {
      logo.dispose();
      qr.dispose();
    }
  }

  static Future<ui.Image> _assetImage(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  static Future<void> share(Uint8List png, DiscoveryPosterData data) async {
    final l = L10n(data.language);
    final date = '${data.date.year}-${data.date.month}-${data.date.day}';
    await channel.invokeMethod<void>('shareImage', {
      'bytes': png,
      'filename':
          'Hindu-Calendar-Discovery-$date-${DateTime.now().microsecondsSinceEpoch}-${data.language.name}.png',
      'caption':
          '${l.pick(data.entry.titleHi, data.entry.titleEn)}\n${l.appName}\n${CalendarPdfService.playStoreUrl}\n${data.entry.url}',
    });
  }
}

/// Text is measured before rasterization. No fixed-height boxes, ellipses or
/// phone text-scale dependence can crop a long Hindi conjunct or a source line.
class _PosterLayout {
  static const ink = Color(0xff30251f);
  static const muted = Color(0xff71645a);
  static const saffron = Color(0xffa14a20);
  final commands = <void Function(Canvas)>[];
  double y = 0;
  void gap(double amount) => y += amount;
  void text(String value,
      {double x = 64,
      double width = 952,
      double size = 32,
      bool bold = false,
      Color color = ink,
      double height = 1.45}) {
    final painter = TextPainter(
      text: TextSpan(
          text: value,
          style: TextStyle(
              fontFamily: 'CalendarHindi',
              fontSize: size,
              height: height,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: color)),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    final top = y;
    commands.add((canvas) {
      painter.paint(canvas, Offset(x, top));
      painter.dispose();
    });
    y += painter.height;
  }

  void image(ui.Image image, Rect destination) =>
      commands.add((canvas) => canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          destination,
          Paint()..filterQuality = FilterQuality.high));
  void panel(int layer, double top, double height) {
    commands.insert(
        layer,
        (canvas) => canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(64, top, 952, height), const Radius.circular(28)),
            Paint()..color = const Color(0xfffff1df)));
  }

  Future<Uint8List> png() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final height = y.ceil();
    canvas.drawRect(Rect.fromLTWH(0, 0, 1080, height.toDouble()),
        Paint()..color = const Color(0xfffffcf6));
    canvas.drawRect(
        const Rect.fromLTWH(0, 0, 1080, 12), Paint()..color = saffron);
    for (final draw in commands) {
      draw(canvas);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(1080, height);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Could not encode poster');
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }
}
