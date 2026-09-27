import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/localization.dart';
import 'core/locations.dart';
import 'domain/festival_engine.dart';
import 'domain/models.dart';
import 'domain/panchang_engine.dart';
import 'screens/calendar_screen.dart';
import 'screens/festivals_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    // The engine continues without editorial overrides; tests guard packaged data.
  }
  runApp(HinduCalendarApp(holikaOverrides: overrides));
}

class HinduCalendarApp extends StatefulWidget {
  const HinduCalendarApp({super.key, required this.holikaOverrides});
  final Map<int, DateTime> holikaOverrides;

  @override
  State<HinduCalendarApp> createState() => _HinduCalendarAppState();
}

class _HinduCalendarAppState extends State<HinduCalendarApp> {
  final PanchangEngine panchang = const PanchangEngine();
  AppLanguage language = AppLanguage.hi;
  GeoLocation location = locations.first;
  int tab = 0;
  late final FestivalEngine festival;

  @override
  void initState() {
    super.initState();
    festival = FestivalEngine(panchang, holikaOverrides: widget.holikaOverrides);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n(language);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: l10n.appName,
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
                onLanguageChanged: (v) => setState(() => language = v),
                onLocationChanged: (v) => setState(() => location = v),
              ),
              FestivalsScreen(
                festival: festival,
                language: language,
                location: location,
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (v) => setState(() => tab = v),
          destinations: [
            NavigationDestination(icon: const Icon(Icons.calendar_month_outlined), selectedIcon: const Icon(Icons.calendar_month), label: l10n.calendar),
            NavigationDestination(icon: const Icon(Icons.celebration_outlined), selectedIcon: const Icon(Icons.celebration), label: l10n.festivals),
          ],
        ),
      ),
    );
  }
}
