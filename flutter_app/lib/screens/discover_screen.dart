import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/localization.dart';
import '../data/daily_discoveries.dart';
import '../domain/festival_engine.dart';
import '../domain/panchang_engine.dart';
import '../domain/models.dart';

/// A local, editorial daily read. No polling, background work or network feed.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({
    super.key,
    required this.language,
    required this.active,
    this.clock = DateTime.now,
    this.location,
    this.festival,
  });
  final GeoLocation? location;
  final FestivalEngine? festival;
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
  int _request = 0;
  String? _loadedKey;
  Set<String> _festivals = {};
  bool _loading = false;
  bool _failed = false;
  late final FestivalEngine _fallback = FestivalEngine(const PanchangEngine());

  void _loadObservances() {
    final location = widget.location;
    if (location == null || !widget.active || !_foreground) return;
    final key =
        '${_date.year}-${_date.month}-${_date.day}|${location.cacheKey}';
    if (key == _loadedKey) return;
    _loadedKey = key;
    _loading = true;
    _failed = false;
    _festivals = {};
    final request = ++_request;
    final engine = widget.festival ?? _fallback;
    final date = _date;
    engine.majorFestivalsAsync(date.year, location).then((major) {
      if (!mounted || request != _request) return;
      setState(() {
        _festivals = engine
            .lightweightForDate(date, location, major: major)
            .map((e) => e.id)
            .toSet();
        _loading = false;
      });
    }).catchError((Object _) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    });
  }

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
    if (oldWidget.location?.cacheKey != widget.location?.cacheKey ||
        oldWidget.festival != widget.festival) {
      _loadedKey = null;
      _request++;
      _festivals = {};
      _loading = false;
    }
    if (oldWidget.active != widget.active ||
        oldWidget.clock != widget.clock ||
        oldWidget.location?.cacheKey != widget.location?.cacheKey ||
        oldWidget.festival != widget.festival) {
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
    if (_date.year != now.year ||
        _date.month != now.month ||
        _date.day != now.day) {
      setState(() {
        _date = now;
      });
    }
    _loadObservances();
    final next = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      next.difference(now) + const Duration(seconds: 1),
      _refresh,
    );
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
    final location = widget.location;
    final cell = location == null
        ? null
        : const PanchangEngine().monthCell(_date, location);
    final rawTithi = cell == null
        ? 0
        : cell.tithi.index + (cell.pakshaEn == 'Krishna Paksha' ? 15 : 0);
    final sections = DailyDiscoveries.dailySections(
        date: _date,
        hinduMonth: cell?.month.index ?? 0,
        rawTithi: rawTithi,
        adhik: cell?.adhik ?? false,
        festivals: _festivals);

    return ListView(
      key: const PageStorageKey('daily-discoveries'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Text(
          l.pick('आज का ज्ञान', 'Discover today'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l.pick(
            'एक अभ्यास • एक विचार • एक नई जानकारी',
            'One practice • One reflection • One discovery',
          ),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primaryContainer, scheme.secondaryContainer],
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.auto_stories_outlined,
                size: 34,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MaterialLocalizations.of(context).formatFullDate(_date),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    if (cell != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${cell.adhik ? '${l.adhik} ' : ''}${l.pick(cell.month.hi, cell.month.en)} • ${l.pick(cell.pakshaHi, cell.pakshaEn)} ${l.pick(cell.tithi.hi, cell.tithi.en)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      l.pick(
                        'हर दिन, कुछ नया जानें',
                        'A little discovery every day',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_failed)
          TextButton.icon(
            onPressed: () => setState(() {
              _loadedKey = null;
              _loadObservances();
            }),
            icon: const Icon(Icons.refresh),
            label: Text(
              l.pick('पर्व जानकारी फिर लाएँ', 'Retry observance details'),
            ),
          ),
        const SizedBox(height: 24),
        _section(context, Icons.self_improvement,
            l.pick('अध्यात्म और अच्छी आदतें', 'Spirituality & good practices')),
        const SizedBox(height: 4),
        Text(
            l.pick('मन को शांत करें, जीवन में अपनाएँ',
                'A quiet moment. A meaningful practice.'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        _DiscoveryCard(
            entry: sections.spiritual,
            language: widget.language,
            promptTitle:
                l.pick('आज का छोटा अभ्यास', 'A small practice for today'),
            prompt: sections.spiritual.promptHi.isNotEmpty
                ? l.pick(
                    sections.spiritual.promptHi, sections.spiritual.promptEn)
                : _practice(sections.spiritual.id, l)),
        const SizedBox(height: 26),
        _section(context, Icons.psychology_outlined,
            l.pick('नैतिकता और जीवन-दर्शन', 'Morality & philosophy')),
        const SizedBox(height: 4),
        Text(
            l.pick('एक विचार, जो दिन को दिशा दे', 'A thought to guide the day'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        _DiscoveryCard(
            entry: sections.philosophy,
            language: widget.language,
            promptTitle: l.pick('खुद से पूछें', 'Ask yourself'),
            prompt: sections.philosophy.promptHi.isNotEmpty
                ? l.pick(
                    sections.philosophy.promptHi, sections.philosophy.promptEn)
                : _reflection(sections.philosophy.id, l)),
        const SizedBox(height: 26),
        _section(context, Icons.history_edu_outlined,
            l.pick('आज की जानकारी', 'Today’s facts')),
        const SizedBox(height: 4),
        Text(
            sections.anniversary
                ? l.pick('आज के दिन इतिहास में', 'On this date in history')
                : l.pick('आज जानिए • संस्कृति और विरासत',
                    'Discover today • Culture and heritage'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant)),
        const SizedBox(height: 10),
        _DiscoveryCard(entry: sections.fact, language: widget.language),
      ],
    );
  }

  String _practice(String id, L10n l) => switch (id) {
        'gita-return' => l.pick(
            'दो मिनट शांत बैठें। मन भटके तो बिना झुंझलाए ध्यान वापस लाएँ।',
            'Sit quietly for two minutes. When your mind wanders, gently bring your attention back.'),
        'gita-offering-work' => l.pick(
            'आज एक छोटा काम पूरे मन से करें और उसे ईश्वर को अर्पित करने का भाव रखें।',
            'Do one small task wholeheartedly today, with the intention of offering it to the divine.'),
        'yoga' => l.pick(
            'कुछ क्षण आराम से बैठकर अपनी सामान्य साँस पर ध्यान दें।',
            'Sit comfortably for a few moments and notice your natural breathing.'),
        _ => l.pick(
            'इस पाठ के भाव पर दो मिनट मनन करें। अपनी परंपरा के अनुसार प्रार्थना या ईश्वर-स्मरण के लिए एक शांत क्षण रखें।',
            'Reflect on this reading for two minutes. Make a quiet moment for prayer or remembrance in your own tradition.'),
      };

  String _reflection(String id, L10n l) => switch (id) {
        'gita-compassion' => l.pick(
            'आज किसके साथ थोड़ा अधिक धैर्य और दया रख सकते हैं?',
            'Who could you treat with a little more patience and kindness today?'),
        'gita-speech' => l.pick(
            'क्या मेरी बात सच्ची होने के साथ हितकारी भी है?',
            'Are my words helpful as well as truthful?'),
        'gita-charity' => l.pick(
            'आज बिना बदले की अपेक्षा किसकी मदद कर सकते हैं?',
            'Whom could you help today without expecting anything in return?'),
        'gita-peace' => l.pick(
            'किस परिणाम की चिंता छोड़कर अपने प्रयास पर ध्यान दे सकते हैं?',
            'Which outcome could you stop worrying about and focus on your effort instead?'),
        'gita-balance' => l.pick(
            'आज काम और विश्राम में थोड़ा बेहतर संतुलन कैसे बनाएँ?',
            'How could you balance work and rest a little better today?'),
        'gita-respect' => l.pick(
            'आज किसी से असहमति होने पर भी सम्मान कैसे बनाए रखें?',
            'How could you show respect today, even when you disagree?'),
        'gita-mind' => l.pick(
            'मन को शांत करने के लिए आज कौन-सी छोटी आदत अपना सकते हैं?',
            'What small habit could help you keep a calmer mind today?'),
        _ => l.pick('आज अपने मन को मित्र बनाने वाला कौन-सा कदम उठा सकते हैं?',
            'What step could you take today to make your mind a friend?'),
      };

  Widget _section(BuildContext context, IconData icon, String title) => Row(
        children: [
          Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
}

class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard(
      {required this.entry,
      required this.language,
      this.promptTitle,
      this.prompt});
  final String? promptTitle, prompt;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.year != null) ...[
              Text(
                '${entry.year}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (entry.teacherHi.isNotEmpty) ...[
              Text(l.pick(entry.teacherHi, entry.teacherEn),
                  style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      height: 1.5)),
              const SizedBox(height: 8),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (entry.reference.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                  '${entry.reference} · ${entry.kind == 'story' ? l.pick('कथा-सार', 'Story retelling') : l.pick('भावार्थ', 'Paraphrase')}',
                  style: theme.textTheme.bodySmall?.copyWith(height: 1.5)),
            ],
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
            if (prompt != null) ...[
              const SizedBox(height: 14),
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(85),
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(promptTitle!,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 5),
                        Text(prompt!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.5)),
                      ])),
            ],
            if (prompt != null) const SizedBox(height: 12),
            Text(entry.source, style: theme.textTheme.bodySmall),
            const Divider(),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: () => _openSource(context),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(l.pick('स्रोत पढ़ें', 'Read source')),
                ),
                IconButton(
                  tooltip: l.pick('पाठ कॉपी करें', 'Copy reading'),
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '$title\n${l.pick(entry.teacherHi, entry.teacherEn)}\n${entry.reference}\n\n$body${prompt == null ? '' : '\n\n$promptTitle: $prompt'}\n\n${entry.source}: ${entry.url}',
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l.pick('पाठ कॉपी हो गया', 'Reading copied'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSource(BuildContext context) async {
    final l = L10n(language);
    try {
      if (await launchUrl(
        Uri.parse(entry.url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {
      // Preserve access to the citation when a browser cannot be opened.
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.pick('स्रोत का लिंक', 'Source link')),
        content: SelectableText(entry.url),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.pick('बंद करें', 'Close')),
          ),
        ],
      ),
    );
  }
}
