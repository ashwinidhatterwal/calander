import 'package:flutter/foundation.dart';
import 'models.dart';
import 'panchang_engine.dart';

class FestivalRule {
  const FestivalRule(
    this.id,
    this.nameHi,
    this.nameEn,
    this.monthEn,
    this.paksha,
    this.tithiIndex,
    this.selector,
    this.gregorianMonths, {
    this.importance = 3,
    this.notesHi,
    this.notesEn,
  });
  final String id, nameHi, nameEn, monthEn, paksha, selector;
  final int tithiIndex, importance;
  final List<int> gregorianMonths;
  final String? notesHi, notesEn;
}

const majorRules = <FestivalRule>[
  FestivalRule(
    'maha_shivaratri',
    'महाशिवरात्रि',
    'Maha Shivaratri',
    'Phalguna',
    'krishna',
    14,
    'nishita',
    [1, 2, 3],
    importance: 5,
  ),
  FestivalRule(
    'rama_navami',
    'राम नवमी',
    'Rama Navami',
    'Chaitra',
    'shukla',
    9,
    'madhyahna',
    [3, 4],
    importance: 5,
  ),
  FestivalRule(
    'raksha_bandhan',
    'रक्षाबंधन',
    'Raksha Bandhan',
    'Shravana',
    'shukla',
    15,
    'sunrise',
    [7, 8, 9],
    importance: 5,
  ),
  FestivalRule(
    'janmashtami',
    'श्रीकृष्ण जन्माष्टमी',
    'Krishna Janmashtami',
    'Bhadrapada',
    'krishna',
    8,
    'sunrise',
    [8, 9],
    importance: 5,
    notesHi:
        'यह सामान्य उत्तर भारतीय तिथि चयन है; वैष्णव/सम्प्रदाय-विशिष्ट नियम अलग हो सकते हैं।',
    notesEn:
        'General North-Indian date selection; sect-specific Vaishnava rules may differ.',
  ),
  FestivalRule(
    'ganesh_chaturthi',
    'गणेश चतुर्थी',
    'Ganesh Chaturthi',
    'Bhadrapada',
    'shukla',
    4,
    'madhyahna',
    [8, 9],
    importance: 4,
  ),
  FestivalRule(
    'shardiya_navratri',
    'शारदीय नवरात्रि आरम्भ',
    'Shardiya Navratri Begins',
    'Ashwin',
    'shukla',
    1,
    'first_third_day',
    [9, 10],
    importance: 5,
  ),
  FestivalRule(
    'chaitra_navratri',
    'चैत्र नवरात्रि आरम्भ',
    'Chaitra Navratri Begins',
    'Chaitra',
    'shukla',
    1,
    'first_third_day',
    [3, 4],
    importance: 5,
  ),
  FestivalRule(
    'chaitra_durga_ashtami',
    'चैत्र दुर्गा अष्टमी',
    'Chaitra Durga Ashtami',
    'Chaitra',
    'shukla',
    8,
    'sunrise',
    [3, 4],
    importance: 5,
  ),
  FestivalRule(
    'durga_ashtami',
    'दुर्गा अष्टमी / महाष्टमी',
    'Durga Ashtami / Mahashtami',
    'Ashwin',
    'shukla',
    8,
    'sunrise',
    [9, 10],
    importance: 5,
  ),
  FestivalRule(
    'vijayadashami',
    'विजयादशमी / दशहरा',
    'Vijayadashami / Dussehra',
    'Ashwin',
    'shukla',
    10,
    'aparahna',
    [9, 10],
    importance: 5,
    notesHi:
        'उत्तर भारतीय अपराह्न-आधारित दशहरा। सूर्योदय पर नवमी होने पर भी दोपहर में दशमी होने से पर्व इसी दिन हो सकता है; बंगाल की तिथि अलग हो सकती है।',
    notesEn:
        'North-Indian Aparahna-based Dussehra. Dashami during the afternoon can determine the festival even if Navami prevails at sunrise; the Bengal date may differ.',
  ),
  FestivalRule(
    'sharad_purnima',
    'शरद पूर्णिमा / कोजागरी',
    'Sharad Purnima / Kojagari',
    'Ashwin',
    'shukla',
    15,
    'nishita',
    [9, 10, 11],
    importance: 5,
    notesHi:
        'यह पर्व रात में पूर्णिमा होने पर मनाया जाता है; सूर्योदय की तिथि अलग हो सकती है।',
    notesEn:
        'Observed when Purnima prevails at night; the sunrise tithi may differ.',
  ),
  FestivalRule(
    'karwa_chauth',
    'करवा चौथ',
    'Karwa Chauth',
    'Kartika',
    'krishna',
    4,
    'moonrise',
    [9, 10, 11],
    importance: 5,
  ),
  FestivalRule(
    'dhanteras',
    'धनतेरस',
    'Dhanteras',
    'Kartika',
    'krishna',
    13,
    'pradosha',
    [10, 11],
    importance: 4,
  ),
  FestivalRule(
    'diwali',
    'दीपावली',
    'Diwali',
    'Kartika',
    'krishna',
    15,
    'pradosha',
    [10, 11],
    importance: 5,
  ),
  FestivalRule(
    'govardhan_puja',
    'गोवर्धन पूजा',
    'Govardhan Puja',
    'Kartika',
    'shukla',
    1,
    'pratah',
    [10, 11],
    importance: 4,
  ),
  FestivalRule(
    'bhai_dooj',
    'भाई दूज',
    'Bhai Dooj',
    'Kartika',
    'shukla',
    2,
    'aparahna_with_sunrise',
    [10, 11],
    importance: 4,
  ),
];

