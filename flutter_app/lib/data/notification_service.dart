import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../core/localization.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';

class NotificationService {
  static int _generation = 0;
  static const channel = MethodChannel('in.hinducalendar/device');
  static Future<Map<String, dynamic>> status() async {
    try {
      return Map<String, dynamic>.from(
        await channel.invokeMethod('status') ?? {},
      );
    } on MissingPluginException {
      return {};
    }
  }

  static Future<void> initialize() async {
    try {
      await channel.invokeMethod('initializeNotifications');
    } on MissingPluginException {
      /* Android only. */
    }
  }

  static Future<void> configure(
    bool morning,
    bool events,
    bool sound, {
    int morningMinute = 300,
    int eventsMinute = 300,
  }) async => channel.invokeMethod('configure', {
    'morning': morning,
    'events': events,
    'sound': sound,
    'morningMinute': morningMinute,
    'eventsMinute': eventsMinute,
  });

  static Future<void> openSettings(String method) async =>
      channel.invokeMethod(method);

  static Future<bool> test(
    AppLanguage language, {
    bool delayed = false,
  }) async =>
      await channel.invokeMethod<bool>('testNotification', {
        'title': language == AppLanguage.hi
            ? 'सूचना परीक्षण'
            : 'Notification test',
        'body': language == AppLanguage.hi
            ? 'हिन्दू कैलेंडर की परीक्षण सूचना प्राप्त हुई।'
            : 'Your Hindu Calendar test notification arrived.',
        'delayed': delayed,
      }) ??
      false;
  static Future<void> refresh({
    required GeoLocation location,
    required AppLanguage language,
    required Map<int, DateTime> overrides,
    required List<PersonalEvent> events,
  }) async {
    final generation = ++_generation;
    final settings = await status();
    if (settings['morning'] != true && settings['events'] != true) return;
    final now = DateTime.now();
    final payload = await compute(notificationPayload, (
      DateTime.utc(now.year, now.month, now.day),
      location,
      language,
      overrides,
      events,
    ));
    if (generation != _generation) return;
    await channel.invokeMethod('cache', jsonEncode(payload));
  }

  static Future<void> created(PersonalEvent event, AppLanguage language) async {
    try {
      await channel.invokeMethod('created', {
        'title': language == AppLanguage.hi
            ? 'कार्यक्रम सहेजा गया'
            : 'Event saved',
        'body': event.title,
      });
    } on MissingPluginException {
      /* Native notifications are Android-only. */
    }
  }
}

/// Rolling offline summaries. Native daily alarm delivers immediately and asks
/// a bounded background worker to renew this cache without opening the UI.
Map<String, Map<String, String>> notificationPayload(
  (DateTime, GeoLocation, AppLanguage, Map<int, DateTime>, List<PersonalEvent>)
  args,
) {
  final (start, location, language, overrides, events) = args;
  const panchang = PanchangEngine();
  final festival = FestivalEngine(panchang, holikaOverrides: overrides);
  final matcher = PersonalEventMatcher(panchang);
  final result = <String, Map<String, String>>{};
  for (var i = 0; i < 32; i++) {
    final date = start.add(Duration(days: i));
    final cell = panchang.monthCell(date, location);
    final hi = language == AppLanguage.hi;
    final names = festival
        .lightweightForDate(
          date,
          location,
          major: festival.majorFestivalsForYear(date.year, location),
        )
        .map((f) => hi ? f.nameHi : f.nameEn)
        .join(' · ');
    final personal = matcher
        .eventsOnDate(events, date, location)
        .map((e) => e.title)
        .join(' · ');
    final month = (hi ? monthNamesHi : monthNamesEn)[date.month - 1];
    result[date.toIso8601String().substring(0, 10)] = {
      'title': '${date.day} $month ${date.year}',
      'body':
          '${hi ? cell.pakshaHi : cell.pakshaEn} ${hi ? cell.tithi.hi : cell.tithi.en}${names.isEmpty ? '' : '\n$names'}',
      'events': personal,
    };
  }
  return result;
}
