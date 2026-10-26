import 'package:flutter/services.dart';

import '../core/localization.dart';
import '../domain/civil_holidays.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';

/// Uses the same sunrise calculations as the month grid. Personal events are
/// deliberately excluded from a calendar intended for sharing.
class CalendarPdfService {
  static const channel = MethodChannel('in.hinducalendar/calendar_pdf');
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=in.hinducalendar.hindu_calendar';
  static Future<Uint8List> build({
    required DateTime month,
    required bool yearly,
    required AppLanguage language,
    required GeoLocation location,
    required PanchangEngine panchang,
    required FestivalEngine festival,
    ValueChanged<int>? onProgress,
  }) async {
    final l = L10n(language);
    final major = await festival.majorFestivalsAsync(month.year, location);
    final pages = <Map<String, Object>>[];
    for (var index = 0; index < (yearly ? 12 : 1); index++) {
      final date = DateTime.utc(month.year, yearly ? index + 1 : month.month);
      final days = <Map<String, String>>[];
      for (
        var day = 1;
        day <= DateTime.utc(date.year, date.month + 1, 0).day;
        day++
      ) {
        final d = DateTime.utc(date.year, date.month, day);
        final cell = panchang.monthCell(d, location);
        final detail = panchang.buildDay(d, location);
        String time(DateTime utc) => panchang.time12(
          utc,
          location,
          amLabel: l.pick('पु.', 'AM'),
          pmLabel: l.pick('अप.', 'PM'),
        );
        final nextDay = panchang
            .localDateOfUtc(detail.tithiEndUtc, location)
            .isAfter(d);
        final raw =
            cell.tithi.index + (cell.pakshaHi.startsWith('शुक्ल') ? 0 : 15);
        final events = major
            .where(
              (x) =>
                  x.localDate.year == d.year &&
                  x.localDate.month == d.month &&
                  x.localDate.day == d.day,
            )
            .toList();
        final recurring = sunriseObservances(
          d,
          TithiState(cell.tithi, cell.pakshaHi, cell.pakshaEn, raw),
          cell.month,
        );
        final names = <String>{
          for (final e in events) l.pick(e.nameHi, e.nameEn),
          if (events.isEmpty)
            for (final e in recurring) l.pick(e.nameHi, e.nameEn),
          for (final h in nationalHolidays.where((h) => h.occursOn(d)))
            l.pick(h.nameHi, h.nameEn),
        };
        days.add({
          'day': '$day',
          'tithi': panchang
              .tithisForDay(d, location)
              .map((part) => l.pick(part.tithi.hi, part.tithi.en))
              .join(' → '),
          'paksha': l.pick(cell.pakshaHi, cell.pakshaEn),
          'events': names.join(' · '),
          'hinduMonth':
              '${cell.adhik ? '${l.adhik} ' : ''}${l.pick(cell.month.hi, cell.month.en)}',
          'samvat': '${detail.vikramSamvat}',
          'nakshatra': l.pick(detail.nakshatra.hi, detail.nakshatra.en),
          'sunrise': time(detail.sunriseUtc),
          'sunset': time(detail.sunsetUtc),
          'tithiEnd': '${time(detail.tithiEndUtc)}${nextDay ? ' +1' : ''}',
        });
        if (day % 7 == 0) await Future<void>.delayed(Duration.zero);
      }
      final months = language == AppLanguage.hi ? monthNamesHi : monthNamesEn;
      final years = days.map((d) => d['samvat']!).toSet().join('–');
      pages.add({
        'days': days,
        'offset': date.weekday % 7,
        'appName': l.appName,
        'location': l.pick(location.cityHi, location.cityEn),
        'hinduMonths':
            '${days.map((d) => d['hinduMonth']!).toSet().join(' • ')} ${l.month}',
        'gregorianMonth': '${months[date.month - 1]} ${date.year}',
        'samvat': l.pick('विक्रम संवत $years', 'Vikram Samvat $years'),
        'caption': l.pick(
          'सूर्योदय से तिथि क्रम • भारतीय समय',
          'Tithis from sunrise • IST',
        ),
        'weekdays': language == AppLanguage.hi ? shortWeekHi : shortWeekEn,
        'note': l.pick(
          '→ तिथि बदलने का क्रम। समय पहले बदलाव का है। +1 का अर्थ अगला दिन है।',
          '→ shows tithi changes. Time is the first change; +1 means the following day.',
        ),
        'nakshatraLabel': l.pick('नक्षत्र', 'Nak.'),
        'sunriseLabel': l.sunrise,
        'sunsetLabel': l.sunset,
        'tithiEndLabel': l.pick('बदलाव', 'Changes'),
      });
      onProgress?.call(index + 1);
      // Let the progress indicator paint between months.
      await Future<void>.delayed(Duration.zero);
    }
    final bytes = await channel.invokeMethod<Uint8List>('buildVector', {
      'pages': pages,
      'playStoreUrl': playStoreUrl,
    });
    if (bytes == null || bytes.length < 8) {
      throw StateError('PDF export did not produce a document');
    }
    return bytes;
  }

  static Future<void> share(Uint8List bytes, String filename) => channel
      .invokeMethod<void>('share', {'bytes': bytes, 'filename': filename});
}