class FestivalEngine {
  FestivalEngine(this.panchang, {Map<int, DateTime>? holikaOverrides})
    : holikaOverrides = holikaOverrides ?? const {};
  final PanchangEngine panchang;
  final Map<int, DateTime> holikaOverrides;
  final Map<String, List<FestivalObservance>> _majorCache = {};
  final Map<String, Future<List<FestivalObservance>>> _pending = {};
  Future<List<FestivalObservance>> majorFestivalsAsync(
    int year,
    GeoLocation location,
  ) {
    final key = '$year|${location.cacheKey}';
    final cached = _majorCache[key];
    if (cached != null) return Future.value(cached);
    return _pending.putIfAbsent(
      key,
      () => compute(_calculateYear, (year, location, holikaOverrides))
          .then((items) {
            _majorCache[key] = items;
            return items;
          })
          .whenComplete(() {
            _pending.remove(key);
          }),
    );
  }

  Duration _scale(Duration d, double f) =>
      Duration(microseconds: (d.inMicroseconds * f).round());
  DateTime _mid(DateTime a, DateTime b) => a.add(_scale(b.difference(a), 0.5));

  List<DateTime>? _window(DateTime d, GeoLocation loc, String selector) {
    final ss = panchang.sunriseSunset(d, loc),
        sunrise = ss[0],
        sunset = ss[1],
        daylight = sunset.difference(sunrise);
    if (selector == 'sunrise') return [sunrise, sunrise];
    if (selector == 'daylight') return [sunrise, sunset];
    if (selector == 'pratah') {
      return [sunrise, sunrise.add(_scale(daylight, 0.2))];
    }
    if (selector == 'madhyahna') {
      return [
        sunrise.add(_scale(daylight, 0.4)),
        sunrise.add(_scale(daylight, 0.6)),
      ];
    }
    if (selector == 'first_third_day') {
      return [sunrise, sunrise.add(_scale(daylight, 1 / 3))];
    }
    if (selector == 'aparahna' || selector == 'aparahna_with_sunrise') {
      return [
        sunrise.add(_scale(daylight, 0.6)),
        sunrise.add(_scale(daylight, 0.8)),
      ];
    }
    if (selector == 'pradosha') {
      return [sunset, sunset.add(const Duration(minutes: 144))];
    }
    if (selector == 'nishita') {
      final nextSunrise = panchang.sunriseSunset(
            panchang.nextCivilDay(d),
            loc,
          )[0],
          night = nextSunrise.difference(sunset),
          mid = sunset.add(_scale(night, 0.5)),
          half = _scale(night, 1 / 30);
      return [mid.subtract(half), mid.add(half)];
    }
    if (selector == 'moonrise') {
      final rise = panchang.moonriseMoonset(d, loc)[0];
      return rise == null ? null : [rise, rise];
    }
    throw ArgumentError('Unknown selector $selector');
  }

  bool _matchesAt(DateTime instant, FestivalRule rule) {
    final t = panchang.tithiAt(instant);
    if ((t.rawIndex <= 15 ? 'shukla' : 'krishna') != rule.paksha ||
        t.value.index != rule.tithiIndex) {
      return false;
    }
    final m = panchang.lunarMonthDetailsAt(instant);
    // Annual festivals belong to the regular lunar month, not an adhik copy.
    return m.purnimanta.en == rule.monthEn && !m.adhik;
  }

