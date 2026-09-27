enum AppLanguage { hi, en }

class L10n {
  const L10n(this.language);
  final AppLanguage language;
  bool get isHindi => language == AppLanguage.hi;

  String pick(String hi, String en) => isHindi ? hi : en;

  String get appName => pick('हिन्दू कैलेंडर', 'Hindu Calendar');
  String get calendar => pick('कैलेंडर', 'Calendar');
  String get festivals => pick('त्योहार', 'Festivals');
  String get today => pick('आज', 'Today');
  String get tithi => pick('तिथि', 'Tithi');
  String get month => pick('मास', 'Month');
  String get paksha => pick('पक्ष', 'Paksha');
  String get panchang => pick('आज का पंचांग', 'Day Panchang');
  String get sunrise => pick('सूर्योदय', 'Sunrise');
  String get sunset => pick('सूर्यास्त', 'Sunset');
  String get moonrise => pick('चंद्रोदय', 'Moonrise');
  String get moonset => pick('चंद्रास्त', 'Moonset');
  String get nakshatra => pick('नक्षत्र', 'Nakshatra');
  String get yoga => pick('योग', 'Yoga');
  String get karana => pick('करण', 'Karana');
  String get sunMoon => pick('सूर्य और चंद्र', 'Sun & Moon');
  String get auspicious => pick('शुभ समय', 'Auspicious Time');
  String get caution => pick('सावधानी का समय', 'Caution Periods');
  String get abhijit => pick('अभिजीत मुहूर्त', 'Abhijit Muhurta');
  String get brahma => pick('ब्रह्म मुहूर्त', 'Brahma Muhurta');
  String get rahu => pick('राहुकाल', 'Rahu Kalam');
  String get yamaganda => pick('यमगण्ड', 'Yamaganda');
  String get gulika => pick('गुलिक काल', 'Gulika');
  String get samvat => pick('संवत', 'Calendar Eras');
  String get noMajorFestival => pick('आज कोई प्रमुख पर्व नहीं है।', 'No major festival today.');
  String get dayDetails => pick('दिन का विवरण', 'Day details');
  String get location => pick('स्थान', 'Location');
  String get languageLabel => pick('भाषा', 'Language');
  String get english => 'English';
  String get hindi => 'हिन्दी';
  String get adhik => pick('अधिक', 'Adhik');
  String get kshayaTithi => pick('क्षय तिथि', 'Skipped Tithi');
  String get vriddhiTithi => pick('वृद्धि तिथि', 'Repeated Tithi');
}

const monthNamesHi = ['जनवरी','फ़रवरी','मार्च','अप्रैल','मई','जून','जुलाई','अगस्त','सितंबर','अक्टूबर','नवंबर','दिसंबर'];
const monthNamesEn = ['January','February','March','April','May','June','July','August','September','October','November','December'];
const shortWeekHi = ['रवि','सोम','मंगल','बुध','गुरु','शुक्र','शनि'];
const shortWeekEn = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
