import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/localization.dart';
import '../core/release_config.dart';
import 'privacy_screen.dart';

class AboutSupportScreen extends StatefulWidget {
  const AboutSupportScreen({
    super.key,
    required this.language,
    required this.initialTheme,
    required this.onThemeChanged,
  });

  final AppLanguage language;
  final AppThemePreference initialTheme;
  final ValueChanged<AppThemePreference> onThemeChanged;

  @override
  State<AboutSupportScreen> createState() => _AboutSupportScreenState();
}

class _AboutSupportScreenState extends State<AboutSupportScreen> {
  late AppThemePreference _themePreference;

  bool get _hi => widget.language == AppLanguage.hi;

  @override
  void initState() {
    super.initState();
    _themePreference = widget.initialTheme;
  }

  void _setTheme(AppThemePreference value) {
    setState(() => _themePreference = value);
    widget.onThemeChanged(value);
  }

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
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    width: 82,
                    height: 82,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _hi ? 'हिन्दू कैलेंडर' : 'Hindu Calendar',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  'v${ReleaseConfig.appVersion}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 6),
                Text(
                  _hi ? 'तिथि • पर्व • आपके दिन' : 'Tithi • Festivals • Your days',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_outlined, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hi ? 'रूप-रंग' : 'Appearance',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _hi
                        ? 'ऐप हल्के रंग में खुलता है। चाहें तो गहरा रूप चुन सकते हैं।'
                        : 'The app opens in light mode by default. You can switch to dark mode if you prefer.',
                  ),
                  const SizedBox(height: 14),
                  SegmentedButton<AppThemePreference>(
                    segments: [
                      ButtonSegment(
                        value: AppThemePreference.light,
                        icon: const Icon(Icons.light_mode_outlined),
                        label: Text(_hi ? 'हल्का' : 'Light'),
                      ),
                      ButtonSegment(
                        value: AppThemePreference.dark,
                        icon: const Icon(Icons.dark_mode_outlined),
                        label: Text(_hi ? 'गहरा' : 'Dark'),
                      ),
                    ],
                    selected: {_themePreference},
                    onSelectionChanged: (values) => _setTheme(values.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
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
                          _hi ? 'अगर ऐप आपके काम आता है' : 'If the app is useful to you',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _hi
                        ? 'हिन्दू कैलेंडर बिना विज्ञापन और बिना पेवॉल के उपलब्ध है। अगर यह आपके रोज़मर्रा के काम आता है और आप आगे के विकास में हाथ बँटाना चाहें, तो डेवलपर को अपनी इच्छा से एक छोटा-सा सहयोग भेज सकते हैं।'
                        : 'Hindu Calendar is available without ads or a paywall. If it has become useful in your day-to-day life and you would like to help with future development, you can send the developer a small contribution of your choice.',
                    style: const TextStyle(height: 1.48),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    _hi
                        ? 'यह पूरी तरह वैकल्पिक है। सहयोग करने या न करने से ऐप की कोई सुविधा नहीं बदलती। भुगतान आपके UPI ऐप में पूरा होता है; हिन्दू कैलेंडर आपके भुगतान की जानकारी नहीं पढ़ता।'
                        : 'This is completely optional. Supporting the developer never changes or unlocks any app feature. Payment is completed in your UPI app; Hindu Calendar does not read your payment information.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                  ),
                  if (ReleaseConfig.supportConfigured) ...[
                    const SizedBox(height: 16),
                    FilledButton.tonalIcon(
                      onPressed: () => _openUpi(context),
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: Text(
                        _hi
                            ? 'डेवलपर को सहयोग भेजें'
                            : 'Support the developer',
                      ),
                    ),
                  ],
                  if (!ReleaseConfig.supportConfigured) ...[
                    const SizedBox(height: 12),
                    Text(
                      _hi
                          ? 'इस परीक्षण संस्करण में सहयोग लिंक सेट नहीं किया गया है।'
                          : 'The support link is not configured in this test build.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
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
              title: Text(
                _hi ? 'एक निजी धन्यवाद' : 'A personal thank-you',
              ),
              subtitle: Text(
                _hi
                    ? 'सहयोग के लिए धन्यवाद कहने के तौर पर, डेवलपर अपने हाथ से लिखा एक छोटा-सा पत्र डाक से भेजना चाहता है। चाहें तो सहयोग के बाद अपना नाम और डाक-पता ईमेल कर सकते हैं।'
                    : 'To say thank you, the developer would be happy to mail you a short handwritten note. If you would like one, you can email your name and postal address after supporting.',
              ),
              trailing: ReleaseConfig.noteRequestConfigured
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: ReleaseConfig.noteRequestConfigured
                  ? () => _requestNote(context)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text(_hi ? 'गोपनीयता' : 'Privacy'),
                  subtitle: Text(
                    _hi
                        ? 'लोकल डेटा, सहयोग और डाक से धन्यवाद-पत्र की जानकारी'
                        : 'Local data, optional support, and mailed thank-you-note details',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PrivacyScreen(language: widget.language),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: Text(
                    _hi ? 'ओपन-सोर्स लाइसेंस' : 'Open-source licenses',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName:
                        _hi ? 'हिन्दू कैलेंडर' : 'Hindu Calendar',
                    applicationVersion: ReleaseConfig.appVersion,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/branding/app_icon.png',
                        width: 52,
                        height: 52,
                      ),
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
          'tn': 'Support for Hindu Calendar development',
          'cu': 'INR',
        },
      );
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hi
                  ? 'UPI ऐप नहीं खुल सका।'
                  : 'No UPI app could be opened.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hi
                  ? 'UPI ऐप खोलने में समस्या हुई।'
                  : 'There was a problem opening the UPI app.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _requestNote(BuildContext context) async {
    try {
      final subject = _hi
          ? 'हिन्दू कैलेंडर — धन्यवाद-पत्र'
          : 'Hindu Calendar — handwritten thank-you note';
      final body = _hi
          ? 'नमस्ते,\n\nमैंने हिन्दू कैलेंडर के विकास में सहयोग किया है। अगर संभव हो तो मुझे आपका हस्तलिखित धन्यवाद-पत्र पाकर खुशी होगी।\n\nनाम:\nडाक-पता:\nवैकल्पिक UPI ट्रांजैक्शन रेफरेंस:\n\nधन्यवाद।'
          : 'Hello,\n\nI supported Hindu Calendar development. If possible, I would be happy to receive your handwritten thank-you note.\n\nName:\nPostal address:\nOptional UPI transaction reference:\n\nThank you.';
      final uri = Uri(
        scheme: 'mailto',
        path: ReleaseConfig.supportEmail,
        queryParameters: {'subject': subject, 'body': body},
      );
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hi ? 'ईमेल ऐप नहीं खुल सका।' : 'No email app could be opened.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _hi
                  ? 'ईमेल ऐप खोलने में समस्या हुई।'
                  : 'There was a problem opening the email app.',
            ),
          ),
        );
      }
    }
  }
}
