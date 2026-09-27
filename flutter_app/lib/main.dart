import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization.dart';
import 'core/locations.dart';
import 'data/personal_event_store.dart';
import 'domain/festival_engine.dart';
import 'domain/models.dart';
import 'domain/panchang_engine.dart';
import 'domain/personal_event.dart';
import 'screens/calendar_screen.dart';
import 'screens/festivals_screen.dart';
import 'screens/my_days_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HinduCalendarBootstrap());
}

class HinduCalendarBootstrap extends StatefulWidget {
  const HinduCalendarBootstrap({super.key});

  @override
  State<HinduCalendarBootstrap> createState() => _HinduCalendarBootstrapState();
}

class _HinduCalendarBootstrapState extends State<HinduCalendarBootstrap> {
  final PersonalEventStore _store = PersonalEventStore();
  _BootstrapData? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final started = DateTime.now();
    final overrides = <int, DateTime>{};
    try {
      final raw = await rootBundle.loadString('assets/data/festival_overrides.json');
      final items = jsonDecode(raw) as List<dynamic>;
      for (final item in items.cast<Map<String, dynamic>>()) {
        if (item['festival_id'] == 'holika_dahan' && item['profile'] == 'north_india_purnimanta') {
          final d = DateTime.parse(item['date'] as String);
          overrides[item['year'] as int] = DateTime.utc(d.year, d.month, d.day);
        }
      }
    } catch (_) {
      // The deterministic engine continues without editorial overrides.
    }

    List<PersonalEvent> events = const [];
    try {
      events = await _store.load();
    } catch (_) {
      // Local event storage failure must never block calendar startup.
    }
    final elapsed = DateTime.now().difference(started);
    const minimumSplash = Duration(milliseconds: 260);
    if (elapsed < minimumSplash) {
      await Future<void>.delayed(minimumSplash - elapsed);
    }
    if (!mounted) return;
    setState(() => _data = _BootstrapData(overrides, events));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const _LoadingApp();
    return HinduCalendarApp(
      holikaOverrides: data.overrides,
      initialEvents: data.events,
      onEventsChanged: _store.save,
    );
  }
}

class _BootstrapData {
  const _BootstrapData(this.overrides, this.events);
  final Map<int, DateTime> overrides;
  final List<PersonalEvent> events;
}

class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8D4B2D),
        scaffoldBackgroundColor: const Color(0xFFFFF8F1),
      ),
      home: const Scaffold(
        backgroundColor: Color(0xFFFFF8F1),
        body: SafeArea(child: _LoadingScreen()),
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(Icons.calendar_month_rounded, size: 44, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 22),
            Text(
              'हिन्दू कैलेंडर',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              'तिथि • पर्व • आपके दिन',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 26),
            const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.6)),
          ],
        ),
      ),
    );
  }
}

class HinduCalendarApp extends StatefulWidget {
  const HinduCalendarApp({
    super.key,
    required this.holikaOverrides,
    this.initialEvents = const [],
    this.onEventsChanged,
  });

  final Map<int, DateTime> holikaOverrides;
  final List<PersonalEvent> initialEvents;
  final Future<void> Function(List<PersonalEvent>)? onEventsChanged;

  @override
  State<HinduCalendarApp> createState() => _HinduCalendarAppState();
}

class _HinduCalendarAppState extends State<HinduCalendarApp> {
  final PanchangEngine panchang = const PanchangEngine();
  AppLanguage language = AppLanguage.hi;
  GeoLocation location = locations.first;
  int tab = 0;
  late final FestivalEngine festival;
  late List<PersonalEvent> personalEvents;

  @override
  void initState() {
    super.initState();
    festival = FestivalEngine(panchang, holikaOverrides: widget.holikaOverrides);
    personalEvents = List<PersonalEvent>.of(widget.initialEvents);
  }

  void _upsertEvent(PersonalEvent event) {
    final next = List<PersonalEvent>.of(personalEvents);
    final index = next.indexWhere((x) => x.id == event.id);
    if (index == -1) {
      next.add(event);
    } else {
      next[index] = event;
    }
    setState(() => personalEvents = next);
    widget.onEventsChanged?.call(List<PersonalEvent>.unmodifiable(next));
  }

  void _deleteEvent(String id) {
    final next = personalEvents.where((x) => x.id != id).toList(growable: false);
    setState(() => personalEvents = next);
    widget.onEventsChanged?.call(List<PersonalEvent>.unmodifiable(next));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n(language);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: l10n.appName,
      locale: language == AppLanguage.hi ? const Locale('hi', 'IN') : const Locale('en', 'IN'),
      supportedLocales: const [Locale('hi', 'IN'), Locale('en', 'IN')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8D4B2D),
        scaffoldBackgroundColor: const Color(0xFFFFFBF6),
      ),
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: tab,
            children: [
              CalendarScreen(
                panchang: panchang,
                festival: festival,
                language: language,
                location: location,
                personalEvents: personalEvents,
                onUpsertPersonalEvent: _upsertEvent,
                onLanguageChanged: (v) => setState(() => language = v),
                onLocationChanged: (v) => setState(() => location = v),
              ),
              FestivalsScreen(
                festival: festival,
                language: language,
                location: location,
                personalEvents: personalEvents,
              ),
              MyDaysScreen(
                events: personalEvents,
                language: language,
                location: location,
                panchang: panchang,
                active: tab == 2,
                onUpsert: _upsertEvent,
                onDelete: _deleteEvent,
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.calendar_month_outlined),
              selectedIcon: const Icon(Icons.calendar_month),
              label: l10n.calendar,
            ),
            NavigationDestination(
              icon: const Icon(Icons.celebration_outlined),
              selectedIcon: const Icon(Icons.celebration),
              label: l10n.festivals,
            ),
            NavigationDestination(
              icon: const Icon(Icons.event_repeat_outlined),
              selectedIcon: const Icon(Icons.event_repeat),
              label: l10n.myDays,
            ),
          ],
        ),
      ),
    );
  }
}
