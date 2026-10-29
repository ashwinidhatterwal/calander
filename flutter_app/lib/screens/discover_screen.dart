import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization.dart';
import '../data/daily_discoveries.dart';

/// A local, editorial daily read. No polling, background work or network feed.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.language, required this.active,
    this.clock = DateTime.now});
  final AppLanguage language;
  final bool active;
  final DateTime Function() clock;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with WidgetsBindingObserver {
  late DateTime _date;
  Timer? _midnight;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _date = widget.clock();
    _refresh();
  }

  @override
  void didUpdateWidget(covariant DiscoverScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active || oldWidget.clock != widget.clock) {
      _refresh();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _refresh();
  }

  void _refresh() {
    _midnight?.cancel();
    if (!widget.active || !_foreground) return;
    final now = widget.clock();
    if (_date.year != now.year || _date.month != now.month || _date.day != now.day) {
      setState(() => _date = now);
    }
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(next.difference(now) + const Duration(seconds: 1), _refresh);
  }

  @override
  void dispose() {
    _midnight?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.language);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final events = DailyDiscoveries.onThisDay(_date);
    final culture = DailyDiscoveries.cultureFor(_date);
    return ListView(
      key: const PageStorageKey('daily-discoveries'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(l.pick('आज का ज्ञान', 'Discover today'),
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(l.pick('हमारी संस्कृति, हमारी दुनिया', 'Our culture, our world'),
          style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [scheme.primaryContainer,
              scheme.secondaryContainer]),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.auto_stories_outlined, size: 34, color: scheme.onPrimaryContainer),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(MaterialLocalizations.of(context).formatFullDate(_date),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800, color: scheme.onPrimaryContainer)),
              const SizedBox(height: 6),
              Text(l.pick('हर दिन, कुछ नया जानें', 'A little discovery every day'),
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
            ])),
          ]),
        ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 24),
          _section(context, Icons.history_edu, l.pick('आज के दिन', 'On this day')),
          const SizedBox(height: 10),
          for (final entry in events) ...[
            _DiscoveryCard(entry: entry, language: widget.language),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 20),
        _section(context, Icons.temple_hindu_outlined,
          l.pick('अपनी विरासत जानें', 'Explore our heritage')),
        const SizedBox(height: 10),
        _DiscoveryCard(entry: culture, language: widget.language),
        const SizedBox(height: 14),
        Text(l.pick('सांस्कृतिक जानकारी रोज़ बदलती है। ऐतिहासिक घटनाएँ उनकी संबंधित तारीख पर दिखाई जाती हैं।',
          'Cultural cards rotate daily. Historical events appear on their matching dates.'),
          style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _section(BuildContext context, IconData icon, String title) => Row(children: [
    Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
    const SizedBox(width: 8),
    Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium
      ?.copyWith(fontWeight: FontWeight.w800))),
  ]);
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({required this.entry, required this.language});
  final DailyDiscovery entry;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final l = L10n(language);
    final theme = Theme.of(context);
    final title = l.pick(entry.titleHi, entry.titleEn);
    final body = l.pick(entry.bodyHi, entry.bodyEn);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (entry.year != null) ...[
            Text('${entry.year}', style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
          ],
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          SelectableText(body, style: theme.textTheme.bodyLarge?.copyWith(height: 1.65)),
          const SizedBox(height: 12),
          const Divider(),
          Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8, children: [
              TextButton.icon(
                onPressed: () => _openSource(context),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text('${l.pick('स्रोत', 'Source')}: ${entry.source}'),
              ),
              IconButton(
                tooltip: l.pick('जानकारी कॉपी करें', 'Copy this fact'),
                icon: const Icon(Icons.copy_outlined, size: 20),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: '$title\n\n$body\n\n${entry.source}: ${entry.url}'));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(l.pick('जानकारी कॉपी हो गई', 'Fact copied'))));
                },
              ),
            ]),
        ]),
      ),
    );
  }

  Future<void> _openSource(BuildContext context) async {
    final l = L10n(language);
    try {
      if (await launchUrl(Uri.parse(entry.url), mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      // Preserve access to the citation when a browser cannot be opened.
    }
    if (!context.mounted) return;
    await showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: Text(l.pick('स्रोत का लिंक', 'Source link')),
      content: SelectableText(entry.url),
      actions: [TextButton(onPressed: () => Navigator.pop(context),
        child: Text(l.pick('बंद करें', 'Close')))],
    ));
  }
}
