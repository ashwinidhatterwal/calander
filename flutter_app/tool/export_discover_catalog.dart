import 'dart:io';
import 'dart:convert';
import 'package:hindu_calendar/data/daily_discoveries.dart';
void main() => stdout.writeln(jsonEncode(DailyDiscoveries.entries.map((e) => {
  'id': e.id, 'titleHi': e.titleHi, 'titleEn': e.titleEn, 'source': e.source,
  'url': e.url, 'months': e.hinduMonths, 'tithis': e.tithis,
  'festivals': e.festivalIds, 'dated': e.isDated,
}).toList()));
