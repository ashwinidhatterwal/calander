import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';
import 'package:hindu_calendar/domain/models.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/screens/day_details_screen.dart';
import 'package:hindu_calendar/screens/discover_screen.dart';

class _FastFestival extends FestivalEngine {
  _FastFestival() : super(const PanchangEngine());
  @override
  Future<List<FestivalObservance>> majorFestivalsAsync(
    int year,
    GeoLocation location,
  ) async => [];
}

void main() {
  for (final language in AppLanguage.values) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
        'day details and Discover fit narrow screen ${language.name} $scale',
        (tester) async {
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final font = FontLoader('CalendarHindi')
            ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari.ttf'));
          await font.load();
        final icons = FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
          final boundary = GlobalKey();
          final festival = _FastFestival();
          Widget app(Widget child) => MaterialApp(
            locale: Locale(language == AppLanguage.hi ? 'hi' : 'en'),
            supportedLocales: const [Locale('hi'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: 'CalendarHindi',
              scaffoldBackgroundColor: const Color(0xfffffbf7),
              cardTheme: CardThemeData(elevation: 0, color: const Color(0xfffff4ed),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xffe8d3c7), width: .8))),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xff9a4e2d),
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RepaintBoundary(key: boundary, child: child),
          );
          await tester.pumpWidget(
            app(
              DayDetailsScreen(
                date: DateTime.utc(2026, 10, 29),
                panchang: const PanchangEngine(),
                festival: festival,
                language: language,
                location: locations.first,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            await _capture(tester, boundary, 'day-${language.name}-top');
          }
          for (var i = 0; i < 7; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -280),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            if (i == 0 && scale == 1) {
              await _capture(tester, boundary, 'day-${language.name}-timeline');
            }
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            app(
              Scaffold(
                body: DiscoverScreen(
                  language: language,
                  active: true,
                  location: locations.first,
                  festival: festival,
                  clock: () => DateTime(2026, 10, 30),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (scale == 1) {
            await _capture(tester, boundary, 'discover-${language.name}');
          }
          for (var i = 0; i < 5; i++) {
            await tester.drag(find.byType(ListView), const Offset(0, -280));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_PREVIEWS')) return;
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('build/ui-review')..createSync(recursive: true);
    File('${directory.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