  ({bool match, DateTime? basis}) _matches(
    DateTime d,
    GeoLocation loc,
    FestivalRule rule,
  ) {
    final w = _window(d, loc, rule.selector);
    if (w == null) return (match: false, basis: null);
    if (rule.selector == 'aparahna_with_sunrise' &&
        !_matchesAt(panchang.sunriseSunset(d, loc)[0], rule)) {
      return (match: false, basis: null);
    }
    if (w[0] == w[1]) {
      return (match: _matchesAt(w[0], rule), basis: w[0]);
    }
    // Walk complete tithi intervals. Sampling five points can miss a short
    // overlap at the edge of a puja window and select the wrong civil day.
    var cursor = w[0];
    while (cursor.isBefore(w[1])) {
      final transition = panchang.nextTithiTransition(cursor);
      final end = transition.isBefore(w[1]) ? transition : w[1];
      final probe = _mid(cursor, end);
      if (_matchesAt(probe, rule)) {
        return (match: true, basis: probe);
      }
      cursor = transition.add(const Duration(milliseconds: 1));
    }
    return (match: false, basis: null);
  }

  Iterable<DateTime> _candidates(int year, List<int> months) sync* {
    final min = months.reduce((a, b) => a < b ? a : b),
        max = months.reduce((a, b) => a > b ? a : b);
    var d = DateTime.utc(year, min, 1);
    final end = DateTime.utc(
      year,
      max + 1,
      1,
    ).subtract(const Duration(days: 1));
    while (!d.isAfter(end)) {
      if (months.contains(d.month)) yield d;
      d = d.add(const Duration(days: 1));
    }
  }

  FestivalObservance findMajor(int year, GeoLocation loc, String id) {
    final rule = majorRules.firstWhere((r) => r.id == id);
    // Reviewed North India exception; sunrise alone is insufficient here.
    // Source: Drik Panchang Krishna Janmashtami 2025 (Jaipur/New Delhi).
    if (id == 'janmashtami' && year == 2025 && loc.countryCode == 'IN') {
      return FestivalObservance(
        id: rule.id,
        nameHi: rule.nameHi,
        nameEn: rule.nameEn,
        localDate: DateTime.utc(2025, 8, 15),
        category: 'festival',
        importance: rule.importance,
        selectionBasis: 'reviewed_north_india_janmashtami_2025',
        notesHi:
            'समीक्षित सामान्य उत्तर भारतीय तिथि; वैष्णव/सम्प्रदाय की तिथि अलग हो सकती है।',
        notesEn:
            'Reviewed general North-Indian date; sect-specific observance may differ.',
      );
    }
    for (final d in _candidates(year, rule.gregorianMonths)) {
      final m = _matches(d, loc, rule);
      if (m.match) {
        return FestivalObservance(
          id: rule.id,
          nameHi: rule.nameHi,
          nameEn: rule.nameEn,
          localDate: d,
          category: 'festival',
          importance: rule.importance,
          selectionBasis: rule.selector,
          basisTimeUtc: m.basis,
          notesHi: rule.notesHi,
          notesEn: rule.notesEn,
        );
      }
    }
    // Explicit traditional fallbacks when the target tithi is absent from
    // the preferred window on both adjacent dates; never fabricate a date.
    if (id == 'dhanteras' || id == 'govardhan_puja') {
      final fallback = FestivalRule(
        rule.id,
        rule.nameHi,
        rule.nameEn,
        rule.monthEn,
        rule.paksha,
        rule.tithiIndex,
        id == 'dhanteras' ? 'sunrise' : 'daylight',
        rule.gregorianMonths,
      );
      for (final d in _candidates(year, rule.gregorianMonths)) {
        final match = _matches(d, loc, fallback);
        if (match.match) {
          return FestivalObservance(
            id: rule.id,
            nameHi: rule.nameHi,
            nameEn: rule.nameEn,
            localDate: d,
            category: 'festival',
            importance: rule.importance,
            selectionBasis: id == 'dhanteras'
                ? 'trayodashi_sunrise_when_pradosha_absent'
                : 'pratipada_daylight_when_pratah_absent',
            basisTimeUtc: match.basis,
          );
        }
      }
    }
    if (id == 'karwa_chauth') {
      for (final d in _candidates(year, rule.gregorianMonths)) {
        final sunrise = panchang.sunriseSunset(d, loc)[0];
        if (_matchesAt(sunrise, rule)) {
          return FestivalObservance(
            id: rule.id,
            nameHi: rule.nameHi,
            nameEn: rule.nameEn,
            localDate: d,
            category: 'festival',
            importance: rule.importance,
            selectionBasis: 'chaturthi_sunrise_when_neither_moonrise_matches',
            basisTimeUtc: sunrise,
          );
        }
      }
    }
    throw StateError('No $id match found for $year');
  }

