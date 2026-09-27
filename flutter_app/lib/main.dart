import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/localization.dart';
import 'core/locations.dart';
import 'data/app_settings_store.dart';
import 'data/personal_event_store.dart';
import 'data/widget_sync_service.dart';
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
  final AppSettingsStore _settingsStore = const AppSettingsStore();
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

    AppSettings settings = AppSettings(language: AppLanguage.hi, location: locations.first);
    try {
      settings = await _settingsStore.load();
    } catch (_) {
      // Preference storage failure must never block calendar startup.
    }
    final elapsed = DateTime.now().difference(started);
    const minimumSplash = Duration(milliseconds: 260);
    if (elapsed < minimumSplash) {
      await Future<void>.delayed(minimumSplash - elapsed);
    }
    if (!mounted) return;
    setState(() => _data = _BootstrapData(overrides, events, settings));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (data == null) return const _LoadingApp();
    return HinduCalendarApp(
      holikaOverrides: data.overrides,
      initialEvents: data.events,
      initialLanguage: data.settings.language,
      initialLocation: data.settings.location,
      onEventsChanged: _store.save,
      onLanguageChanged: _settingsStore.saveLanguage,
      onLocationChanged: _settingsStore.saveLocation,
    );
  }
}

class _BootstrapData {
  const _BootstrapData(this.overrides, this.events, this.settings);
  final Map<int, DateTime> overrides;
  final List<PersonalEvent> events;
  final AppSettings settings;
}

class _LoadingApp extends StatelessWidget {
  const _LoadingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const Scaffold(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  'assets/branding/app_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
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
    this.initialLanguage = AppLanguage.hi,
    this.initialLocation,
    this.onEventsChanged,
    this.onLanguageChanged,
    this.onLocationChanged,
  });

  final Map<int, DateTime> holikaOverrides;
  final List<PersonalEvent> initialEvents;
  final AppLanguage initialLanguage;
  final GeoLocation? initialLocation;
  final Future<void> Function(List<PersonalEvent>)? onEventsChanged;
  final Future<void> Function(AppLanguage)? onLanguageChanged;
  final Future<void> Function(GeoLocation)? onLocationChanged;

  @override
  State<HinduCalendarApp> createState() => _HinduCalendarAppState();
}

class _HinduCalendarAppState extends State<HinduCalendarApp> {
  final PanchangEngine panchang = const PanchangEngine();
  late AppLanguage language;
  late GeoLocation location;
  int tab = 0;
  late final FestivalEngine festival;
  late List<PersonalEvent> personalEvents;

  @override
  void initState() {
    super.initState();
    festival = FestivalEngine(panchang, holikaOverrides: widget.holikaOverrides);
    personalEvents = List<PersonalEvent>.of(widget.initialEvents);
    language = widget.initialLanguage;
    location = widget.initialLocation ?? locations.first;
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHomeWidgets());
  }

  void _syncHomeWidgets() {
    unawaited(
      WidgetSyncService.sync(
        panchang: panchang,
        festival: festival,
        location: location,
        language: language,
        personalEvents: personalEvents,
      ),
    );
  }

  void _changeLanguage(AppLanguage value) {
    setState(() => language = value);
    unawaited(widget.onLanguageChanged?.call(value) ?? Future<void>.value());
    _syncHomeWidgets();
  }

  void _changeLocation(GeoLocation value) {
    setState(() => location = value);
    unawaited(widget.onLocationChanged?.call(value) ?? Future<void>.value());
    _syncHomeWidgets();
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
    _syncHomeWidgets();
  }

  void _deleteEvent(String id) {
    final next = personalEvents.where((x) => x.id != id).toList(growable: false);
    setState(() => personalEvents = next);
    widget.onEventsChanged?.call(List<PersonalEvent>.unmodifiable(next));
    _syncHomeWidgets();
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
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.system,
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
                onLanguageChanged: _changeLanguage,
                onLocationChanged: _changeLocation,
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

ThemeData _theme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF8D4B2D),
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    navigationBarTheme: NavigationBarThemeData(backgroundColor: scheme.surfaceContainer),
    cardTheme: CardThemeData(
      elevation: 0.8,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
  );
}
