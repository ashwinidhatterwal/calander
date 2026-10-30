import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/data/calendar_pdf_service.dart';
import 'package:hindu_calendar/data/daily_discoveries.dart';
import 'package:hindu_calendar/data/discovery_share_service.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/screens/discovery_share_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final entry = DailyDiscoveries.entries
      .firstWhere((e) => e.id == 'gita-simple-offering');
  final data = DiscoveryPosterData.forDay(
      entry: entry,
      language: AppLanguage.hi,
      date: DateTime(2026, 10, 29),
      location: locations.first);

  test('poster snapshot retains every civil-day tithi and selected location',
      () {
    final day = const PanchangEngine().buildDay(data.date, locations.first);
    expect(data.tithiTimeline.length, 3);
    expect(data.tithiTimeline.where((t) => t.contains('(सूर्योदय)')).length, 1);
    expect(data.tithiTimeline.first, contains('दिन शुरू होने से'));
    expect(data.tithiTimeline.last, contains('दिन समाप्ति तक'));
    expect(data.samvat, contains('${day.vikramSamvat}'));
    expect(data.place, locations.first.cityHi);
    expect(data.hinduDate, isNotEmpty);
    expect(data.sunrise, isNotEmpty);
  });

  testWidgets(
      'PNG renders Hindi, English, stories and long references without cropping',
      (tester) async {
    for (final language in AppLanguage.values) {
      for (final id in [
        'gita-simple-offering',
        'nachiketa-first-boon',
        'vivekananda-patriot-heart'
      ]) {
        final snapshot = DiscoveryPosterData.forDay(
            entry: DailyDiscoveries.entries.firstWhere((e) => e.id == id),
            language: language,
            date: data.date,
            location: locations.first);
        await tester.runAsync(() async {
          final bytes = await DiscoveryShareService.build(snapshot);
          final codec = await ui.instantiateImageCodec(bytes);
          final image = (await codec.getNextFrame()).image;
          expect(image.width, 1080);
          expect(image.height, inInclusiveRange(1000, 8000));
          image.dispose();
          codec.dispose();
          if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
            final dir = Directory('build/ui-review')
              ..createSync(recursive: true);
            File('${dir.path}/share-${language.name}-$id.png')
                .writeAsBytesSync(bytes);
          }
        });
      }
    }
  });

  testWidgets('preview shares the exact displayed PNG and branded caption',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    MethodCall? captured;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(DiscoveryShareService.channel, (call) async {
      captured = call;
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(DiscoveryShareService.channel, null));
    await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(1.6)),
            child: child!),
        home: DiscoverySharePreview(data: data)));
    await tester.runAsync(() async {
      for (var i = 0; i < 100 && find.byType(Image).evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
      }
    });
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    final shown = (image.image as MemoryImage).bytes;
    await tester.tap(find.text('फोटो साझा करें'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(captured!.method, 'shareImage');
    final args = captured!.arguments as Map;
    expect(args['bytes'], orderedEquals(shown));
    expect(args['caption'], contains(CalendarPdfService.playStoreUrl));
    expect(args['caption'], contains(entry.url));
    expect(args['caption'], isNot(contains('${locations.first.latitude}')));
    expect(args['filename'],
        matches(RegExp(r'^Hindu-Calendar-Discovery-[0-9-]+-hi\.png$')));
    await tester.pumpWidget(const SizedBox());
  });
}
