import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/localization.dart';

class DeveloperDetailsCard extends StatelessWidget {
  const DeveloperDetailsCard(
      {super.key,
      required this.language,
      required this.name,
      required this.email});
  final AppLanguage language;
  final String name, email;

  @override
  Widget build(BuildContext context) {
    final l = L10n(language);
    final theme = Theme.of(context);
    final contact = email.trim();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14)),
                    child: Icon(Icons.code_outlined,
                        color: theme.colorScheme.primary)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(l.pick('डेवलपर', 'Developer'),
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 16),
              SelectableText(name,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700, height: 1.4)),
              const SizedBox(height: 8),
              Text(l.pick('संपर्क ईमेल', 'Contact email'),
                  style: theme.textTheme.labelLarge
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              if (contact.isNotEmpty)
                SelectableText(contact,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5))
              else
                Text(l.pick('संपर्क ईमेल उपलब्ध नहीं है।',
                    'Contact email is unavailable.')),
              if (contact.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton.icon(
                          onPressed: () => _email(context, contact),
                          icon: const Icon(Icons.mail_outline, size: 19),
                          label: Text(l.pick('ईमेल लिखें', 'Write an email'))),
                      TextButton.icon(
                          onPressed: () => _copy(context, contact),
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          label: Text(l.pick('ईमेल कॉपी करें', 'Copy email'))),
                    ]),
              ],
            ])));
  }

  Future<void> _copy(BuildContext context, String contact) async {
    await Clipboard.setData(ClipboardData(text: contact));
    if (!context.mounted) return;
    final l = L10n(language);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(l.pick('ईमेल पता कॉपी हो गया।', 'Email address copied.'))));
  }

  Future<void> _email(BuildContext context, String contact) async {
    try {
      final uri = Uri(
          scheme: 'mailto',
          path: contact,
          query: 'subject=${Uri.encodeComponent('Hindu Calendar')}');
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {/* Copying preserves access when no email app is available. */}
    if (!context.mounted) return;
    await _copy(context, contact);
  }
}
