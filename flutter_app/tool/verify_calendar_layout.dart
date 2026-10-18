import 'dart:io';
import "package:flutter/rendering.dart";
import 'package:flutter/material.dart';
import 'package:hindu_calendar/core/app_theme.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/domain/festival_engine.dart';
import 'package:hindu_calendar/screens/calendar_screen.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  final failures = <FlutterErrorDetails>[];
  FlutterError.onError = failures.add;
  final engine = PanchangEngine();
  for (final width in [320.0, 400.0]) {
    runApp(MaterialApp(
        home: Scaffold(
            body: CalendarScreen(
      key: ValueKey(width),
      panchang: engine,
      festival: FestivalEngine(engine),
      language: AppLanguage.en,
      location: locations.first,
      personalEvents: const [],
      onUpsertPersonalEvent: (_) {},
      onLanguageChanged: (_) {},
      onLocationChanged: (_) async {},
      themePreference: AppThemePreference.light,
      onThemeChanged: (_) {},
    ))));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final view = binding.renderViews.first;
    view.configuration = ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(Size(width, 900)),
        physicalConstraints: BoxConstraints.tight(Size(width, 900)),
        devicePixelRatio: 1);
    binding.scheduleFrame();
    await Future<void>.delayed(const Duration(seconds: 2));
    final elements = <Element>[];
    void visit(Element element) {
      elements.add(element);
      element.visitChildren(visit);
    }

    visit(binding.rootElement!);
    final now = DateTime.now();
    final key =
        ValueKey('calendar-cell-${now.year}-${now.month}-1-${now.day == 1}');
    final tile = elements.firstWhere((e) => e.widget.key == key);
    final labels = <Element>[];
    void collect(Element e) {
      if (e.widget is Text) labels.add(e);
      e.visitChildren(collect);
    }

    collect(tile);
    final top = labels.first;
    final bottom = labels.firstWhere((e) => (e.widget as Text).data == '1');
    final a =
        (top.findRenderObject() as RenderBox).localToGlobal(Offset.zero).dy;
    final b =
        (bottom.findRenderObject() as RenderBox).localToGlobal(Offset.zero).dy;
    if (a >= b || (top.widget as Text).style?.fontWeight != FontWeight.w800) {
      throw StateError('Tithi/date ordering or font weight is incorrect');
    }
    final menu = elements
        .map((e) => e.widget)
        .whereType<PopupMenuButton<String>>()
        .first;
    menu.onSelected!('pdf');
    await Future<void>.delayed(const Duration(milliseconds: 600));
    elements.clear();
    visit(binding.rootElement!);
    final text = elements
        .map((e) => e.widget)
        .whereType<Text>()
        .map((t) => t.data)
        .toList();
    if (!text.contains('Monthly calendar') ||
        !text.contains('Yearly calendar')) {
      throw StateError('Export choices are missing');
    }
    if (failures.isNotEmpty) {
      for (final f in failures) {
        stdout.writeln(f);
      }
      exit(1);
    }
    stdout.writeln(
        'PASS $width px: bold tithi above date, PDF choices, no render errors');
  }
  exit(0);
}
