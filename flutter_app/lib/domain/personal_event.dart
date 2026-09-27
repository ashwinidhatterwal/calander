import 'models.dart';
import 'panchang_engine.dart';

enum PersonalEventBasis { gregorian, hinduTithi }
enum PersonalEventPaksha { shukla, krishna }
enum PersonalEventKind { general, birthday, anniversary, puja, vrat, family }

class PersonalEvent {
  const PersonalEvent({
    required this.id,
    required this.title,
    required this.kind,
    required this.basis,
    required this.repeatYearly,
    this.note = '',
    this.gregorianYear,
    this.gregorianMonth,
    this.gregorianDay,
    this.hinduMonth,
    this.hinduPaksha,
    this.hinduTithi,
    this.adhikMonth = false,
  });

  final String id;
  final String title;
  final String note;
  final PersonalEventKind kind;
  final PersonalEventBasis basis;
  final bool repeatYearly;
  final int? gregorianYear;
  final int? gregorianMonth;
  final int? gregorianDay;
  final int? hinduMonth;
  final PersonalEventPaksha? hinduPaksha;
  final int? hinduTithi;
  final bool adhikMonth;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'note': note,
        'kind': kind.name,
        'basis': basis.name,
        'repeatYearly': repeatYearly,
        'gregorianYear': gregorianYear,
        'gregorianMonth': gregorianMonth,
        'gregorianDay': gregorianDay,
        'hinduMonth': hinduMonth,
        'hinduPaksha': hinduPaksha?.name,
        'hinduTithi': hinduTithi,
        'adhikMonth': adhikMonth,
      };

  factory PersonalEvent.fromJson(Map<String, dynamic> json) {
    T enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
      if (name == null) return fallback;
      return values.firstWhere((x) => x.name == name, orElse: () => fallback);
    }

    return PersonalEvent(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      note: json['note'] as String? ?? '',
      kind: enumValue(PersonalEventKind.values, json['kind'] as String?, PersonalEventKind.general),
      basis: enumValue(PersonalEventBasis.values, json['basis'] as String?, PersonalEventBasis.gregorian),
      repeatYearly: json['repeatYearly'] as bool? ?? true,
      gregorianYear: json['gregorianYear'] as int?,
      gregorianMonth: json['gregorianMonth'] as int?,
      gregorianDay: json['gregorianDay'] as int?,
      hinduMonth: json['hinduMonth'] as int?,
      hinduPaksha: json['hinduPaksha'] == null
          ? null
          : enumValue(PersonalEventPaksha.values, json['hinduPaksha'] as String?, PersonalEventPaksha.shukla),
      hinduTithi: json['hinduTithi'] as int?,
      adhikMonth: json['adhikMonth'] as bool? ?? false,
    );
  }
}

class ResolvedPersonalEvent {
  const ResolvedPersonalEvent(this.event, this.date);
  final PersonalEvent event;
  final DateTime date;
}

class PersonalEventMatcher {
  const PersonalEventMatcher(this.panchang);
  final PanchangEngine panchang;

  bool occursOn(PersonalEvent event, DateTime date, GeoLocation location) {
    final d = DateTime.utc(date.year, date.month, date.day);
    if (event.basis == PersonalEventBasis.gregorian) {
      if (event.gregorianMonth != d.month || event.gregorianDay != d.day) return false;
      return event.repeatYearly || event.gregorianYear == d.year;
    }

    final cell = panchang.monthCell(d, location);
    return matchesHinduCell(event, cell);
  }

  bool matchesHinduCell(
    PersonalEvent event,
    ({NamedValue tithi, String pakshaHi, String pakshaEn, NamedValue month, bool adhik}) cell,
  ) {
    if (event.basis != PersonalEventBasis.hinduTithi) return false;
    final isShukla = cell.pakshaHi.startsWith('शुक्ल');
    final expectedShukla = event.hinduPaksha == PersonalEventPaksha.shukla;
    return event.hinduMonth == cell.month.index &&
        event.hinduTithi == cell.tithi.index &&
        event.adhikMonth == cell.adhik &&
        isShukla == expectedShukla;
  }

  List<PersonalEvent> eventsOnDate(
    List<PersonalEvent> events,
    DateTime date,
    GeoLocation location,
  ) => events.where((event) => occursOn(event, date, location)).toList(growable: false);

  List<ResolvedPersonalEvent> upcoming(
    List<PersonalEvent> events,
    DateTime from,
    GeoLocation location, {
    int limit = 24,
    int horizonDays = 430,
  }) {
    if (events.isEmpty) return const [];
    final start = DateTime.utc(from.year, from.month, from.day);
    final result = <ResolvedPersonalEvent>[];
    final seen = <String>{};

    for (var i = 0; i <= horizonDays && result.length < limit; i++) {
      final date = start.add(Duration(days: i));
      ({NamedValue tithi, String pakshaHi, String pakshaEn, NamedValue month, bool adhik})? cell;
      for (final event in events) {
        if (seen.contains(event.id)) continue;
        bool match;
        if (event.basis == PersonalEventBasis.gregorian) {
          match = event.gregorianMonth == date.month &&
              event.gregorianDay == date.day &&
              (event.repeatYearly || event.gregorianYear == date.year);
        } else {
          final effectiveCell = cell ??= panchang.monthCell(date, location);
          match = matchesHinduCell(event, effectiveCell);
        }
        if (match) {
          result.add(ResolvedPersonalEvent(event, date));
          seen.add(event.id);
        }
      }
    }
    result.sort((a, b) => a.date.compareTo(b.date));
    return result;
  }
}

const personalTithiHi = <String>[
  'प्रतिपदा','द्वितीया','तृतीया','चतुर्थी','पंचमी','षष्ठी','सप्तमी','अष्टमी','नवमी','दशमी','एकादशी','द्वादशी','त्रयोदशी','चतुर्दशी','पूर्णिमा / अमावस्या'
];
const personalTithiEn = <String>[
  'Pratipada','Dwitiya','Tritiya','Chaturthi','Panchami','Shashthi','Saptami','Ashtami','Navami','Dashami','Ekadashi','Dwadashi','Trayodashi','Chaturdashi','Purnima / Amavasya'
];