  FestivalObservance _holika(int year, GeoLocation loc) {
    final override = holikaOverrides[year];
    if (override != null) {
      return FestivalObservance(
        id: 'holika_dahan',
        nameHi: 'होलिका दहन',
        nameEn: 'Holika Dahan',
        localDate: override,
        category: 'festival',
        importance: 5,
        selectionBasis: 'reviewed_north_india_override',
        notesHi:
            'भद्रा/प्रदोष के जटिल अपवाद के लिए संपादकीय रूप से सत्यापित उत्तर-भारत तिथि।',
        notesEn:
            'Editorially reviewed North-India date for a complex Bhadra/Pradosha edge case.',
      );
    }
    const rule = FestivalRule(
      'holika_dahan',
      'होलिका दहन',
      'Holika Dahan',
      'Phalguna',
      'shukla',
      15,
      'pradosha',
      [2, 3, 4],
      importance: 5,
    );
    for (final d in _candidates(year, rule.gregorianMonths)) {
      final m = _matches(d, loc, rule);
      if (m.match) {
        return FestivalObservance(
          id: rule.id,
          nameHi: rule.nameHi,
          nameEn: rule.nameEn,
          localDate: d,
          category: 'festival',
          importance: 5,
          selectionBasis: 'phalguna_purnima_overlaps_pradosha',
          basisTimeUtc: m.basis,
          notesHi:
              'भद्रा के सूक्ष्म मुहूर्त नियम अलग सत्यापन परत में रखे गए हैं।',
          notesEn:
              'Detailed Bhadra muhurta rules are kept in a separate validation layer.',
        );
      }
    }
    throw StateError('No Holika Dahan match found');
  }

  List<FestivalObservance> majorFestivalsForYear(int year, GeoLocation loc) {
    final key = '$year|${loc.cacheKey}';
    final cached = _majorCache[key];
    if (cached != null) return cached;
    final items = [for (final r in majorRules) findMajor(year, loc, r.id)];
    final h = _holika(year, loc);
    items.add(h);
    items.add(
      FestivalObservance(
        id: 'holi',
        nameHi: 'होली / धुलंडी',
        nameEn: 'Holi / Dhulandi',
        localDate: h.localDate.add(const Duration(days: 1)),
        category: 'festival',
        importance: 5,
        selectionBasis: 'day_after_holika_dahan',
      ),
    );
    items.sort((a, b) => a.localDate.compareTo(b.localDate));
    final frozen = List<FestivalObservance>.unmodifiable(items);
    _majorCache[key] = frozen;
    return frozen;
  }

  /// Invalidate only the departing location; preserve astronomy and other years.
  void clearLocationCache(GeoLocation location) {
    _majorCache.removeWhere((key, _) => key.endsWith('|${location.cacheKey}'));
  }

  /// Fast observances for a visible calendar date. Major festivals can be passed
  /// from [majorFestivalsForYear]; recurring events are derived directly.
  List<FestivalObservance> lightweightForDate(
    DateTime d,
    GeoLocation loc, {
    List<FestivalObservance> major = const [],
  }) {
    final out = <FestivalObservance>[];
    out.addAll(
      major.where(
        (x) =>
            x.localDate.year == d.year &&
            x.localDate.month == d.month &&
            x.localDate.day == d.day,
      ),
    );
    final sr = panchang.sunriseSunset(d, loc)[0],
        t = panchang.tithiAt(sr),
        month = panchang.lunarMonthDetailsAt(sr).purnimanta;
    out.addAll(sunriseObservances(d, t, month));
    out.sort((a, b) => b.importance.compareTo(a.importance));
    return out;
  }
}

/// Shared sunrise labels. No GPS, year scan or moonrise calculation is needed.
List<FestivalObservance> sunriseObservances(
  DateTime date,
  TithiState t,
  NamedValue month,
) {
  FestivalObservance item(
    String id,
    String hi,
    String en,
    String category,
    int importance,
  ) => FestivalObservance(
    id: id,
    nameHi: hi,
    nameEn: en,
    localDate: date,
    category: category,
    importance: importance,
    selectionBasis: 'tithi_at_sunrise',
  );
  return [
    if (t.value.index == 11) item('ekadashi', 'एकादशी', 'Ekadashi', 'vrat', 3),
    if (t.rawIndex == 15)
      item(
        'purnima',
        '${month.hi} पूर्णिमा',
        '${month.en} Purnima',
        'lunar_day',
        2,
      ),
    if (t.rawIndex == 30)
      item(
        'amavasya',
        '${month.hi} अमावस्या',
        '${month.en} Amavasya',
        'lunar_day',
        2,
      ),
  ];
}

List<FestivalObservance> _calculateYear(
  (int, GeoLocation, Map<int, DateTime>) args,
) => FestivalEngine(
  const PanchangEngine(),
  holikaOverrides: args.$3,
).majorFestivalsForYear(args.$1, args.$2);
