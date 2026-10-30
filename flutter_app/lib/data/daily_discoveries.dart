part 'wisdom_readings.dart';
part 'sanatan_readings.dart';

/// Editorial content checked against the linked primary sources on 2026-10-30.
/// Cultural cards rotate; only entries with a date are anniversaries.
class DailyDiscovery {
  const DailyDiscovery({
    required this.id,
    required this.titleHi,
    required this.titleEn,
    required this.bodyHi,
    required this.bodyEn,
    required this.source,
    required this.url,
    this.month,
    this.day,
    this.year,
    this.hinduMonths = const [],
    this.tithis = const [],
    this.festivalIds = const [],
    this.kind = 'tradition',
    this.teacherHi = '',
    this.teacherEn = '',
    this.reference = '',
    this.section = '',
    this.group = '',
    this.promptHi = '',
    this.promptEn = '',
    this.quote = '',
    this.referenceHi = '',
  });
  final String id, titleHi, titleEn, bodyHi, bodyEn, source, url;
  final int? month, day, year;
  final List<int> hinduMonths, tithis;
  final List<String> festivalIds;
  final String quote, referenceHi;
  final String kind;
  final String teacherHi,
      teacherEn,
      reference,
      section,
      group,
      promptHi,
      promptEn;
  bool get isDated => month != null;
}

class DailyDiscoveries {
  const DailyDiscoveries._();

  static List<DailyDiscovery> onThisDay(DateTime date) => entries
      .where(
        (e) =>
            e.month == date.month &&
            e.day == date.day &&
            (e.year == null || e.year! <= date.year),
      )
      .toList(growable: false);

