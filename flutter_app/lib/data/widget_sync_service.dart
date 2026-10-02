import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:home_widget/home_widget.dart';

import '../core/localization.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';

class WidgetSyncService {
  const WidgetSyncService._();

  static int _generation = 0;
  static const String todayProvider = 'TodayPanchangWidgetProvider';
  static const String upcomingProvider = 'UpcomingWidgetProvider';

  static Future<void> sync({
    required PanchangEngine panchang,
    required FestivalEngine festival,
    required GeoLocation location,
    required AppLanguage language,
    required List<PersonalEvent> personalEvents,
  }) async {
    if (!Platform.isAndroid) return;
    try {
      final generation = ++_generation;
      final data = await compute(_widgetPayload, (
        panchang,
        festival.holikaOverrides,
        location,
        language,
        personalEvents
      ));
      if (generation != _generation) return;
      final writes = data.entries
          .map((e) => HomeWidget.saveWidgetData<String>(e.key, e.value));
      await Future.wait(writes);
      await Future.wait([
        HomeWidget.updateWidget(androidName: todayProvider),
        HomeWidget.updateWidget(androidName: upcomingProvider),
      ]);
    } catch (_) {
      // Widgets are optional. They must never block or crash the calendar app.
    }
  }

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _dateLabel(DateTime d, AppLanguage language) {
    final month = language == AppLanguage.hi
        ? monthNamesHi[d.month - 1]
        : monthNamesEn[d.month - 1];
    return '${d.day} $month ${d.year}';
  }
}

class _WidgetOccurrence {
  const _WidgetOccurrence(this.date, this.title, this.kind);
  final DateTime date;
  final String title;
  final String kind;
}

Map<String, String> _widgetPayload(
    (
      PanchangEngine,
      Map<int, DateTime>,
      GeoLocation,
      AppLanguage,
      List<PersonalEvent>
    ) args) {
  final (panchang, overrides, location, language, personalEvents) = args;
  final festival = FestivalEngine(panchang, holikaOverrides: overrides);
  final now = DateTime.now();
  final start = DateTime.utc(now.year, now.month, now.day);
  final data = <String, String>{};

  for (var i = 0; i < 14; i++) {
    final date = start.add(Duration(days: i));
    final cell = panchang.monthCell(date, location);
    final ss = panchang.sunriseSunset(date, location);
    final weekday = language == AppLanguage.hi
        ? const [
            'सोम',
            'मंगल',
            'बुध',
            'गुरु',
            'शुक्र',
            'शनि',
            'रवि'
          ][date.weekday - 1]
        : const [
            'Mon',
            'Tue',
            'Wed',
            'Thu',
            'Fri',
            'Sat',
            'Sun'
          ][date.weekday - 1];
    final monthName = language == AppLanguage.hi
        ? monthNamesHi[date.month - 1]
        : monthNamesEn[date.month - 1];
    final tithi = language == AppLanguage.hi ? cell.tithi.hi : cell.tithi.en;
    final paksha = language == AppLanguage.hi ? cell.pakshaHi : cell.pakshaEn;
    final lunarMonth =
        language == AppLanguage.hi ? cell.month.hi : cell.month.en;
    final adhik =
        cell.adhik ? (language == AppLanguage.hi ? 'अधिक ' : 'Adhik ') : '';
    final monthSuffix = language == AppLanguage.hi ? 'मास' : 'month';

    data['day_${i}_iso'] = WidgetSyncService._iso(date);
    data['day_${i}_weekday'] = weekday;
    data['day_${i}_date'] = '${date.day} $monthName';
    data['day_${i}_tithi'] = '$paksha $tithi';
    data['day_${i}_month'] = '$adhik$lunarMonth $monthSuffix';
    data['day_${i}_sunrise'] = panchang.hhmm(ss[0], location);
    data['day_${i}_sunset'] = panchang.hhmm(ss[1], location);
  }

  final upcoming = <_WidgetOccurrence>[];
  final years = {start.year, start.year + 1};
  for (final year in years) {
    for (final f in festival.majorFestivalsForYear(year, location)) {
      if (!f.localDate.isBefore(start)) {
        upcoming.add(_WidgetOccurrence(
          f.localDate,
          language == AppLanguage.hi ? f.nameHi : f.nameEn,
          language == AppLanguage.hi ? 'पर्व / व्रत' : 'Festival / Vrat',
        ));
      }
    }
  }

  final matcher = PersonalEventMatcher(panchang);
  for (final r
      in matcher.upcoming(personalEvents, start, location, limit: 20)) {
    upcoming.add(_WidgetOccurrence(
      r.date,
      r.event.title,
      language == AppLanguage.hi ? 'आपका दिन' : 'My Day',
    ));
  }

  upcoming.sort((a, b) {
    final dateCompare = a.date.compareTo(b.date);
    if (dateCompare != 0) return dateCompare;
    return a.title.compareTo(b.title);
  });

  final unique = <_WidgetOccurrence>[];
  final seen = <String>{};
  for (final item in upcoming) {
    final key = '${WidgetSyncService._iso(item.date)}|${item.title}';
    if (seen.add(key)) unique.add(item);
    if (unique.length == 12) break;
  }

  for (var i = 0; i < 12; i++) {
    final item = i < unique.length ? unique[i] : null;
    data['event_${i}_iso'] =
        item == null ? '' : WidgetSyncService._iso(item.date);
    data['event_${i}_title'] = item?.title ?? '';
    data['event_${i}_kind'] = item?.kind ?? '';
    data['event_${i}_date'] =
        item == null ? '' : WidgetSyncService._dateLabel(item.date, language);
  }

  data['widget_empty_upcoming'] = language == AppLanguage.hi
      ? 'कोई आगामी कार्यक्रम नहीं'
      : 'No upcoming event';
  data['widget_open_app'] =
      language == AppLanguage.hi ? 'कैलेंडर खोलें' : 'Open calendar';

  return data;
}
