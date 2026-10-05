/// Short cultural explanations; observance customs vary by family and region.
const festivalDescriptions = <String, (String, String)>{
  'maha_shivaratri': (
    'भगवान शिव की आराधना का पर्व। भक्त उपवास, शिवलिंग पूजन और रात्रि जागरण करते हैं।',
    'A festival devoted to Lord Shiva, traditionally observed with fasting, worship and a night vigil.'
  ),
  'rama_navami': (
    'भगवान राम के जन्म का उत्सव। रामायण पाठ और दोपहर में जन्मोत्सव पूजा की परंपरा है।',
    'Celebrates the birth of Lord Rama, with Ramayana recitations and traditional midday worship.'
  ),
  'raksha_bandhan': (
    'भाई-बहन के स्नेह और पारस्परिक संरक्षण का पर्व। बहनें राखी बाँधती हैं और परिवार शुभकामनाएँ साझा करता है।',
    'Celebrates sibling affection and care through tying a rakhi and exchanging blessings.'
  ),
  'janmashtami': (
    'भगवान श्रीकृष्ण के जन्म का उत्सव। उपवास, भजन और मध्यरात्रि जन्मोत्सव प्रमुख परंपराएँ हैं।',
    'Celebrates Lord Krishna’s birth with fasting, devotional singing and a midnight celebration.'
  ),
  'ganesh_chaturthi': (
    'भगवान गणेश के जन्म का पर्व। गणपति स्थापना, पूजा और मोदक का भोग लगाया जाता है।',
    'Celebrates Lord Ganesha’s birth with installation of his image, worship and offerings of modak.'
  ),
  'shardiya_navratri': (
    'देवी दुर्गा की नौ रातों की आराधना का आरम्भ। घटस्थापना, उपवास और देवी पाठ की परंपरा है।',
    'Begins nine nights of worship of Goddess Durga, with ceremonial pot installation, fasting and devotional readings.'
  ),
  'chaitra_navratri': (
    'चैत्र मास में देवी दुर्गा की नौ रातों की आराधना का आरम्भ। घटस्थापना, देवी पाठ और उपवास की परंपरा है।',
    'Begins the spring Navratri worship of Goddess Durga, with ceremonial pot installation, devotional readings and fasting.',
  ),
  'chaitra_durga_ashtami': (
    'चैत्र नवरात्रि की अष्टमी पर देवी पूजन और कन्या पूजन की परंपरा है। परिवार और क्षेत्र के अनुसार विधियाँ बदलती हैं।',
    'The Ashtami observance during Chaitra Navratri, traditionally marked by Devi worship and Kanya Puja; customs vary.',
  ),
  'durga_ashtami': (
    'शारदीय नवरात्रि का प्रमुख देवी पर्व, जिसे महाष्टमी भी कहते हैं। देवी पूजन और कन्या पूजन की परंपरा है।',
    'A major Devi observance during Shardiya Navratri, also called Mahashtami, traditionally marked by worship and Kanya Puja.',
  ),
  'vijayadashami': (
    'असत्य पर सत्य की विजय का उत्सव। राम की रावण पर और दुर्गा की महिषासुर पर विजय का स्मरण होता है।',
    'Celebrates the victory of good over evil, recalling Rama’s victory over Ravana and Durga’s over Mahishasura.'
  ),
  'karwa_chauth': (
    'वैवाहिक मंगल की कामना का व्रत। परंपरागत रूप से चंद्र दर्शन और अर्घ्य के बाद उपवास खोला जाता है।',
    'A fast traditionally observed for marital well-being, concluded after sighting and offering water to the moon.'
  ),
  'dhanteras': (
    'धन्वंतरि और समृद्धि की आराधना का पर्व। दीप जलाने और शुभ खरीदारी की परंपरा है।',
    'Honours Dhanvantari and prosperity, traditionally marked by lighting lamps and auspicious purchases.'
  ),
  'diwali': (
    'प्रकाश और मंगल का पर्व। घरों में दीप जलाकर लक्ष्मी-गणेश पूजन किया जाता है और शुभकामनाएँ बाँटी जाती हैं।',
    'The festival of lights, celebrated with lamps, Lakshmi–Ganesha worship and shared good wishes.'
  ),
  'govardhan_puja': (
    'श्रीकृष्ण द्वारा गोवर्धन धारण की स्मृति में पूजा। अन्नकूट और प्रकृति के प्रति कृतज्ञता की परंपरा है।',
    'Recalls Krishna lifting Govardhan, celebrated through Annakut offerings and gratitude to nature.'
  ),
  'bhai_dooj': (
    'भाई-बहन के स्नेह का पर्व। बहनें भाई को तिलक लगाकर उसके सुख और मंगल की कामना करती हैं।',
    'Celebrates sibling affection; sisters apply a ceremonial tilak and offer wishes for their brother’s well-being.'
  ),
  'holika_dahan': (
    'भक्त प्रह्लाद की कथा से जुड़ा अग्नि उत्सव। होलिका दहन बुराई के अंत और भक्ति की विजय का प्रतीक है।',
    'A bonfire observance associated with Prahlada, symbolising the defeat of evil and the strength of devotion.'
  ),
  'holi': (
    'रंगों और मिलन का उत्सव। लोग रंग खेलते हैं, मिठाइयाँ बाँटते हैं और आपसी स्नेह बढ़ाते हैं।',
    'A festival of colours and togetherness, celebrated by playing with colours and sharing sweets.'
  ),
  'ekadashi': (
    'प्रत्येक पक्ष की एकादशी पर भगवान विष्णु की आराधना और उपवास की परंपरा है। पारण का समय स्थानीय परंपरा से देखें।',
    'The eleventh lunar day of each fortnight, traditionally devoted to Vishnu worship and fasting; breaking-fast customs vary.'
  ),
  'purnima': (
    'पूर्णिमा पर चंद्रमा पूर्ण दिखाई देता है। स्नान, दान और सत्यनारायण पूजा की परंपरा है।',
    'The full-moon observance, traditionally associated with ritual bathing, charity and Satyanarayan worship.'
  ),
  'amavasya': (
    'अमावस्या नवचंद्र की तिथि है। पितृ-स्मरण, दान और ध्यान की परंपरा है।',
    'The new-moon observance, traditionally associated with remembrance of ancestors, charity and reflection.'
  ),
  'pradosh': (
    'त्रयोदशी की संध्या में भगवान शिव की आराधना का व्रत। प्रदोष काल में पूजा की जाती है।',
    'A Shiva observance on the thirteenth lunar day, with worship around twilight.'
  ),
  'sankashti': (
    'कृष्ण पक्ष चतुर्थी पर भगवान गणेश की आराधना का व्रत। चंद्र दर्शन के बाद व्रत खोलने की परंपरा है।',
    'A Ganesha fast on the fourth day of the waning fortnight, traditionally concluded after moon sighting.'
  ),
};
String festivalDescription(String id, bool hindi) {
  final item = festivalDescriptions[id] ??
      festivalDescriptions.entries
          .where((e) => id.startsWith(e.key))
          .map((e) => e.value)
          .firstOrNull;
  return item == null
      ? ''
      : hindi
          ? item.$1
          : item.$2;
}