  static DailyDiscovery cultureFor(DateTime date) {
    final pool = entries.where((e) => !e.isDated).toList(growable: false);
    // UTC civil dates avoid DST and time-of-day affecting daily selection.
    final index = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(2026, 1, 1)).inDays;
    return pool[index % pool.length];
  }

  /// Ordered tiers: actual observance, matching sunrise tithi, month, general.
  /// A tithi match is a reading suggestion, not a festival-date declaration.
  static List<({DailyDiscovery entry, String reason})> select({
    required DateTime date,
    required int hinduMonth,
    required int rawTithi,
    Set<String> festivals = const {},
    bool adhik = false,
  }) {
    final dayNumber = DateTime.utc(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime.utc(2026)).inDays;
    final pool = entries.where((e) => !e.isDated).toList();
    final ranked = <({DailyDiscovery entry, String reason})>[];
    final used = <String>{};
    void addTier(Iterable<DailyDiscovery> items, String reason) {
      final list = items.where((e) => !used.contains(e.id)).toList();
      if (list.isEmpty) return;
      final offset = dayNumber % list.length;
      for (var i = 0; i < list.length; i++) {
        final e = list[(i + offset) % list.length];
        used.add(e.id);
        ranked.add((entry: e, reason: reason));
      }
    }

    addTier(
      pool.where((e) => e.festivalIds.any(festivals.contains)),
      'festival',
    );
    if (!adhik) {
      addTier(
        pool.where(
          (e) =>
              e.tithis.contains(rawTithi) &&
              (e.hinduMonths.isEmpty || e.hinduMonths.contains(hinduMonth)),
        ),
        'tithi',
      );
    }
    addTier(pool.where((e) => e.hinduMonths.contains(hinduMonth)), 'month');
    addTier(pool, 'general');
    return ranked;
  }

  static const philosophyIds = {
    'gita-compassion',
    'gita-peace',
    'gita-speech',
    'gita-charity',
    'gita-respect',
    'gita-friend',
    'gita-mind',
    'gita-balance',
  };
  static const factIds = {
    'vedic',
    'kumbh',
    'garba',
    'durga',
    'ramlila',
    'ramman',
    'kutiyattam',
    'chhau',
    'kalbelia',
    'mudiyettu',
    'jantar',
    'konark',
    'chola',
    'hampi',
    'nalanda',
    'stepwell',
    'deepavali',
  };

  /// Spread each teacher's readings across the cycle instead of showing them
  /// in one consecutive block. Every reading occurs exactly once per cycle.
  static List<DailyDiscovery> _interleave(Iterable<DailyDiscovery> pool) {
    final groups = <String, List<DailyDiscovery>>{};
    for (final entry in pool) {
      groups
          .putIfAbsent(entry.group.isEmpty ? 'gita' : entry.group, () => [])
          .add(entry);
    }
    final result = <DailyDiscovery>[];
    final used = <String, int>{};
    String? previous;
    while (result.length < groups.values.fold<int>(0, (n, g) => n + g.length)) {
      String? next;
      var mostRemaining = 0;
      for (final group in groups.entries) {
        final remaining = group.value.length - (used[group.key] ?? 0);
        if (group.key != previous && remaining > mostRemaining) {
          next = group.key;
          mostRemaining = remaining;
        }
      }
      // A majority group can remain alone in the spiritual pool.
      next ??= groups.keys
          .firstWhere((key) => (used[key] ?? 0) < groups[key]!.length);
      final index = used[next] ?? 0;
      result.add(groups[next]![index]);
      used[next] = index + 1;
      previous = next;
    }
    return result;
  }

  /// Exactly three distinct daily readings. Actual festival/tithi matches
  /// keep priority; otherwise the spiritual reading explores the wisdom pool.
  static ({
    DailyDiscovery spiritual,
    DailyDiscovery philosophy,
    DailyDiscovery fact,
    bool anniversary
  }) dailySections({
    required DateTime date,
    required int hinduMonth,
    required int rawTithi,
    Set<String> festivals = const {},
    bool adhik = false,
  }) {
    final day = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(2026))
        .inDays;
    final ranked = select(
        date: date,
        hinduMonth: hinduMonth,
        rawTithi: rawTithi,
        festivals: festivals,
        adhik: adhik);
    final relevant = ranked.where((item) =>
        (item.reason == 'festival' || item.reason == 'tithi') &&
        !philosophyIds.contains(item.entry.id) &&
        !factIds.contains(item.entry.id) &&
        item.entry.section != 'philosophy');
    final spiritualPool =
        _interleave(entries.where((entry) => entry.section == 'spiritual'));
    final spiritual = relevant.isNotEmpty
        ? relevant.first.entry
        : spiritualPool[day % spiritualPool.length];
    final philosophyPool = _interleave(entries.where((e) =>
        philosophyIds.contains(e.id) ||
        (e.section == 'philosophy' &&
            e.group != 'buddhist' &&
            e.group != 'jain')));
    final dated = onThisDay(date);
    final facts = dated.isNotEmpty
        ? dated
        : entries.where((e) => factIds.contains(e.id)).toList();
    return (
      spiritual: spiritual,
      philosophy: philosophyPool[day % philosophyPool.length],
      fact: facts[day % facts.length],
      anniversary: dated.isNotEmpty
    );
  }

  static const entries = <DailyDiscovery>[
    ...sanatanReadings,
    ...wisdomReadings,
    DailyDiscovery(
      id: "prahlad-story",
      titleHi: "प्रह्लाद की अटूट भक्ति",
      titleEn: "Prahlad’s steadfast devotion",
      bodyHi:
          "होलिका की कथा में बालक प्रह्लाद संकट के बीच भी विष्णु का नाम नहीं छोड़ते। भक्त इस प्रसंग में अहंकार पर श्रद्धा की विजय देखते हैं। होली की आस्था से जुड़ी यह कथा आज भी सुनाई जाती है।",
      bodyEn:
          "In the sacred Holika story, Prahlad remains devoted to Vishnu despite his father’s opposition and survives the fire. Devotees understand it as faith overcoming fear and arrogance. This is a religious narrative.",
      source: "BAPS",
      url:
          "https://www.baps.org/cultureandheritage/Traditions/AnnualCelebrationsandFestivals/Holi.aspx",
      hinduMonths: [12],
      tithis: [],
      festivalIds: ["holika_dahan", "holi"],
      kind: "story",
    ),
    DailyDiscovery(
      id: "pradosh-reading",
      titleHi: "संध्या में शिव-स्मरण",
      titleEn: "Shiva remembrance at Pradosh",
      bodyHi:
          "त्रयोदशी का प्रदोष भगवान शिव की आराधना से जुड़ा है। इसमें संध्या का समय विशेष महत्त्व रखता है। इसलिए व्रत का दिन देखते समय केवल सुबह की तिथि नहीं, प्रदोषकाल भी देखना चाहिए।",
      bodyEn:
          "Pradosh connects Shiva devotion with Trayodashi in both fortnights. Its evening worship window matters; sunrise tithi alone does not determine the observance date.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/vrats/pradoshdates.html",
      hinduMonths: [],
      tithis: [13, 28],
      festivalIds: [],
      kind: "tradition",
    ),
    DailyDiscovery(
      id: "satya-reading",
      titleHi: "घर-आँगन में सत्यनारायण कथा",
      titleEn: "Purnima and Satyanarayana",
      bodyHi:
          "पूर्णिमा पर अनेक घरों में सत्यनारायण भगवान की कथा और पूजा होती है। पूजा का समय चुनते हुए पूर्णिमा कब तक रहेगी, यह देख लें; जरूरी नहीं कि वह पूरे दिन रहे।",
      bodyEn:
          "Satyanarayana worship is a household tradition associated with Purnima. Its actual lunar interval matters because Purnima need not occupy an entire civil day.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/vrats/satyanarayandates.html",
      hinduMonths: [],
      tithis: [15],
      festivalIds: [],
      kind: "tradition",
    ),
    DailyDiscovery(
      id: "ekadashi-reading",
      titleHi: "एकादशी और पारण",
      titleEn: "Ekadashi and Parana",
      bodyHi:
          "एकादशी विष्णुभक्ति का दिन है। व्रत खोलने को पारण कहते हैं और उसका समय अलग से देखा जाता है। विधि में अपने परिवार की परंपरा और स्थानीय पंचांग का ध्यान रखें।",
      bodyEn:
          "Ekadashi is associated with Vishnu devotion. Parana means concluding the fast and has its own timing, distinct from the start of Ekadashi. Local calendars and family traditions can differ.",
      source: "Drik Panchang",
      url:
          "https://www.drikpanchang.com/faq/ekadashi/about-ekadashi-timings.html",
      hinduMonths: [],
      tithis: [11, 26],
      festivalIds: [],
      kind: "tradition",
    ),
    DailyDiscovery(
      id: "gangaur",
      titleHi: "गौरी के गीत, गणगौर का उत्सव",
      titleEn: "Gauri at Gangaur",
      bodyHi:
          "राजस्थान में गणगौर आते ही गौरी की पूजा और उनसे जुड़े गीतों की रौनक बढ़ जाती है। इस प्रिय परंपरा में सुहागिनें और अविवाहित कन्याएँ, दोनों भाग लेती हैं।",
      bodyEn:
          "Gangaur honours Gauri and brings married and unmarried women together in a cherished regional tradition.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-chaitra.html",
      hinduMonths: [1],
      festivalIds: [],
      tithis: [3],
    ),
    DailyDiscovery(
      id: "ugadi",
      titleHi: "नए वर्ष का स्वागत",
      titleEn: "Many names for a new year",
      bodyHi:
          "चैत्र शुक्ल प्रतिपदा को कहीं उगादी कहते हैं, कहीं गुड़ी पड़वा। नाम और रीति अलग हैं, पर नई शुरुआत का उल्लास दोनों में है।",
      bodyEn:
          "Ugadi and Gudi Padwa mark a new year at Chaitra’s bright-fortnight beginning, expressing renewal through regional customs.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-chaitra.html",
      hinduMonths: [1],
      festivalIds: [],
      tithis: [1],
    ),
    DailyDiscovery(
      id: "rama-reading",
      titleHi: "रामनवमी का मंगल",
      titleEn: "Remembering Rama Navami",
      bodyHi:
          "रामनवमी प्रभु श्रीराम के जन्मोत्सव का दिन है। भक्त अयोध्या में उनके जन्म का स्मरण करते हैं और पूजा, पाठ व भजन से उत्सव मनाते हैं।",
      bodyEn:
          "Rama Navami recalls the sacred account of Rama’s birth in Ayodhya and is a major occasion for devotion.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-chaitra.html",
      hinduMonths: [1],
      festivalIds: ["rama_navami"],
      tithis: [],
    ),
    DailyDiscovery(
      id: "akshaya",
      titleHi: "अक्षय तृतीया का पुण्यभाव",
      titleEn: "Giving on Akshaya Tritiya",
      bodyHi:
          "अक्षय तृतीया विष्णु-आराधना और दान की परंपरा से जुड़ी है। मान्यता है कि इस दिन किए शुभ कर्मों का पुण्य अक्षय रहता है।",
      bodyEn:
          "Akshaya Tritiya joins Vishnu worship with generosity and the traditional belief in enduring spiritual merit.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-vaishakha.html",
      hinduMonths: [2],
      festivalIds: [],
      tithis: [3],
    ),
    DailyDiscovery(
      id: "jahnavi",
      titleHi: "गंगा को जाह्नवी क्यों कहते हैं?",
      titleEn: "Why Ganga is called Jahnavi",
      bodyHi:
          "गंगा सप्तमी से जुड़ी कथा में ऋषि जह्नु गंगा को फिर प्रवाहित करते हैं। इसी प्रसंग के कारण माँ गंगा का एक नाम जाह्नवी भी पड़ा।",
      bodyEn:
          "A sacred Ganga Saptami narrative tells of sage Jahnu releasing the river again, explaining the name Jahnavi.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-vaishakha.html",
      hinduMonths: [2],
      festivalIds: [],
      tithis: [7],
    ),
    DailyDiscovery(
      id: "parashurama",
      titleHi: "परशुराम जयंती का स्मरण",
      titleEn: "Remembering Parashurama",
      bodyHi:
          "परशुराम जयंती पर भगवान विष्णु के परशुराम अवतार की पूजा की जाती है। यह विष्णु के अवतारों के स्मरण से जुड़ा उत्सव है।",
      bodyEn:
          "Parashurama Jayanti honours Parashurama within the Vaishnava tradition of Vishnu’s incarnations.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-vaishakha.html",
      hinduMonths: [2],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "narada",
      titleHi: "नारद की वीणा, नारायण का नाम",
      titleEn: "Narada and remembrance",
      bodyHi:
          "भक्त नारद का स्मरण हो तो नारायण का नाम साथ आता है। धार्मिक कथाओं में उनकी निरंतर भक्ति हमें कामकाज के बीच भी प्रभु-स्मरण की याद दिलाती है।",
      bodyEn:
          "Sacred narratives portray Narada as a devotee of Narayana, exemplifying continual remembrance of the divine.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-jyeshtha.html",
      hinduMonths: [3],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "vat",
      titleHi: "वट सावित्री की परंपरा",
      titleEn: "The Vat Savitri tradition",
      bodyHi:
          "वट सावित्री व्रत में दांपत्य के मंगल की कामना की जाती है। कुछ क्षेत्रों में यह अमावस्या को होता है, कुछ में पूर्णिमा को। अपने यहाँ की परंपरा के अनुसार दिन देखा जाता है।",
      bodyEn:
          "Vat Savitri expresses prayers for marital well-being; regional traditions differ between full-moon and new-moon observances.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-jyeshtha.html",
      hinduMonths: [3],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "shani",
      titleHi: "शनि और कर्म का स्मरण",
      titleEn: "Shani and responsibility",
      bodyHi:
          "शनि जयंती शनि देव की आराधना का अवसर है। सनातन मान्यता में वे कर्मफल से जुड़े हैं; उनका स्मरण अपने कर्मों की ओर भी ध्यान दिलाता है।",
      bodyEn:
          "Shani Jayanti honours Shani among the Navagrahas; tradition associates Shani with the consequences of actions.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-jyeshtha.html",
      hinduMonths: [3],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "ratha",
      titleHi: "भक्तों के बीच जगन्नाथ",
      titleEn: "Jagannath’s chariot journey",
      bodyHi:
          "रथयात्रा में भगवान जगन्नाथ गुंडिचा मंदिर की ओर जाते हैं। मंदिर से बाहर निकली यह यात्रा भक्तों के लिए अपने प्रभु के दर्शन का बड़ा उत्सव बन जाती है।",
      bodyEn:
          "Jagannath’s Ratha Yatra travels to Gundicha temple, bringing a living temple tradition into public space.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-ashadha.html",
      hinduMonths: [4],
      festivalIds: [],
      tithis: [2],
    ),
    DailyDiscovery(
      id: "sleep",
      titleHi: "देवशयनी का भाव",
      titleEn: "The meaning of Devshayani",
      bodyHi:
          "देवशयनी एकादशी से भगवान विष्णु के योगनिद्रा में जाने की मान्यता है। भक्त इस पावन प्रसंग का स्मरण करते हैं।",
      bodyEn:
          "Devshayani Ekadashi traditionally marks the beginning of Vishnu’s sacred repose, a devotional belief rather than a dated historical event.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-ashadha.html",
      hinduMonths: [4],
      festivalIds: ["devshayani_ekadashi"],
      tithis: [],
    ),
    DailyDiscovery(
      id: "vyasa",
      titleHi: "गुरु के प्रति कृतज्ञता",
      titleEn: "Honouring Vyasa",
      bodyHi:
          "आषाढ़ की गुरु पूर्णिमा पर गुरुजन और महर्षि व्यास का स्मरण किया जाता है। जिन्होंने हमें ज्ञान दिया, उनके प्रति आदर और आभार इस उत्सव का मूल भाव है।",
      bodyEn:
          "Ashadha brings Guru Purnima and Vyasa Puja, occasions for gratitude to those who transmit spiritual knowledge.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-ashadha.html",
      hinduMonths: [4],
      festivalIds: [],
      tithis: [15],
    ),
    DailyDiscovery(
      id: "sawan",
      titleHi: "सावन और शिवभक्ति",
      titleEn: "Mondays of Shravana",
      bodyHi:
          "श्रावण के सोमवार शिव-आराधना के लिए विशेष माने जाते हैं। अमांत और पूर्णिमांत मास-गणना अलग होने से सावन की अवधि क्षेत्र के अनुसार बदल सकती है।",
      bodyEn:
          "Shravana Mondays are associated with Shiva devotion; regional month systems can shift the observance period.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-shravana.html",
      hinduMonths: [5],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "mangala",
      titleHi: "मंगला गौरी का मंगलभाव",
      titleEn: "Mangala Gauri",
      bodyHi:
          "श्रावण के मंगलवार को मंगला गौरी व्रत की परंपरा है। अनेक सुहागिनें माँ गौरी से अपने गृहस्थ जीवन के मंगल की प्रार्थना करती हैं।",
      bodyEn:
          "Mangala Gauri observances on Shravana Tuesdays include prayers for well-being in married life.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-shravana.html",
      hinduMonths: [5],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "rakhi",
      titleHi: "राखी के धागे का स्नेह",
      titleEn: "Rakhi and family affection",
      bodyHi:
          "श्रावण में रक्षाबंधन आता है। कलाई पर बँधी राखी भाई-बहन के स्नेह और एक-दूसरे की देखभाल का प्यारा स्मरण है।",
      bodyEn:
          "Raksha Bandhan in Shravana celebrates sibling affection and mutual care.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-shravana.html",
      hinduMonths: [5],
      festivalIds: ["raksha_bandhan"],
      tithis: [],
    ),
    DailyDiscovery(
      id: "krishna-birth",
      titleHi: "कान्हा के जन्म का उल्लास",
      titleEn: "Celebrating Krishna’s birth",
      bodyHi:
          "जन्माष्टमी पर भक्त भगवान श्रीकृष्ण के जन्म का उत्सव मनाते हैं। भाद्रपद की इस परंपरा में कान्हा के प्रति प्रेम और भक्ति की विशेष रौनक रहती है।",
      bodyEn:
          "Janmashtami recalls Krishna’s birth in sacred tradition and gives Krishna devotion a special place in Bhadrapada.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-bhadrapada.html",
      hinduMonths: [6],
      festivalIds: ["janmashtami"],
      tithis: [],
    ),
    DailyDiscovery(
      id: "aja",
      titleHi: "कठिन समय में धर्म का साथ",
      titleEn: "Harishchandra and Ekadashi",
      bodyHi:
          "अजा एकादशी की कथा में राजा हरिश्चंद्र और गौतम ऋषि का प्रसंग आता है। भक्त इसे कठिनाई में भी धर्म और आशा का साथ बनाए रखने की कथा मानते हैं।",
      bodyEn:
          "The Aja Ekadashi narrative connects Harishchandra with sage Gautama; devotees read it as a story of faith amid hardship.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-bhadrapada.html",
      hinduMonths: [6],
      festivalIds: [],
      tithis: [26],
    ),
    DailyDiscovery(
      id: "bhadra-festivals",
      titleHi: "भाद्रपद में भक्ति के अनेक रंग",
      titleEn: "Bhadrapada’s varied devotion",
      bodyHi:
          "गणेश चतुर्थी, राधाष्टमी और अनंत चतुर्दशी—भाद्रपद में अनेक उत्सव आते हैं। एक ही मास में उपासना के कई सुंदर रूप दिखाई देते हैं।",
      bodyEn:
          "Ganesh Chaturthi, Radha Ashtami and Anant Chaturdashi illustrate the month’s variety of devotional traditions.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-bhadrapada.html",
      hinduMonths: [6],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "ancestors",
      titleHi: "जिनसे मिला जीवन, उनका स्मरण",
      titleEn: "Gratitude during Pitru Paksha",
      bodyHi:
          "पितृपक्ष में पूर्वजों का स्मरण और तर्पण किया जाता है। परिवार उन पीढ़ियों के प्रति कृतज्ञता व्यक्त करता है, जिनसे उसे जीवन और अपनी विरासत मिली।",
      bodyEn:
          "Pitru Paksha includes remembrance and offerings for ancestors, expressing gratitude for family heritage.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-ashwin.html",
      hinduMonths: [7],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "mahalaya",
      titleHi: "सर्वपितृ अमावस्या",
      titleEn: "Sarva Pitru Amavasya",
      bodyHi:
          "पितृपक्ष के अंतिम दिन सर्वपितृ अमावस्या आती है। पूर्वजों के सामूहिक स्मरण के लिए इसे विशेष अवसर माना जाता है।",
      bodyEn:
          "Sarva Pitru Amavasya closes Pitru Paksha and serves as a special occasion for remembrance of ancestors.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-ashwin.html",
      hinduMonths: [7],
      festivalIds: [],
      tithis: [30],
    ),
    DailyDiscovery(
      id: "ashwin-devotion",
      titleHi: "आश्विन में माँ की आराधना",
      titleEn: "Devi worship in Ashwin",
      bodyHi:
          "शारदीय नवरात्रि, दुर्गाष्टमी और महानवमी आश्विन मास में आती हैं। देश के अलग-अलग क्षेत्रों में माँ की पूजा अपनी-अपनी रीति से होती है।",
      bodyEn:
          "Shardiya Navratri, Durga Ashtami and Maha Navami bring varied regional expressions of Devi worship to Ashwin.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-ashwin.html",
      hinduMonths: [7],
      festivalIds: ["shardiya_navratri", "durga_ashtami"],
      tithis: [],
    ),
    DailyDiscovery(
      id: "karwa",
      titleHi: "करवा चौथ की मंगलकामना",
      titleEn: "The meaning of Karwa Chauth",
      bodyHi:
          "करवा चौथ की परंपरा में दांपत्य के मंगल की प्रार्थना और चंद्रदर्शन का स्थान है। पूजा की रीति परिवार और क्षेत्र के अनुसार अलग हो सकती है।",
      bodyEn:
          "Karwa Chauth traditions combine prayers for marital well-being with moon viewing; family customs vary.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-kartik.html",
      hinduMonths: [8],
      festivalIds: ["karwa_chauth"],
      tithis: [],
    ),
    DailyDiscovery(
      id: "ahoi",
      titleHi: "अहोई माता से मंगल की प्रार्थना",
      titleEn: "Ahoi Ashtami",
      bodyHi:
          "उत्तर भारत में अहोई अष्टमी संतान के मंगल की कामना से जुड़ी है। कहीं तारे देखकर, तो कहीं चंद्रदर्शन के बाद व्रत पूरा किया जाता है।",
      bodyEn:
          "Ahoi Ashtami in northern India centres on children’s well-being, with local customs involving stars or moonrise.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-kartik.html",
      hinduMonths: [8],
      festivalIds: [],
      tithis: [23],
    ),
    DailyDiscovery(
      id: "kartik-lights",
      titleHi: "कार्तिक का उजास",
      titleEn: "Kartik’s celebrations",
      bodyHi:
          "दीपावली, गोवर्धन पूजा, छठ और तुलसी विवाह—कार्तिक में घर-आँगन कई उत्सवों से जगमगाते हैं। दीप और प्रकृति के साथ गृहस्थ भक्ति का सुंदर मेल दिखाई देता है।",
      bodyEn:
          "Diwali, Govardhan Puja, Chhath and Tulsi Vivah express Kartik’s connections with lamps, nature and household devotion.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-kartik.html",
      hinduMonths: [8],
      festivalIds: [
        "diwali",
        "govardhan_puja",
        "tulsi_vivah",
        "devutthana_ekadashi",
      ],
      tithis: [],
    ),
    DailyDiscovery(
      id: "gita-birth",
      titleHi: "गीता जयंती का संदेश",
      titleEn: "Gita Jayanti",
      bodyHi:
          "मार्गशीर्ष शुक्ल एकादशी पर गीता जयंती मनाई जाती है। भक्त इस दिन कुरुक्षेत्र में श्रीकृष्ण द्वारा अर्जुन को दिए गए गीता-उपदेश का स्मरण करते हैं।",
      bodyEn:
          "Gita Jayanti on Margashirsha’s bright Ekadashi commemorates Krishna’s teaching to Arjuna in sacred tradition.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-margashirsha.html",
      hinduMonths: [9],
      festivalIds: [],
      tithis: [11],
    ),
    DailyDiscovery(
      id: "vivah",
      titleHi: "सिया-राम के विवाह का उत्सव",
      titleEn: "Remembering Rama and Sita’s marriage",
      bodyHi:
          "विवाह पंचमी पर माता सीता और प्रभु श्रीराम के विवाह का स्मरण होता है। अनेक स्थानों पर इसे विवाहोत्सव की तरह पूजा और आनंद के साथ मनाया जाता है।",
      bodyEn:
          "Vivah Panchami recalls the sacred marriage of Rama and Sita through ceremonial celebrations.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-margashirsha.html",
      hinduMonths: [9],
      festivalIds: [],
      tithis: [5],
    ),
    DailyDiscovery(
      id: "utpanna",
      titleHi: "उत्पन्ना एकादशी का महत्त्व",
      titleEn: "Utpanna Ekadashi",
      bodyHi:
          "मार्गशीर्ष कृष्ण एकादशी को उत्पन्ना एकादशी कहते हैं। कुछ परंपराओं में एकादशी व्रत शुरू करने के लिए इस दिन को विशेष माना जाता है।",
      bodyEn:
          "Utpanna Ekadashi falls in the dark fortnight of Margashirsha and is traditionally associated with beginning Ekadashi observance.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-margashirsha.html",
      hinduMonths: [9],
      festivalIds: [],
      tithis: [26],
    ),
    DailyDiscovery(
      id: "shakambhari",
      titleHi: "माँ शाकंभरी और अन्न का आदर",
      titleEn: "Shakambhari and nourishment",
      bodyHi:
          "माँ शाकंभरी की उपासना फल, सब्जियों और हरियाली से जुड़ी है। यह परंपरा जीवन को पोषण देने वाले अन्न के प्रति कृतज्ञता जगाती है।",
      bodyEn:
          "Shakambhari is traditionally associated with fruits, vegetables and greenery, linking worship with gratitude for nourishment.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-paush.html",
      hinduMonths: [10],
      festivalIds: [],
      tithis: [],
    ),
    DailyDiscovery(
      id: "banada",
      titleHi: "शाकंभरी नवरात्रि की शुरुआत",
      titleEn: "Banada Ashtami",
      bodyHi:
          "पौष शुक्ल अष्टमी से शाकंभरी नवरात्रि शुरू होती है और पूर्णिमा तक चलती है। इसकी अवधि दूसरी नौ-दिवसीय नवरात्रियों जैसी होना जरूरी नहीं।",
      bodyEn:
          "Shakambhari Navratri runs from Pausha’s bright Ashtami to Purnima, a different span from the familiar nine-night observance.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-paush.html",
      hinduMonths: [10],
      festivalIds: [],
      tithis: [8],
    ),
    DailyDiscovery(
      id: "putrada",
      titleHi: "पुत्रदा नाम की दो एकादशी",
      titleEn: "Pausha’s Ekadashi",
      bodyHi:
          "पौष और श्रावण, दोनों मास की शुक्ल एकादशी को पुत्रदा कहा जाता है। अलग क्षेत्रों में इनका प्रचलन अलग-अलग मिलता है।",
      bodyEn:
          "The bright Ekadashis of Pausha and Shravana share the name Putrada, with regional differences in prominence.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-paush.html",
      hinduMonths: [10],
      festivalIds: [],
      tithis: [11],
    ),
    DailyDiscovery(
      id: "saraswati",
      titleHi: "विद्या की देवी को प्रणाम",
      titleEn: "Saraswati and learning",
      bodyHi:
          "वसंत पंचमी पर माँ सरस्वती की पूजा होती है। ज्ञान, संगीत और कला के प्रति श्रद्धा इस पर्व का भाव है; पीले फूल चढ़ाने की परंपरा भी है।",
      bodyEn:
          "Vasant Panchami honours Saraswati through learning, music and art; yellow flowers are among traditional offerings.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-magha.html",
      hinduMonths: [11],
      festivalIds: [],
      tithis: [5],
    ),
    DailyDiscovery(
      id: "ratha-sun",
      titleHi: "रथ सप्तमी का सूर्य-वंदन",
      titleEn: "Ratha Saptami and Surya",
      bodyHi:
          "रथ सप्तमी सूर्य देव की आराधना का पर्व है। परंपरा में इसे सूर्य जयंती भी कहा जाता है।",
      bodyEn:
          "Ratha Saptami is an occasion for Surya worship and is also known traditionally as Surya Jayanti.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-magha.html",
      hinduMonths: [11],
      festivalIds: [],
      tithis: [7],
    ),
    DailyDiscovery(
      id: "sesame",
      titleHi: "षट्तिला में तिल का महत्त्व",
      titleEn: "Sesame at Shattila",
      bodyHi:
          "षट्तिला एकादशी के नाम में ही तिल के छह प्रकार के उपयोग का संकेत है। इस व्रत की परंपरा में तिल से जुड़े अनेक धार्मिक प्रयोग बताए गए हैं।",
      bodyEn:
          "Shattila Ekadashi refers to six ritual uses of sesame, reflected in the observance’s name.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-magha.html",
      hinduMonths: [11],
      festivalIds: [],
      tithis: [26],
    ),
    DailyDiscovery(
      id: "shiva-night",
      titleHi: "शिवरात्रि का जागरण",
      titleEn: "A night of Shiva worship",
      bodyHi:
          "महाशिवरात्रि की रात चार प्रहरों में शिव-पूजा की परंपरा है। भक्त जागरण, नाम-स्मरण और आराधना में यह रात्रि बिताते हैं।",
      bodyEn:
          "Maha Shivaratri traditionally includes Shiva worship across the night’s four watches, with vigil and remembrance.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-phalguna.html",
      hinduMonths: [12],
      festivalIds: ["maha_shivaratri"],
      tithis: [],
    ),
    DailyDiscovery(
      id: "phulera",
      titleHi: "ब्रज में फूलों का उल्लास",
      titleEn: "Phulera Dooj in Braj",
      bodyHi:
          "फाल्गुन शुक्ल द्वितीया को ब्रज में फुलेरा दूज मनाई जाती है। वसंत पंचमी और होली के बीच आने वाला यह पर्व वहाँ की प्रिय परंपरा है।",
      bodyEn:
          "Phulera Dooj, on Phalguna’s bright Dwitiya, belongs to Braj’s celebrations between Vasant Panchami and Holi.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-phalguna.html",
      hinduMonths: [12],
      festivalIds: [],
      tithis: [2],
    ),
    DailyDiscovery(
      id: "amalaki",
      titleHi: "आँवले के संग विष्णु-पूजा",
      titleEn: "Amalaki and Vishnu devotion",
      bodyHi:
          "आमलकी एकादशी पर भगवान विष्णु के साथ आँवले के वृक्ष की पूजा भी होती है। यह एकादशी शिवरात्रि और होली के बीच आती है।",
      bodyEn:
          "Amalaki Ekadashi joins Vishnu worship with reverence for the amla tree, between Shivaratri and Holi.",
      source: "Drik Panchang",
      url: "https://www.drikpanchang.com/festivals/festivals-phalguna.html",
      hinduMonths: [12],
      festivalIds: [],
      tithis: [11],
    ),
    DailyDiscovery(
      id: "gita-compassion",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 12.13–14",
      referenceHi: "श्रीमद्भगवद्गीता 12.13–14",
      group: "gita",
      titleHi: "भक्त के मन में करुणा",
      titleEn: "Devotion and compassion",
      bodyHi:
          "श्रीकृष्ण प्रिय भक्त के गुण बताते हैं—किसी से द्वेष न हो, सबके प्रति मैत्री और दया हो, मन में क्षमा हो। भक्ति का रंग हमारे व्यवहार में भी दिखाई देना चाहिए।",
      bodyEn:
          "Gita 12.13–14 connects devotion with compassion, friendship and forgiveness.",
      source: "Bhagavad Gita 12 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/12/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-practice",
      promptHi: "मन भटके तो फिर प्रेम से प्रभु का स्मरण करें।",
      promptEn: "Return gently to remembrance when your mind wanders.",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 12.9",
      referenceHi: "श्रीमद्भगवद्गीता 12.9",
      group: "gita",
      section: "spiritual",
      titleHi: "मन भटके तो फिर अभ्यास करें",
      titleEn: "Practising devotion",
      bodyHi:
          "मन एक बार में प्रभु पर न टिके तो निराश न हों। श्रीकृष्ण अभ्यास का मार्ग बताते हैं। बार-बार मन को लौटाना भी भक्ति की राह पर बढ़ना है।",
      bodyEn:
          "Gita 12.9 offers steady practice when concentration is difficult.",
      source: "Bhagavad Gita 12 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/12/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-offering-work",
      promptHi: "आज कोई काम प्रभु को अर्पित करने के भाव से करें।",
      promptEn: "Offer one duty to God today.",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 12.10",
      referenceHi: "श्रीमद्भगवद्गीता 12.10",
      group: "gita",
      section: "spiritual",
      titleHi: "अपना कर्म प्रभु को अर्पित करें",
      titleEn: "Offering one’s work",
      bodyHi:
          "मन को स्थिर करना कठिन लगे तो अपने कर्म भगवान को अर्पित करने का भाव रखें। श्रीकृष्ण गीता में कर्म के माध्यम से भी भक्ति का मार्ग बताते हैं।",
      bodyEn: "Gita 12.10 presents work as an offering to the divine.",
      source: "Bhagavad Gita 12 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/12/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-peace",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 12.12",
      referenceHi: "श्रीमद्भगवद्गीता 12.12",
      group: "gita",
      titleHi: "फल की चिंता से थोड़ी मुक्ति",
      titleEn: "Letting go and peace",
      bodyHi:
          "गीता कर्मफल के त्याग के साथ शांति का संबंध बताती है। अपना कर्तव्य निभाते हुए फल पर मन की पकड़ ढीली करें; हर परिणाम को अपनी इच्छा में बाँधना हमारे हाथ में नहीं।",
      bodyEn:
          "Gita 12.12 links inner peace with releasing attachment to results.",
      source: "Bhagavad Gita 12 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/12/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-speech",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 17.15",
      referenceHi: "श्रीमद्भगवद्गीता 17.15",
      group: "gita",
      titleHi: "वाणी भी तप बन सकती है",
      titleEn: "Discipline of speech",
      bodyHi:
          "जो बात सत्य हो, हितकारी हो और किसी को व्यर्थ उद्विग्न न करे—गीता ऐसी वाणी को तप कहती है। बोलना रोज का काम है, उसे सँवारना रोज की साधना हो सकती है।",
      bodyEn:
          "Gita 17.15 values truthful, beneficial speech that does not cause distress.",
      source: "Bhagavad Gita 17 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/17/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-charity",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 17.20",
      referenceHi: "श्रीमद्भगवद्गीता 17.20",
      group: "gita",
      titleHi: "दान में बदले की आशा कैसी?",
      titleEn: "Giving without repayment",
      bodyHi:
          "गीता उस दान को सात्त्विक कहती है जो कर्तव्य समझकर, उचित समय और स्थान पर, योग्य व्यक्ति को दिया जाए। उसमें लौटकर कुछ पाने की अपेक्षा नहीं होती।",
      bodyEn:
          "Gita 17.20 values appropriate giving without expecting repayment.",
      source: "Bhagavad Gita 17 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/17/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-mind",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 17.16",
      referenceHi: "श्रीमद्भगवद्गीता 17.16",
      group: "gita",
      titleHi: "मन को भी निर्मल रखें",
      titleEn: "Discipline of mind",
      bodyHi:
          "मन की प्रसन्नता, सौम्यता, मौन, संयम और भावों की शुद्धि—गीता इन्हें मन का तप कहती है। साधना केवल बाहर के आचरण तक सीमित नहीं है।",
      bodyEn:
          "Gita 17.16 describes serenity, gentleness and self-restraint as mental discipline.",
      source: "Bhagavad Gita 17 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/17/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-respect",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 17.14",
      referenceHi: "श्रीमद्भगवद्गीता 17.14",
      group: "gita",
      titleHi: "सरलता और आदर का आचरण",
      titleEn: "Respect and simplicity",
      bodyHi:
          "देव, गुरु और ज्ञानीजन का आदर, शुद्धता, सरलता तथा अहिंसा—गीता इन्हें शारीरिक तप में स्थान देती है। श्रद्धा अपने आचरण में उतरकर सार्थक होती है।",
      bodyEn:
          "Gita 17.14 honours respect, cleanliness, simplicity and nonviolence.",
      source: "Bhagavad Gita 17 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/17/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-balance",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 6.16–17",
      referenceHi: "श्रीमद्भगवद्गीता 6.16–17",
      group: "gita",
      titleHi: "साधना में संतुलन रखें",
      titleEn: "Balance in practice",
      bodyHi:
          "श्रीकृष्ण भोजन, विश्राम और काम में संतुलन की बात कहते हैं। बहुत अधिक या बहुत कम सोना-खाना साधना में बाधा बन सकता है। संयमित दिनचर्या भी योग का सहारा है।",
      bodyEn: "Gita 6.16–17 encourages balance in food, sleep and activity.",
      source: "Bhagavad Gita 6 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/6/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-return",
      promptHi: "आज कुछ क्षण ध्यान करें; मन भटके तो उसे वापस लाएँ।",
      promptEn: "Practise bringing attention back during a quiet moment.",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 6.26",
      referenceHi: "श्रीमद्भगवद्गीता 6.26",
      group: "gita",
      section: "spiritual",
      titleHi: "भटके मन को प्रेम से लौटाएँ",
      titleEn: "Returning the wandering mind",
      bodyHi:
          "मन बार-बार भटकता है। श्रीकृष्ण उसे फिर सँभालकर आत्मा में स्थिर करने का अभ्यास बताते हैं। एकाग्रता टूट जाए तो साधना छोड़ने के बजाय फिर लौटें।",
      bodyEn:
          "Gita 6.26 teaches repeatedly returning attention when the mind wanders.",
      source: "Bhagavad Gita 6 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/6/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-lamp",
      promptHi: "शांत जगह बैठकर कुछ समय ध्यान करें।",
      promptEn: "Sit in a quiet place for a short meditation.",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 6.19",
      referenceHi: "श्रीमद्भगवद्गीता 6.19",
      group: "gita",
      section: "spiritual",
      titleHi: "हवा से बची दीपशिखा",
      titleEn: "The steady lamp",
      bodyHi:
          "हवा न हो तो दीपक की लौ स्थिर रहती है। गीता इसी सुंदर उपमा से योगी के संयमित, ध्यान में स्थिर मन को समझाती है।",
      bodyEn:
          "Gita 6.19 compares steady meditation to a lamp sheltered from wind.",
      source: "Bhagavad Gita 6 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/6/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "gita-friend",
      teacherHi: "श्रीमद्भगवद्गीता · श्रीकृष्ण",
      teacherEn: "Bhagavad Gita · Shri Krishna",
      reference: "Bhagavad Gita 6.5–6",
      referenceHi: "श्रीमद्भगवद्गीता 6.5–6",
      group: "gita",
      titleHi: "मन अपना साथी भी है",
      titleEn: "Making the mind a friend",
      bodyHi:
          "श्रीकृष्ण कहते हैं कि मन हमारे उत्थान में साथी बन सकता है और असंयम में बाधा भी। उसे साधना अपने ही जीवन को सही दिशा देने का प्रयत्न है।",
      bodyEn:
          "Gita 6.5–6 connects training the mind with one’s own spiritual growth.",
      source: "Bhagavad Gita 6 · Swami Mukundananda",
      url: "https://www.holy-bhagavad-gita.org/chapter/6/",
      kind: "teaching",
    ),
    DailyDiscovery(
      id: "nav-nine",
      hinduMonths: [1, 7],
      titleHi: "माँ के नौ रूप, नौ रातें",
      titleEn: "Nine nights of Navratri",
      bodyHi:
          "नवरात्रि में माँ दुर्गा के नौ स्वरूपों की आराधना होती है। पूजा, पाठ और भजन के बीच भक्त शक्ति का स्मरण करते हैं।",
      bodyEn:
          "Navratri honours nine forms of Durga through worship, devotional reading and singing.",
      url: "https://www.drikpanchang.com/navratri/info/navratri.html",
      source: "Drik Panchang",
    ),
    DailyDiscovery(
      id: "nav-kalash",
      hinduMonths: [1, 7],
      titleHi: "कलश के साथ शुभारंभ",
      titleEn: "Beginning with Ghatasthapana",
      bodyHi:
          "नवरात्रि के पहले दिन घटस्थापना की परंपरा है। घर या पूजा-स्थल में कलश की स्थापना के साथ देवी-आराधना का आरंभ होता है।",
      bodyEn:
          "Installing a ceremonial pot marks the beginning of Navratri worship in homes and communities.",
      url: "https://www.drikpanchang.com/navratri/info/navratri.html",
      source: "Drik Panchang",
    ),
    DailyDiscovery(
      id: "nav-golu",
      hinduMonths: [1, 7],
      titleHi: "नवरात्रि का गोलु",
      titleEn: "Golu in southern India",
      bodyHi:
          "दक्षिण भारत में नवरात्रि पर सीढ़ीनुमा मंच पर गुड़ियाँ सजाई जाती हैं। गोलु और बोम्मला कोलुवु जैसे नामों से जानी जाने वाली यह परंपरा उत्सव का एक सुंदर रूप है।",
      bodyEn:
          "Navratri doll displays arranged on stepped platforms are known by names including Golu and Bommala Koluvu.",
      url: "https://www.drikpanchang.com/navratri/info/navratri.html",
      source: "Drik Panchang",
    ),
    DailyDiscovery(
      id: "nav-learning",
      hinduMonths: [1, 7],
      titleHi: "जब विद्या की होती है पूजा",
      titleEn: "Honouring learning",
      bodyHi:
          "दक्षिण भारत की कई परंपराओं में नवरात्रि के अंतिम तीन दिन माँ सरस्वती को समर्पित हैं। विद्या को देवी का रूप मानकर आदर दिया जाता है।",
      bodyEn:
          "In several southern Navratri traditions, the final three days honour Saraswati and the sacred value of learning.",
      url: "https://www.drikpanchang.com/navratri/info/navratri.html",
      source: "Drik Panchang",
    ),
    DailyDiscovery(
      id: "nav-regional",
      hinduMonths: [1, 7],
      titleHi: "भक्ति एक, उत्सव के रंग अनेक",
      titleEn: "One festival, many traditions",
      bodyHi:
          "गुजरात का गरबा, बंगाल की दुर्गा पूजा और दक्षिण भारत का गोलु—नवरात्रि देश में अनेक रूपों में मनाई जाती है। हर क्षेत्र अपनी रीति से माँ की आराधना करता है।",
      bodyEn:
          "Garba, Bengali Durga Puja and southern Golu express the regional diversity of Navratri.",
      url: "https://www.drikpanchang.com/navratri/info/navratri.html",
      source: "Drik Panchang",
    ),
    DailyDiscovery(
      id: "nav-chandi",
      hinduMonths: [7],
      titleHi: "चंडी पाठ की परंपरा",
      titleEn: "The tradition of Chandi reading",
      bodyHi:
          "बेलूर मठ में नवरात्रि के समय चंडी पाठ होता है। माँ की आराधना में पूजा के साथ पावन पाठ सुनने-पढ़ने की भी अपनी जगह है।",
      bodyEn:
          "At Belur Math, Chandi recitation accompanies worship during Navratri.",
      url: "https://belurmath.org/durga-puja-at-belur-math/",
      source: "Belur Math",
    ),
    DailyDiscovery(
      id: "nav-sandhi",
      hinduMonths: [7],
      titleHi: "अष्टमी और नवमी की संधि",
      titleEn: "The meaning of Sandhi Puja",
      bodyHi:
          "दुर्गा पूजा में अष्टमी के अंतिम चौबीस मिनट और नवमी के पहले चौबीस मिनट संधि-पूजा का समय माने जाते हैं। दो तिथियों के इस मिलन पर विशेष पूजन होता है।",
      bodyEn:
          "Sandhi Puja honours the junction formed by the final 24 minutes of Ashtami and first 24 minutes of Navami.",
      url: "https://belurmath.org/durga-puja-at-belur-math/",
      source: "Belur Math",
    ),
    DailyDiscovery(
      id: "nav-belur",
      hinduMonths: [7],
      titleHi: "बेलूर मठ की पूजा-परंपरा",
      titleEn: "Compassion at Belur Math",
      bodyHi:
          "माँ शारदा के निर्देश के अनुसार बेलूर मठ की दुर्गा पूजा में पशुबलि नहीं दी जाती। यहाँ प्रतीकात्मक अर्पण की परंपरा निभाई जाती है।",
      bodyEn:
          "Following Sarada Devi’s instruction, Belur Math’s Durga Puja uses symbolic offerings instead of animal sacrifice.",
      url: "https://belurmath.org/durga-puja-at-belur-math/",
      source: "Belur Math",
    ),
    DailyDiscovery(
      id: "prayer",
      titleHi: "प्रार्थना मन से निकले",
      titleEn: "Prayer from a simple heart",
      bodyHi:
          "श्रीरामकृष्ण सच्चे और सरल हृदय से प्रार्थना करने की सीख देते हैं। प्रभु के सामने मन की सच्चाई रखें; भक्ति में बनावट की आवश्यकता नहीं।",
      bodyEn:
          "Sri Ramakrishna’s teaching values sincere prayer from a simple heart, placing honesty at the centre of devotion.",
      url: "https://media.belurmath.org/inspiration-sri-ramakrishna-2-1560",
      source: "Belur Math",
    ),
    DailyDiscovery(
      id: "yoga",
      titleHi: "आसन से आगे भी है योग",
      titleEn: "Yoga as living heritage",
      bodyHi:
          "योग केवल आसनों तक सीमित नहीं; ध्यान और श्वास के अभ्यास भी इसकी परंपरा में हैं। वर्ष 2016 में यूनेस्को ने योग को मानवता की अमूर्त सांस्कृतिक विरासत की सूची में स्थान दिया।",
      bodyEn:
          "Yoga brings together postures, meditation and breathing practices. It joined UNESCO’s list of humanity’s intangible cultural heritage in 2016.",
      url: "https://ich.unesco.org/en/RL/yoga-01163",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "vedic",
      titleHi: "सुनकर सहेजी गई वेद-वाणी",
      titleEn: "The oral tradition of Vedic chanting",
      bodyHi:
          "वेदपाठ पीढ़ी-दर-पीढ़ी सुनकर और बोलकर सहेजा गया है। इस मौखिक परंपरा को वर्ष 2008 में यूनेस्को की प्रतिनिधि सूची में स्थान मिला।",
      bodyEn:
          "Vedic chanting has been preserved through oral transmission across generations. The tradition entered UNESCO’s Representative List in 2008.",
      url: "https://ich.unesco.org/en/RL/tradition-of-vedic-chanting-00062",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "kumbh",
      titleHi: "चार नगरों से जुड़ा कुंभ",
      titleEn: "Four cities of the Kumbh",
      bodyHi:
          "प्रयागराज, हरिद्वार, उज्जैन और नासिक—कुंभ की परंपरा इन चार नगरों से जुड़ी है। इसमें तीर्थयात्रा के साथ धार्मिक ज्ञान और सामुदायिक जीवन का भी संगम होता है।",
      bodyEn:
          "The Kumbh tradition is associated with Prayagraj, Haridwar, Ujjain and Nashik, bringing together pilgrimage, religious learning and community customs.",
      url: "https://ich.unesco.org/en/RL/kumbh-mela-01258",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "garba",
      hinduMonths: [1, 7],
      titleHi: "गरबे में माँ की आराधना",
      titleEn: "Garba and devotion to Shakti",
      bodyHi:
          "गुजरात में नवरात्रि का गरबा शक्ति-उपासना से जुड़ा है। दीप वाले मिट्टी के पात्र या माँ अंबा की छवि के चारों ओर नृत्य करते हुए भक्ति प्रकट की जाती है।",
      bodyEn:
          "Gujarat’s Garba is a devotional dance associated with Navaratri and Shakti. Dancers circle a lamp-lit earthen pot or an image of goddess Amba.",
      url: "https://ich.unesco.org/en/RL/garba-of-gujarat-01962",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "durga",
      hinduMonths: [7],
      titleHi: "कोलकाता की दुर्गा पूजा",
      titleEn: "Durga Puja in Kolkata",
      bodyHi:
          "कोलकाता की दुर्गा पूजा माँ की आराधना से जुड़ी जीवंत परंपरा है। वर्ष 2021 में इसे यूनेस्को की अमूर्त सांस्कृतिक विरासत की सूची में स्थान मिला।",
      bodyEn:
          "Durga Puja in Kolkata entered UNESCO’s intangible cultural heritage list in 2021. It is a living cultural tradition centred on the worship of goddess Durga.",
      url: "https://ich.unesco.org/en/RL/durga-puja-in-kolkata-00703",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "ramlila",
      hinduMonths: [7],
      titleHi: "गाँव-नगर में जीवित रामकथा",
      titleEn: "The Ramayana on stage",
      bodyHi:
          "रामलीला में गीत, कथा और संवाद से रामायण के प्रसंग मंच पर उतरते हैं। कलाकारों और दर्शकों की भागीदारी इस परंपरा को पीढ़ियों तक जीवित रखती है।",
      bodyEn:
          "Ramlila presents the Ramayana through song, narration and dialogue. Community participation helps keep this performance tradition alive.",
      url:
          "https://ich.unesco.org/en/RL/ramlila-the-traditional-performance-of-the-ramayana-00110",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "ramman",
      titleHi: "गढ़वाल का रममाण",
      titleEn: "Garhwal’s Ramman tradition",
      bodyHi:
          "गढ़वाल हिमालय की रममाण परंपरा में धार्मिक उत्सव और अनुष्ठानिक रंगमंच साथ आते हैं। वर्ष 2009 में इसे यूनेस्को की प्रतिनिधि सूची में शामिल किया गया।",
      bodyEn:
          "Ramman is a religious festival and ritual theatre tradition of the Garhwal Himalayas. It entered UNESCO’s Representative List in 2009.",
      url: "https://ich.unesco.org/en/state/india-IN",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "kutiyattam",
      titleHi: "संस्कृत रंगमंच की धरोहर",
      titleEn: "A Sanskrit theatre heritage",
      bodyHi:
          "कुटियाट्टम संस्कृत रंगमंच की जीवित परंपरा है। इसे यूनेस्को की मानवता की अमूर्त सांस्कृतिक विरासत की प्रतिनिधि सूची में स्थान मिला है।",
      bodyEn:
          "Kutiyattam is a tradition of Sanskrit theatre recognised on UNESCO’s Representative List of the Intangible Cultural Heritage of Humanity.",
      url: "https://ich.unesco.org/en/state/india-IN",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "chhau",
      titleHi: "छऊ की नृत्य-परंपरा",
      titleEn: "The heritage of Chhau dance",
      bodyHi:
          "छऊ भारत की नृत्य-परंपराओं में अपनी अलग पहचान रखता है। वर्ष 2010 में इसे यूनेस्को की प्रतिनिधि सूची में स्थान मिला।",
      bodyEn:
          "Chhau dance is part of India’s intangible cultural heritage. It entered UNESCO’s Representative List in 2010.",
      url: "https://ich.unesco.org/en/state/india-IN",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "kalbelia",
      titleHi: "राजस्थान की कालबेलिया कला",
      titleEn: "Rajasthan’s Kalbelia heritage",
      bodyHi:
          "कालबेलिया के लोकगीत और नृत्य राजस्थान की सांस्कृतिक धरोहर हैं। इस कला-परंपरा को यूनेस्को की अमूर्त सांस्कृतिक विरासत की सूची में मान्यता मिली है।",
      bodyEn:
          "Kalbelia folk songs and dances belong to Rajasthan’s cultural heritage. The tradition is recognised on UNESCO’s intangible cultural heritage list.",
      url: "https://sangeetnatak.gov.in/sections/ICH",
      source: "Sangeet Natak Akademi",
    ),
    DailyDiscovery(
      id: "mudiyettu",
      titleHi: "केरल का मुडियेट्टु",
      titleEn: "Kerala’s ritual theatre",
      bodyHi:
          "केरल की मुडियेट्टु परंपरा में अनुष्ठान और नृत्य-नाट्य का मेल है। यह भारत की यूनेस्को-मान्य अमूर्त सांस्कृतिक धरोहरों में शामिल है।",
      bodyEn:
          "Mudiyettu is a ritual theatre and dance-drama tradition of Kerala, recognised among India’s UNESCO-listed intangible cultural heritage.",
      url: "https://sangeetnatak.gov.in/sections/ICH",
      source: "Sangeet Natak Akademi",
    ),
    DailyDiscovery(
      id: "jantar",
      titleHi: "जयपुर में आकाश को पढ़ते यंत्र",
      titleEn: "Jaipur’s astronomical heritage",
      bodyHi:
          "जयपुर का जंतर मंतर अठारहवीं शताब्दी के आरंभ का खगोलीय अवलोकन स्थल है। इसके विशाल यंत्र बताते हैं कि हमारे यहाँ आकाश के अध्ययन की कैसी समृद्ध परंपरा रही है।",
      bodyEn:
          "Jaipur’s Jantar Mantar is an astronomical observation site from the early eighteenth century. Its monumental instruments offer a window into India’s history of astronomy.",
      url: "https://whc.unesco.org/en/list/1338/",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "konark",
      titleHi: "पत्थर में उकेरा सूर्य का रथ",
      titleEn: "The Sun’s chariot in stone",
      bodyHi:
          "ओडिशा का कोणार्क सूर्य मंदिर सूर्य देव के रथ की कल्पना पर बना है। उसके चौबीस सजे हुए पहिए इस धरोहर की विशेष पहचान हैं।",
      bodyEn:
          "Odisha’s Konark Sun Temple represents the chariot of Surya. Its 24 decorated wheels are a defining feature of the monument.",
      url: "https://whc.unesco.org/en/list/246/",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "chola",
      titleHi: "चोलों की तीन महान धरोहरें",
      titleEn: "Three great Chola temples",
      bodyHi:
          "तंजावुर और गंगैकोंडचोलपुरम के बृहदीश्वर तथा दारासुरम का ऐरावतेश्वर—ये महान जीवित चोल मंदिर हैं। ग्यारहवीं-बारहवीं शताब्दी की यह धरोहर आज भी अपनी पहचान बनाए हुए है।",
      bodyEn:
          "The Great Living Chola Temples include Brihadisvara at Thanjavur, Brihadisvara at Gangaikondacholapuram and Airavatesvara at Darasuram, dating to the eleventh and twelfth centuries.",
      url: "https://whc.unesco.org/en/list/250/",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "hampi",
      titleHi: "हम्पी के मंदिर और रथमार्ग",
      titleEn: "Hampi’s chariot streets",
      bodyHi:
          "हम्पी के मंदिरों के पास चौड़े रथमार्ग हैं, जिनके दोनों ओर स्तंभों वाले मंडप मिलते हैं। यहाँ मंदिर के उत्सव और नगर की बनावट का संबंध दिखाई देता है।",
      bodyEn:
          "Hampi’s temples feature broad chariot streets lined with pillared mandapas, showing how temple festivals shaped the city’s architecture.",
      url: "https://whc.unesco.org/en/list/241/",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "nalanda",
      titleHi: "नालंदा की ज्ञान-धरोहर",
      titleEn: "Nalanda’s tradition of learning",
      bodyHi:
          "बिहार के नालंदा महाविहार के अवशेष बौद्ध शिक्षा की समृद्ध परंपरा याद दिलाते हैं। यहाँ स्तूप, पूजा-स्थल और रहने-पढ़ने के भवनों के अवशेष मिलते हैं।",
      bodyEn:
          "The ruins of Nalanda Mahavihara in Bihar preserve a heritage of Buddhist learning and monastic life, including stupas, shrines and residential and educational buildings.",
      url: "https://whc.unesco.org/en/list/1502/",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "stepwell",
      titleHi: "पानी के आदर में बनी बावड़ी",
      titleEn: "A stepwell of water and faith",
      bodyHi:
          "पाटण की रानी की वाव को जल की पवित्रता दर्शाने वाले उल्टे मंदिर की तरह रचा गया है। इस बावड़ी में सीढ़ियों के सात स्तर हैं।",
      bodyEn:
          "Rani-ki-Vav at Patan in Gujarat was designed like an inverted temple honouring the sacredness of water. It has seven levels of stairs.",
      url: "https://whc.unesco.org/en/list/922/",
      source: "UNESCO",
    ),
    DailyDiscovery(
      id: "deepavali",
      hinduMonths: [8],
      titleHi: "दीपावली को विश्व-मान्यता",
      titleEn: "Deepavali’s global recognition",
      bodyHi:
          "दीपावली को वर्ष 2025 में यूनेस्को की मानवता की अमूर्त सांस्कृतिक विरासत की प्रतिनिधि सूची में शामिल किया गया।",
      bodyEn:
          "Deepavali was inscribed on UNESCO’s Representative List of the Intangible Cultural Heritage of Humanity in 2025.",
      url:
          "https://india.un.org/en/306851-deepavali-gets-unesco-intangible-cultural-heritage-tag",
      source: "United Nations in India",
    ),
    DailyDiscovery(
      id: "republic",
      titleHi: "जब भारत गणराज्य बना",
      titleEn: "India became a republic",
      bodyHi:
          "26 जनवरी 1950 को हमारा संविधान लागू हुआ। इसी दिन भारत गणराज्य बना।",
      bodyEn:
          "On 26 January 1950, India’s Constitution came into effect and India became a republic.",
      url: "https://www.mygov.in/campaigns/read-preamble",
      source: "MyGov",
      month: 1,
      day: 26,
      year: 1950,
    ),
    DailyDiscovery(
      id: "independence",
      titleHi: "स्वाधीनता का वह प्रभात",
      titleEn: "India’s independence",
      bodyHi:
          "15 अगस्त 1947 को भारत औपनिवेशिक शासन से स्वतंत्र हुआ। यह दिन हमारे स्वतंत्रता-इतिहास का स्मरण कराता है।",
      bodyEn: "India gained independence from colonial rule on 15 August 1947.",
      url:
          "https://www.pib.gov.in/FeaturesDeatils.aspx?ModuleId=2&NoteId=157078&lang=1&reg=3",
      source: "Press Information Bureau",
      month: 8,
      day: 15,
      year: 1947,
    ),
    DailyDiscovery(
      id: "constitution",
      titleHi: "संविधान अंगीकार करने का दिन",
      titleEn: "The Constitution was adopted",
      bodyHi:
          "26 नवंबर 1949 को संविधान सभा ने भारत का संविधान अंगीकार किया। इसे 26 जनवरी 1950 को लागू किया गया।",
      bodyEn:
          "India’s Constituent Assembly adopted the Constitution on 26 November 1949. It came into effect on 26 January 1950.",
      url: "https://www.mygov.in/campaigns/read-preamble",
      source: "MyGov",
      month: 11,
      day: 26,
      year: 1949,
    ),
    DailyDiscovery(
      id: "aryabhata",
      titleHi: "अंतरिक्ष में भारत का आर्यभट",
      titleEn: "India’s first satellite",
      bodyHi:
          "19 अप्रैल 1975 को भारत का पहला उपग्रह आर्यभट प्रक्षेपित हुआ। इसका डिजाइन और निर्माण भारत में किया गया था।",
      bodyEn:
          "Aryabhata, India’s first satellite, was launched on 19 April 1975. It was designed and built in India.",
      url: "https://www.isro.gov.in/aryabhata_1.html",
      source: "ISRO",
      month: 4,
      day: 19,
      year: 1975,
    ),
    DailyDiscovery(
      id: "moon",
      titleHi: "चंद्रमा पर विक्रम के कदम",
      titleEn: "Chandrayaan-3 landed on the Moon",
      bodyHi:
          "23 अगस्त 2023 को चंद्रयान-3 के विक्रम लैंडर ने चंद्रमा पर सफल सॉफ्ट लैंडिंग की। यह भारत की अंतरिक्ष-यात्रा की उल्लेखनीय उपलब्धि है।",
      bodyEn:
          "On 23 August 2023, Chandrayaan-3’s Vikram lander successfully soft-landed on the Moon.",
      url:
          "https://www.isro.gov.in/media_isro/pdf/Monthly_summary/MonthlySummary_August2023Eng.pdf",
      source: "ISRO",
      month: 8,
      day: 23,
      year: 2023,
    ),
    DailyDiscovery(
      id: "internet",
      titleHi: "इंटरनेट की राह का पहला संदेश",
      titleEn: "An early step towards the internet",
      bodyHi:
          "29 अक्टूबर 1969 को UCLA से Stanford Research Institute तक ARPANET पर पहला संदेश भेजा गया। भेजना LOGIN था, पर शुरुआत में केवल LO ही पहुँच सका।",
      bodyEn:
          "On 29 October 1969, the first ARPANET message travelled from UCLA to Stanford Research Institute. The intended command was LOGIN, but only LO arrived before a crash.",
      url: "https://www.lk.cs.ucla.edu/internet_first_words.html",
      source: "UCLA",
      month: 10,
      day: 29,
      year: 1969,
    ),
    DailyDiscovery(
      id: "un",
      titleHi: "संयुक्त राष्ट्र की शुरुआत",
      titleEn: "The United Nations began",
      bodyHi:
          "24 अक्टूबर 1945 को संयुक्त राष्ट्र का चार्टर लागू हुआ। इसी के साथ यह संगठन औपचारिक रूप से अस्तित्व में आया।",
      bodyEn:
          "The United Nations formally came into existence on 24 October 1945 when its Charter entered into force.",
      url: "https://www.un.org/en/observances/un-day/",
      source: "United Nations",
      month: 10,
      day: 24,
      year: 1945,
    ),
    DailyDiscovery(
      id: "rights",
      titleHi: "मानव अधिकारों की घोषणा",
      titleEn: "The Universal Declaration of Human Rights",
      bodyHi:
          "10 दिसंबर 1948 को संयुक्त राष्ट्र महासभा ने मानव अधिकारों की सार्वभौम घोषणा अंगीकार की।",
      bodyEn:
          "The UN General Assembly adopted the Universal Declaration of Human Rights on 10 December 1948.",
      url:
          "https://www.un.org/en/about-us/universal-declaration-of-human-rights",
      source: "United Nations",
      month: 12,
      day: 10,
      year: 1948,
    ),
    DailyDiscovery(
      id: "yoga-day",
      titleHi: "विश्व योग दिवस",
      titleEn: "International Day of Yoga",
      bodyHi:
          "21 जून को अंतरराष्ट्रीय योग दिवस मनाया जाता है। संयुक्त राष्ट्र ने वर्ष 2014 में इस दिन की घोषणा की थी।",
      bodyEn:
          "21 June is the International Day of Yoga, proclaimed by the United Nations in 2014.",
      url: "https://www.un.org/en/observances/yoga-day",
      source: "United Nations",
      month: 6,
      day: 21,
      year: 2015,
    ),
    DailyDiscovery(
      id: "language",
      titleHi: "अपनी मातृभाषा का आदर",
      titleEn: "International Mother Language Day",
      bodyHi:
          "21 फरवरी अंतरराष्ट्रीय मातृभाषा दिवस है। यह दिन मातृभाषाओं और भाषाओं की विविधता के महत्त्व का स्मरण कराता है।",
      bodyEn:
          "21 February is International Mother Language Day, recognising the importance of mother languages and linguistic diversity.",
      url: "https://www.unesco.org/en/days/mother-language",
      source: "UNESCO",
      month: 2,
      day: 21,
      year: 2000,
    ),
  ];
}
