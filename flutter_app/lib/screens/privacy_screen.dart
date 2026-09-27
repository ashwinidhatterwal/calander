import 'package:flutter/material.dart';

import '../core/localization.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key, required this.language});

  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final hi = language == AppLanguage.hi;
    return Scaffold(
      appBar: AppBar(title: Text(hi ? 'गोपनीयता' : 'Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _Section(
            title: hi ? 'आपका कैलेंडर डेटा' : 'Your calendar data',
            body: hi
                ? 'आपके निजी कार्यक्रम, चुनी हुई भाषा और स्थान इस डिवाइस पर ही सहेजे जाते हैं। ऐप इन्हें किसी सर्वर पर अपलोड नहीं करता।'
                : 'Your personal events, selected language and location are stored on this device. The app does not upload them to a server.',
          ),
          _Section(
            title: hi ? 'विज्ञापन और ट्रैकिंग' : 'Ads and tracking',
            body: hi
                ? 'ऐप में विज्ञापन, व्यवहारिक ट्रैकिंग या एनालिटिक्स SDK नहीं हैं।'
                : 'The app contains no ads, behavioral tracking, or analytics SDK.',
          ),
          _Section(
            title: hi ? 'वैकल्पिक डेवलपर सहयोग' : 'Optional developer support',
            body: hi
                ? 'यदि आप स्वेच्छा से डेवलपर को टिप भेजते हैं, भुगतान आपके चुने हुए बाहरी UPI ऐप में पूरा होता है। हिन्दू कैलेंडर आपके बैंक या UPI क्रेडेंशियल नहीं पढ़ता या सहेजता।'
                : 'If you voluntarily tip the developer, payment is completed in the external UPI app you choose. Hindu Calendar does not read or store your bank or UPI credentials.',
          ),
          _Section(
            title: hi ? 'हस्तलिखित धन्यवाद-पत्र' : 'Handwritten thank-you note',
            body: hi
                ? 'यदि आप भौतिक हस्तलिखित धन्यवाद-पत्र माँगते हैं, आपका ईमेल ऐप खुलता है और आप स्वयं नाम व डाक-पता भेजते हैं। ऐप यह जानकारी सहेजता नहीं है। डेवलपर को मिली डाक-पता जानकारी केवल पत्र भेजने के लिए उपयोग की जानी चाहिए और भेजने के 30 दिनों के भीतर हटाई जानी चाहिए।'
                : 'If you request a physical handwritten thank-you note, your email app opens and you choose to send your name and postal address. The app does not store this information. Postal-address information received by the developer should be used only to mail the note and deleted within 30 days after dispatch.',
          ),
          _Section(
            title: hi ? 'पंचांग परंपरा' : 'Panchang tradition',
            body: hi
                ? 'मुख्य कैलेंडर उत्तर भारतीय पूर्णिमांत परंपरा के अनुसार बनाया गया है। स्थानीय परंपराओं और अलग पंचांग पद्धतियों में पर्व या मुहूर्त की तारीख/समय में अंतर हो सकता है।'
                : 'The main calendar follows the North Indian Purnimanta tradition. Festival dates or Muhurta times can differ under regional traditions and other Panchang methods.',
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
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(body, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
          ],
        ),
      );
}
