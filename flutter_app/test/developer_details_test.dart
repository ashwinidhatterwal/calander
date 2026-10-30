import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/screens/developer_details_card.dart';

void main() {
  for (final language in AppLanguage.values) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
          'developer contact fits narrow screen ${language.name} $scale',
          (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final font = FontLoader('CalendarHindi')
          ..addFont(rootBundle.load('assets/fonts/NotoSansDevanagari.ttf'));
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
        final boundary = GlobalKey();
        String? copied;
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null));
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                useMaterial3: true,
                fontFamily: 'CalendarHindi',
                colorScheme:
                    ColorScheme.fromSeed(seedColor: const Color(0xff9a4e2d))),
            builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                    appBar: AppBar(
                        title: Text(language == AppLanguage.hi
                            ? 'ऐप के बारे में'
                            : 'About')),
                    body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: DeveloperDetailsCard(
                            language: language,
                            name: 'Ashwini Dhatterwal',
                            email: 'developer@example.com'))))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Ashwini Dhatterwal'), findsOneWidget);
        await tester.tap(find.text(
            language == AppLanguage.hi ? 'ईमेल कॉपी करें' : 'Copy email'));
        await tester.pumpAndSettle();
        expect(copied, 'developer@example.com');
        if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final dir = Directory('build/ui-review')
              ..createSync(recursive: true);
            File('${dir.path}/developer-${language.name}-$scale.png')
                .writeAsBytesSync(png!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
