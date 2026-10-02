/// Civil holidays are deliberately independent of Hindu festival selection.
/// Bundled 2026 reference dates cover all 28 states and 8 union territories.
import 'state_holidays_2026.dart';
export 'state_holidays_2026.dart' show holidayRegionAliases;
class CivilHoliday {
  const CivilHoliday(
    this.id,
    this.nameHi,
    this.nameEn,
    this.month,
    this.day, {
    this.stateCode,
    this.year,
  });
  final String id;
  final String nameHi;
  final String nameEn;
  final int month;
  final int day;
  final String? stateCode;
  final int? year;
  DateTime dateInYear(int year) => DateTime.utc(year, month, day);
  bool occursOn(DateTime date) =>
      (year == null || date.year == year) &&
      date.month == month &&
      date.day == day;
}

const nationalHolidays = <CivilHoliday>[
  CivilHoliday('republic_day', 'गणतंत्र दिवस', 'Republic Day', 1, 26),
  CivilHoliday(
    'independence_day',
    'स्वतंत्रता दिवस',
    'Independence Day',
    8,
    15,
  ),
  CivilHoliday('gandhi_jayanti', 'गांधी जयंती', 'Gandhi Jayanti', 10, 2),
];

/// State dates are year-specific published government-office holidays, not
/// computed Hindu observances. No prediction or copying into later years.
String? holidayRegion(String state, String country) {
  if (country != 'IN') return null;
  final key = state.toLowerCase().trim().replaceAll('&', 'and');
  return holidayRegionAliases[key];
}

const stateHolidaySources = {
  'RJ': 'https://emitra.rajasthan.gov.in/emitra/holiday-list',
  'DL':
      'https://dkvib.delhi.gov.in/sites/default/files/DKVIB/circulars-orders/govtholidays2026.pdf',
};
const curatedStateHolidays = <CivilHoliday>[
  CivilHoliday('DL_holi', 'होली', 'Holi', 3, 4, stateCode: 'DL', year: 2026),
  CivilHoliday('DL_eid', 'ईद-उल-फ़ित्र', 'Id-ul-Fitr', 3, 21,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_ram', 'राम नवमी', 'Ram Navami', 3, 26,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_mahavir', 'महावीर जयंती', 'Mahavir Jayanti', 3, 31,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_good_friday', 'गुड फ्राइडे', 'Good Friday', 4, 3,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_buddha', 'बुद्ध पूर्णिमा', 'Buddha Purnima', 5, 1,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_bakrid', 'ईद-उल-जुहा', 'Id-ul-Zuha', 5, 27,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_muharram', 'मुहर्रम', 'Muharram', 6, 26,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_milad', 'ईद-ए-मिलाद', 'Milad-un-Nabi', 8, 26,
      stateCode: 'DL', year: 2026),
  CivilHoliday(
      'DL_janmashtami', 'जन्माष्टमी (वैष्णव)', 'Janmashtami (Vaishnava)', 9, 4,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_dussehra', 'दशहरा', 'Dussehra', 10, 20,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_valmiki', 'महर्षि वाल्मीकि जयंती',
      'Maharishi Valmiki Jayanti', 10, 26,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_diwali', 'दीपावली', 'Diwali', 11, 8,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_nanak', 'गुरु नानक जयंती', 'Guru Nanak Jayanti', 11, 24,
      stateCode: 'DL', year: 2026),
  CivilHoliday('DL_christmas', 'क्रिसमस', 'Christmas', 12, 25,
      stateCode: 'DL', year: 2026),
  CivilHoliday(
      'RJ_ambedkar', 'डॉ. अम्बेडकर जयंती', 'Dr Ambedkar Jayanti', 4, 14,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_parashuram', 'परशुराम जयंती', 'Parashuram Jayanti', 4, 19,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_bakrid', 'ईद-उल-जुहा', 'Id-ul-Zuha', 5, 28,
      stateCode: 'RJ', year: 2026),
  CivilHoliday(
      'RJ_pratap', 'महाराणा प्रताप जयंती', 'Maharana Pratap Jayanti', 6, 17,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_muharram', 'मुहर्रम', 'Muharram', 6, 26,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_tribal', 'विश्व आदिवासी दिवस', 'World Tribal Day', 8, 9,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_milad', 'ईद-ए-मिलाद', 'Milad-un-Nabi', 8, 26,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_rakhi', 'रक्षाबंधन', 'Raksha Bandhan', 8, 28,
      stateCode: 'RJ', year: 2026),
  CivilHoliday(
      'RJ_janmashtami', 'श्रीकृष्ण जन्माष्टमी', 'Krishna Janmashtami', 9, 4,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_teja', 'रामदेव जयंती / तेजा दशमी / खेजड़ली शहीद दिवस',
      'Ramdev Jayanti / Teja Dashami / Khejadli Martyrs Day', 9, 21,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_navratri', 'नवरात्रा स्थापना / महाराजा अग्रसेन जयंती',
      'Navratri Sthapana / Maharaja Agrasen Jayanti', 10, 11,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_ashtami', 'दुर्गाष्टमी', 'Durga Ashtami', 10, 19,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_dussehra', 'विजय दशमी', 'Vijayadashami', 10, 20,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_diwali', 'दीपावली', 'Diwali', 11, 8,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_govardhan', 'गोवर्धन पूजा', 'Govardhan Puja', 11, 9,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_bhai', 'भाई दूज', 'Bhai Dooj', 11, 11,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_nanak', 'गुरु नानक जयंती', 'Guru Nanak Jayanti', 11, 24,
      stateCode: 'RJ', year: 2026),
  CivilHoliday('RJ_christmas', 'क्रिसमस', 'Christmas', 12, 25,
      stateCode: 'RJ', year: 2026),
];

final stateHolidays = <CivilHoliday>[
  ...curatedStateHolidays,
  ...bundledStateHolidays2026.where((h) => !curatedStateHolidays.any((c) =>
      c.stateCode == h.stateCode && c.month == h.month && c.day == h.day)),
];

/// Date-sorted national + effective state list, without duplicate national dates.
List<CivilHoliday> holidaysForRegion(int year, String? region) {
  final result = <CivilHoliday>[
    ...nationalHolidays,
    ...stateHolidays.where((h) => h.stateCode == region && h.year == year &&
        !nationalHolidays.any((n) => n.month == h.month && n.day == h.day)),
  ];
  result.sort((a, b) => a.dateInYear(year).compareTo(b.dateInYear(year)));
  return result;
}
