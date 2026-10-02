class GeoLocation {
  const GeoLocation({
    required this.id,
    required this.cityHi,
    required this.cityEn,
    required this.latitude,
    required this.longitude,
    this.utcOffsetMinutes = 330,
    this.stateHi = '',
    this.stateEn = '',
    this.countryCode = 'IN',
  });

  final String id;
  final String cityHi;
  final String cityEn;
  final String stateHi;
  final String stateEn;
  final String countryCode;
  final double latitude;
  final double longitude;
  final int utcOffsetMinutes;

  // Names/IDs do not identify the effective astronomical location.
  String get cacheKey => '$latitude|$longitude|$utcOffsetMinutes';

  bool get hasValidCoordinates =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      utcOffsetMinutes >= -720 &&
      utcOffsetMinutes <= 840;

  Duration get offset => Duration(minutes: utcOffsetMinutes);
}

class NamedValue {
  const NamedValue(this.index, this.hi, this.en);
  final int index;
  final String hi;
  final String en;
}

class TimeRange {
  const TimeRange(this.startUtc, this.endUtc);
  final DateTime startUtc;
  final DateTime endUtc;
}

class PanchangDay {
  const PanchangDay({
    required this.localDate,
    required this.weekdayHi,
    required this.weekdayEn,
    required this.sunriseUtc,
    required this.sunsetUtc,
    required this.moonriseUtc,
    required this.moonsetUtc,
    required this.tithi,
    required this.pakshaHi,
    required this.pakshaEn,
    required this.tithiEndUtc,
    required this.nextTithi,
    required this.nakshatra,
    required this.nakshatraEndUtc,
    required this.yoga,
    required this.yogaEndUtc,
    required this.karana,
    required this.karanaEndUtc,
    required this.amantaMonth,
    required this.purnimantaMonth,
    required this.adhikMonth,
    required this.kshayaMonthAfter,
    required this.tithiStatus,
    required this.skippedTithi,
    required this.vikramSamvat,
    required this.shakaSamvat,
    required this.sunRashi,
    required this.moonRashi,
    required this.rahuKalam,
    required this.yamaganda,
    required this.gulika,
    required this.abhijit,
    required this.brahmaMuhurta,
  });

  final DateTime localDate;
  final String weekdayHi;
  final String weekdayEn;
  final DateTime sunriseUtc;
  final DateTime sunsetUtc;
  final DateTime? moonriseUtc;
  final DateTime? moonsetUtc;
  final NamedValue tithi;
  final String pakshaHi;
  final String pakshaEn;
  final DateTime tithiEndUtc;
  final NamedValue nextTithi;
  final NamedValue nakshatra;
  final DateTime nakshatraEndUtc;
  final NamedValue yoga;
  final DateTime yogaEndUtc;
  final NamedValue karana;
  final DateTime karanaEndUtc;
  final NamedValue amantaMonth;
  final NamedValue purnimantaMonth;
  final bool adhikMonth;
  final NamedValue? kshayaMonthAfter;
  final String tithiStatus;
  final NamedValue? skippedTithi;
  final int vikramSamvat;
  final int shakaSamvat;
  final NamedValue sunRashi;
  final NamedValue moonRashi;
  final TimeRange rahuKalam;
  final TimeRange yamaganda;
  final TimeRange gulika;
  final TimeRange abhijit;
  final TimeRange brahmaMuhurta;
}

class FestivalObservance {
  const FestivalObservance({
    required this.id,
    required this.nameHi,
    required this.nameEn,
    required this.localDate,
    required this.category,
    required this.importance,
    required this.selectionBasis,
    this.basisTimeUtc,
    this.notesHi,
    this.notesEn,
  });

  final String id;
  final String nameHi;
  final String nameEn;
  final DateTime localDate;
  final String category;
  final int importance;
  final String selectionBasis;
  final DateTime? basisTimeUtc;
  final String? notesHi;
  final String? notesEn;
}
