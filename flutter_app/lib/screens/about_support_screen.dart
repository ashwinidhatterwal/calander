import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization.dart';
import '../core/release_config.dart';
import 'privacy_screen.dart';

class AboutSupportScreen extends StatelessWidget {
  const AboutSupportScreen({super.key, required this.language});

  final AppLanguage language;

  bool get _hi => language == AppLanguage.hi;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_hi ? 'ऐप के बारे में' : 'About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Center(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset('assets/branding/app_icon.png', width: 82, height: 82),
                ),
                const SizedBox(height: 12),
                Text(
                  _hi ? 'हिन्दू कैलेंडर' : 'Hindu Calendar',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text('v${ReleaseConfig.appVersion}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  _hi ? 'तिथि • पर्व • आपके दिन' : 'Tithi • Festivals • Your days',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.favorite_border, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hi ? 'विकास में सहयोग' : 'Support development',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _hi
                        ? 'ऐप पूरी तरह मुफ्त है। सहयोग करने या न करने से कोई सुविधा नहीं बदलती। यदि यह ऐप आपके काम आता है, तो आप डेवलपर को स्वेच्छा से एक टिप भेज सकते हैं।'
                        : 'The app is completely free. Supporting or not supporting never changes any feature. If the app is useful to you, you may voluntarily send the developer a tip.',
                    style: const TextStyle(height: 1.45),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hi
                        ? 'यह चैरिटी दान नहीं है और कर-छूट योग्य नहीं है। कोई डिजिटल सुविधा, बैज या सामग्री नहीं खुलती।'
                        : 'This is not a charitable donation and is not tax-deductible. It unlocks no digital feature, badge, or content.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _hi
                        ? 'भुगतान सीधे डेवलपर के UPI खाते में जाता है; ऐप भुगतान को पढ़ता या सत्यापित नहीं करता।'
                        : 'Payment goes directly to the developer’s UPI account; the app does not read or verify the payment.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
                  ),
                  if (ReleaseConfig.supportConfigured) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _openUpi(context),
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: Text(_hi ? 'स्वेच्छा से सहयोग करें' : 'Send a voluntary tip'),
                    ),
                  ],
                  if (!ReleaseConfig.supportConfigured) ...[
                    const SizedBox(height: 12),
                    Text(
                      _hi ? 'इस परीक्षण बिल्ड में सहयोग भुगतान सक्रिय नहीं है।' : 'Support payments are not configured in this test build.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(_hi ? 'व्यक्तिगत हस्तलिखित धन्यवाद-पत्र' : 'Personal handwritten thank-you note'),
              subtitle: Text(
                _hi
                    ? 'सहयोग करने के बाद चाहें तो अपना डाक-पता ईमेल करके एक भौतिक हस्तलिखित धन्यवाद-पत्र माँग सकते हैं।'
                    : 'After supporting, you may email your postal address to request a physical handwritten thank-you note.',
              ),
              trailing: ReleaseConfig.noteRequestConfigured ? const Icon(Icons.chevron_right) : null,
              onTap: ReleaseConfig.noteRequestConfigured ? () => _requestNote(context) : null,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(_hi ? 'गोपनीयता' : 'Privacy'),
                  subtitle: Text(_hi ? 'लोकल डेटा, सहयोग और धन्यवाद-पत्र नीति' : 'Local data, support, and thank-you-note policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrivacyScreen(language: language)),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(_hi ? 'ओपन-सोर्स लाइसेंस' : 'Open-source licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: _hi ? 'हिन्दू कैलेंडर' : 'Hindu Calendar',
                    applicationVersion: ReleaseConfig.appVersion,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset('assets/branding/app_icon.png', width: 52, height: 52),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUpi(BuildContext context) async {
    try {
      final uri = Uri(
        scheme: 'upi',
        host: 'pay',
        queryParameters: {
          'pa': ReleaseConfig.supportUpiId,
          'pn': ReleaseConfig.supportPayeeName,
          'tn': 'Voluntary tip for Hindu Calendar development',
          'cu': 'INR',
        },
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hi ? 'कोई UPI ऐप नहीं खुल सका।' : 'No UPI app could be opened.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hi ? 'UPI ऐप खोलने में समस्या हुई।' : 'There was a problem opening the UPI app.')),
        );
      }
    }
  }

  Future<void> _requestNote(BuildContext context) async {
    try {
      final subject = _hi ? 'हस्तलिखित धन्यवाद-पत्र — हिन्दू कैलेंडर' : 'Handwritten thank-you note — Hindu Calendar';
      final body = _hi
          ? 'नमस्ते,\n\nमैंने हिन्दू कैलेंडर के विकास में सहयोग किया है और व्यक्तिगत हस्तलिखित धन्यवाद-पत्र चाहूँगा/चाहूँगी।\n\nनाम:\nडाक-पता:\nवैकल्पिक UPI ट्रांजैक्शन रेफरेंस:\n\nधन्यवाद।'
          : 'Hello,\n\nI supported Hindu Calendar development and would like the personal handwritten thank-you note.\n\nName:\nPostal address:\nOptional UPI transaction reference:\n\nThank you.';
      final uri = Uri(
        scheme: 'mailto',
        path: ReleaseConfig.supportEmail,
        queryParameters: {'subject': subject, 'body': body},
      );
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hi ? 'ईमेल ऐप नहीं खुल सका।' : 'No email app could be opened.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_hi ? 'ईमेल ऐप खोलने में समस्या हुई।' : 'There was a problem opening the email app.')),
        );
      }
    }
  }

}
