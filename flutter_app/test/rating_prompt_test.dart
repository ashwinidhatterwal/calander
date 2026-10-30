import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/data/rating_prompt_store.dart';
import 'package:hindu_calendar/screens/rating_prompt.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final installed = DateTime.utc(2026, 10, 1, 8);
  late DateTime now;
  late RatingPromptStore store;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = installed.add(const Duration(hours: 23, minutes: 59));
    store = RatingPromptStore(
        clock: () => now, installationTime: () async => installed);
  });

  test('first request waits a full 24 hours from installation across restarts',
      () async {
    expect((await store.initialize()).isDue(now), isFalse);
    now = installed.add(const Duration(hours: 24));
    final restarted = RatingPromptStore(
        clock: () => now, installationTime: () async => installed);
    expect((await restarted.initialize()).isDue(now), isTrue);
  });
  test('fallback starts at first use and survives a restart', () async {
    final fallback =
        RatingPromptStore(clock: () => now, installationTime: () async => null);
    final first = await fallback.initialize();
    expect(first.isDue(now), isFalse);
    now = now.add(const Duration(hours: 23));
    final state = await RatingPromptStore(
        clock: () => now, installationTime: () async => null).initialize();
    expect(state.installedAt, first.installedAt);
    expect(state.isDue(now), isFalse);
  });
  test(
      'every presentation defers retry for 28 days, including an interrupted dialog',
      () async {
    now = installed.add(const Duration(days: 2));
    final shownAt = now;
    await store.recordShown(await store.initialize());
    now = shownAt
        .add(const Duration(days: 28))
        .subtract(const Duration(seconds: 1));
    expect((await store.initialize()).isDue(now), isFalse);
    now = now.add(const Duration(seconds: 1));
    expect((await store.initialize()).isDue(now), isTrue);
  });
  test('opt-out persists and a reinstalled app waits its own first day',
      () async {
    final state = await store.initialize();
    await store.stop(state);
    now = installed.add(const Duration(days: 100));
    expect((await store.initialize()).isDue(now), isFalse);
    final reinstalled =
        RatingPromptStore(clock: () => now, installationTime: () async => now);
    final fresh = await reinstalled.initialize();
    expect(fresh.stopped, isFalse);
    expect(fresh.isDue(now), isFalse);
    expect(fresh.nextPromptAt, now.add(const Duration(hours: 24)));
  });
  test('Android firstInstallTime is read from the device bridge', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(RatingPromptStore.channel, (call) async {
      expect(call.method, 'firstInstallTime');
      return installed.millisecondsSinceEpoch;
    });
    addTearDown(() =>
        messenger.setMockMethodCallHandler(RatingPromptStore.channel, null));
    final native = await RatingPromptStore(clock: () => now).initialize();
    expect(native.installedAt, installed);
  });

  testWidgets('busy routes defer the request; closing remembers the retry gap',
      (tester) async {
    now = installed.add(const Duration(days: 2));
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: nav,
        home: RatingPromptGate(
            language: AppLanguage.en,
            store: store,
            initialDelay: const Duration(seconds: 1),
            child: const Scaffold(body: Text('Calendar')))));
    nav.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Editor'))));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(RatingPromptDialog), findsNothing);
    nav.currentState!.pop();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 31));
    await tester.pumpAndSettle();
    expect(find.byType(RatingPromptDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect((await store.initialize()).isDue(now), isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('store opening survives a background/resume and stops reminders',
      (tester) async {
    now = installed.add(const Duration(days: 2));
    var opens = 0;
    await tester.pumpWidget(MaterialApp(
        home: RatingPromptGate(
            language: AppLanguage.en,
            store: store,
            initialDelay: const Duration(milliseconds: 1),
            openStore: () async {
              opens++;
              tester.binding
                  .handleAppLifecycleStateChanged(AppLifecycleState.paused);
              tester.binding
                  .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
              return true;
            },
            child: const Scaffold())));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate on Google Play'));
    await tester.pumpAndSettle();
    expect(opens, 1);
    expect((await store.initialize()).stopped, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('never ask persists; back and barrier remain dismissible',
      (tester) async {
    now = installed.add(const Duration(days: 2));
    await tester.pumpWidget(MaterialApp(
        home: RatingPromptGate(
            language: AppLanguage.en,
            store: store,
            initialDelay: const Duration(milliseconds: 1),
            child: const Scaffold())));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Don’t ask again'));
    await tester.pumpAndSettle();
    expect((await store.initialize()).stopped, isTrue);
    await tester.pumpWidget(const SizedBox());
    for (final back in [true, false]) {
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showDialog<RatingChoice>(
                          context: context,
                          builder: (_) => const RatingPromptDialog(
                              language: AppLanguage.en)),
                      child: const Text('Open'))))));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      if (back) {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tapAt(const Offset(2, 2));
      }
      await tester.pumpAndSettle();
      expect(find.byType(RatingPromptDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('recent calendar interaction postpones a due prompt until idle',
      (tester) async {
    now = installed.add(const Duration(days: 2));
    final start = now;
    await tester.pumpWidget(MaterialApp(
        home: RatingPromptGate(
            language: AppLanguage.en,
            store: store,
            child: Scaffold(
                body: TextButton(
                    onPressed: () {}, child: const Text('Calendar action'))))));
    now = start.add(const Duration(seconds: 7));
    await tester.pump(const Duration(seconds: 7));
    await tester.tap(find.text('Calendar action'));
    now = start.add(const Duration(seconds: 8));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(RatingPromptDialog), findsNothing);
    now = start.add(const Duration(seconds: 16));
    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.byType(RatingPromptDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('background app never displays a due rating request',
      (tester) async {
    now = installed.add(const Duration(days: 2));
    await tester.pumpWidget(MaterialApp(
        home: RatingPromptGate(
            language: AppLanguage.en,
            store: store,
            initialDelay: const Duration(seconds: 1),
            child: const Scaffold())));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(RatingPromptDialog), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(RatingPromptDialog), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });

  for (final language in AppLanguage.values) {
    for (final scale in [1.0, 1.6]) {
      for (final dark in [false, true]) {
        testWidgets('rating dialog fits ${language.name} $scale dark=$dark',
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
          await tester.pumpWidget(MaterialApp(
              theme: ThemeData(
                  useMaterial3: true,
                  fontFamily: 'CalendarHindi',
                  colorScheme: ColorScheme.fromSeed(
                      seedColor: const Color(0xff9a4e2d),
                      brightness: dark ? Brightness.dark : Brightness.light)),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!),
              home: RepaintBoundary(
                  key: boundary,
                  child:
                      Scaffold(body: RatingPromptDialog(language: language)))));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (const bool.fromEnvironment('CAPTURE_PREVIEWS')) {
            await tester.runAsync(() async {
              final render = boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
              final image = await render.toImage();
              final png =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final dir = Directory('build/ui-review')
                ..createSync(recursive: true);
              File('${dir.path}/rating-${language.name}-$scale-$dark.png')
                  .writeAsBytesSync(png!.buffer.asUint8List());
              image.dispose();
            });
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
