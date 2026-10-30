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
  int _more = 3;
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
    engine
        .majorFestivalsAsync(date.year, location)
        .then((major) {
          if (!mounted || request != _request) return;
          setState(() {
            _festivals = engine
                .lightweightForDate(date, location, major: major)
                .map((e) => e.id)
                .toSet();
            _loading = false;
          });
        })
        .catchError((Object _) {
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
        _more = 3;
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
    final events = DailyDiscoveries.onThisDay(_date);
    final location = widget.location;
    final cell = location == null
        ? null
        : const PanchangEngine().monthCell(_date, location);
    final rawTithi = cell == null
        ? 0
        : cell.tithi.index + (cell.pakshaEn == 'Krishna Paksha' ? 15 : 0);
    final selected = DailyDiscoveries.select(
      date: _date,
      hinduMonth: cell?.month.index ?? 0,
      rawTithi: rawTithi,
      adhik: cell?.adhik ?? false,
      festivals: _festivals,
    );
    final general = selected.where((e) => e.reason == 'general').toList();
    if (general.isNotEmpty && selected.length > 2) {
      final item = general.first;
      selected.remove(item);
      selected.insert(2, item);
    }
    String reason(String value) => switch (value) {
      'festival' => l.pick('आज का पर्व', 'Today’s observance'),
      'tithi' => l.pick('आज की तिथि से जुड़ा पाठ', 'Reading for today’s tithi'),
      'month' => l.pick('इस हिंदू मास की परंपरा', 'This Hindu month'),
      _ => l.pick('भक्ति, संस्कृति और सीख', 'Faith, culture and wisdom'),
    };

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
            'आस्था • परंपरा • जीवन की सीख',
            'Faith • Tradition • Everyday wisdom',
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
        const SizedBox(height: 20),
        _section(
          context,
          Icons.temple_hindu_outlined,
          l.pick('आज का मनन', 'Today’s reading'),
        ),
        const SizedBox(height: 10),
        for (final item in selected.take(_more)) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              reason(item.reason),
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.primary,
              ),
            ),
          ),
          _DiscoveryCard(entry: item.entry, language: widget.language),
          const SizedBox(height: 18),
        ],
        if (_more < selected.length)
          OutlinedButton.icon(
            onPressed: () => setState(() => _more += 5),
            icon: const Icon(Icons.auto_stories_outlined),
            label: Text(l.pick('और पढ़ें', 'Read more')),
          ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: 24),
          _section(
            context,
            Icons.history_edu,
            l.pick('आज के दिन', 'On this day'),
          ),
          const SizedBox(height: 10),
          for (final entry in events) ...[
            _DiscoveryCard(entry: entry, language: widget.language),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 14),
        Text(
          l.pick(
            'पहले पर्व और तिथि, फिर हिंदू मास, फिर अन्य प्रेरक पाठ। कथाएँ और मान्यताएँ संबंधित परंपरा के रूप में प्रस्तुत हैं; परिवार और क्षेत्र की विधियाँ भिन्न हो सकती हैं।',
            'Readings prioritise observances and tithi, then Hindu month, then general inspiration. Sacred narratives and beliefs are presented as traditions; regional and family customs vary.',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _section(BuildContext context, IconData icon, String title) => Row(
    children: [
      Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.pick(
                entry.isDated
                    ? 'इतिहास'
                    : entry.kind == 'teaching'
                    ? 'शास्त्र से सीख'
                    : entry.kind == 'story'
                    ? 'धार्मिक कथा'
                    : 'परंपरा और संस्कृति',
                entry.isDated
                    ? 'History'
                    : entry.kind == 'teaching'
                    ? 'Scriptural reflection'
                    : entry.kind == 'story'
                    ? 'Sacred narrative'
                    : 'Tradition and culture',
              ),
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
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
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 12),
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
                  tooltip: l.pick('जानकारी कॉपी करें', 'Copy this fact'),
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text:
                            '$title\n\n$body\n\n${entry.source}: ${entry.url}',
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l.pick('जानकारी कॉपी हो गई', 'Fact copied'),
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
