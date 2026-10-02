import 'package:flutter/material.dart';

import '../core/localization.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final l = L10n(language);
    final hi = language == AppLanguage.hi;
    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'गोपनीयता' : 'Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(l.pick(
                  'जिला नाम के लिए स्थान लेने या रीफ़्रेश करने पर Android की स्थान-नाम सेवा इंटरनेट इस्तेमाल कर सकती है। नाम और निर्देशांक फ़ोन पर सहेजे जाते हैं। वैकल्पिक सूचनाएँ स्थानीय गणना से बनती हैं; इनमें नया GPS स्थान नहीं लिया जाता। लॉक स्क्रीन पर जानकारी फ़ोन की सेटिंग के अनुसार दिख सकती है।',
                  'An explicit location acquisition or refresh may use Android’s Geocoder provider to look up the district over the internet. Names and coordinates stay saved on your device. Optional reminders use local calculations and never request background GPS. Notification details may appear on your lock screen according to your phone settings.'))),
          _Section(
            title: hi ? 'आपका कैलेंडर डेटा' : 'Your calendar data',
            body: hi
                ? 'आपके निजी कार्यक्रम, चुनी हुई भाषा, शहर और ऐप का रूप-रंग इसी डिवाइस पर सहेजे जाते हैं। हिन्दू कैलेंडर इस डेटा को किसी डेवलपर सर्वर पर अपलोड नहीं करता।'
                : 'Your personal events, selected language, city, and app appearance are stored on this device. Hindu Calendar does not upload this data to a developer-operated server.',
          ),
          _Section(
            title: hi ? 'विज्ञापन और ट्रैकिंग' : 'Ads and tracking',
            body: hi
                ? 'ऐप में विज्ञापन, व्यवहारिक ट्रैकिंग या एनालिटिक्स SDK नहीं हैं।'
                : 'The app contains no ads, behavioral tracking, or analytics SDK.',
          ),
          _Section(
            title: hi ? 'वैकल्पिक सहयोग' : 'Optional developer support',
            body: hi
                ? 'अगर आप डेवलपर को सहयोग भेजना चुनते हैं, तो भुगतान आपके चुने हुए बाहरी UPI ऐप में पूरा होता है। हिन्दू कैलेंडर आपके बैंक, UPI पिन या भुगतान की जानकारी नहीं पढ़ता और न ही सहेजता है।'
                : 'If you choose to support the developer, payment is completed in the external UPI app you select. Hindu Calendar does not read or store your bank details, UPI PIN, or payment information.',
          ),
          _Section(
            title: hi
                ? 'डाक से धन्यवाद-पत्र'
                : 'Mailed handwritten thank-you note',
            body: hi
                ? 'अगर आप हस्तलिखित धन्यवाद-पत्र चाहते हैं, तो ऐप केवल आपका ईमेल ऐप खोलता है। नाम और डाक-पता भेजना पूरी तरह आपकी इच्छा पर है। हिन्दू कैलेंडर यह जानकारी अपने भीतर सहेजता नहीं है। डेवलपर इस पते का उपयोग केवल पत्र भेजने के लिए करेगा और पत्र भेजने के 30 दिनों के भीतर इसे हटा देगा।'
                : 'If you would like a handwritten thank-you note, the app only opens your email client. Sending your name and postal address is entirely your choice. Hindu Calendar does not store this information inside the app. The developer will use the address only to mail the requested note and delete it within 30 days after dispatch.',
          ),
          _Section(
            title: hi ? 'पंचांग परंपरा' : 'Panchang tradition',
            body: hi
                ? 'मुख्य कैलेंडर उत्तर भारत में प्रचलित पूर्णिमांत पद्धति के अनुसार बनाया गया है। अलग क्षेत्रों या परंपराओं में कुछ पर्वों और मुहूर्तों की तारीख या समय अलग हो सकता है।'
                : 'The main calendar follows the North Indian Purnimanta tradition. Some festival dates and Muhurta times may differ under regional or community-specific traditions.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style:
                  Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ),
      );
}
