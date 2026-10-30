import 'dart:io';
import 'dart:convert';
import 'package:hindu_calendar/data/daily_discoveries.dart';

void main() => stdout.writeln(jsonEncode(DailyDiscoveries.entries
    .map((e) => {
          'id': e.id,
          'titleHi': e.titleHi,
          'titleEn': e.titleEn,
          'source': e.source,
          'url': e.url,
          'teacherHi': e.teacherHi,
          'teacherEn': e.teacherEn,
          'reference': e.reference,
          'section': e.section,
          'group': e.group,
          'bodyHi': e.bodyHi,
          'bodyEn': e.bodyEn,
          'promptHi': e.promptHi,
          'promptEn': e.promptEn,
          'months': e.hinduMonths,
          'tithis': e.tithis,
          'festivals': e.festivalIds,
          'dated': e.isDated,
        })
    .toList()));
