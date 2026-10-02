import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';
import 'personal_event_editor_screen.dart';

class MyDaysScreen extends StatefulWidget {
  const MyDaysScreen({
    super.key,
    required this.events,
    required this.language,
    required this.location,
    required this.panchang,
    required this.active,
    required this.onUpsert,
    required this.onDelete,
  });

  final List<PersonalEvent> events;
  final AppLanguage language;
  final GeoLocation location;
  final PanchangEngine panchang;
  final bool active;
  final ValueChanged<PersonalEvent> onUpsert;
  final ValueChanged<String> onDelete;

  @override
  State<MyDaysScreen> createState() => _MyDaysScreenState();
}

class _MyDaysScreenState extends State<MyDaysScreen> {
  Future<List<ResolvedPersonalEvent>>? _future;
  String? _key;

  @override
  void didUpdateWidget(covariant MyDaysScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.events != widget.events ||
        oldWidget.location.cacheKey != widget.location.cacheKey ||
        oldWidget.active != widget.active) {
      _key = null;
    }
  }

  void _ensure() {
    if (!widget.active || widget.events.isEmpty) return;
    final eventSignature = widget.events
        .map((x) => '${x.id}:${x.title}:${x.basis.name}:${x.gregorianYear}:${x.gregorianMonth}:${x.gregorianDay}:${x.hinduMonth}:${x.hinduPaksha?.name}:${x.hinduTithi}:${x.adhikMonth}')
        .join('|');
    final key = '${widget.location.cacheKey}|$eventSignature';
    if (_key == key) return;
    _key = key;
    final now = DateTime.now();
    _future = Future.microtask(
      () => PersonalEventMatcher(widget.panchang).upcoming(
        widget.events,
        DateTime.utc(now.year, now.month, now.day),
        widget.location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _ensure();
    final l = L10n(widget.language);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.myDays,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.pick(
                        'जन्मदिन, पूजा और तिथि के अनुसार आपके निजी दिन',
                        'Birthdays, puja and personal dates that can follow a Hindu Tithi',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: Text(l.pick('जोड़ें', 'Add')),
              ),
            ],
          ),
        ),
        Expanded(child: _body(context, l)),
      ],
    );
  }

  Widget _body(BuildContext context, L10n l) {
    if (widget.events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_repeat_outlined, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                l.pick('अपने महत्वपूर्ण दिन जोड़ें', 'Add the days that matter to you'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l.pick(
                  'कोई कार्यक्रम सामान्य तारीख पर रखिए या उसे हर वर्ष हिन्दू मास, पक्ष और तिथि के अनुसार चलने दीजिए।',
                  'Use a normal calendar date, or let an event follow its Hindu month, Paksha and Tithi every year.',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: Text(l.pick('पहला कार्यक्रम जोड़ें', 'Add first event')),
              ),
            ],
          ),
        ),
      );
    }

    if (!widget.active) return const SizedBox.shrink();
    return FutureBuilder<List<ResolvedPersonalEvent>>(
      future: _future,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final items = snap.data!;
        if (items.isEmpty) {
          return Center(
            child: Text(l.pick('अगले वर्ष तक कोई कार्यक्रम नहीं मिला।', 'No upcoming event found in the next year.')),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 32),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, index) {
            final item = items[index];
            final event = item.event;
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                leading: CircleAvatar(
                  child: Icon(_kindIcon(event.kind), size: 20),
                ),
                title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(_dateLabel(item.date)),
                      _BasisBadge(event: event, language: widget.language),
                    ],
                  ),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') _edit(context, event);
                    if (value == 'delete') _confirmDelete(context, event);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: 'edit', child: Text(l.pick('बदलें', 'Edit'))),
                    PopupMenuItem(value: 'delete', child: Text(l.pick('हटाएँ', 'Delete'))),
                  ],
                ),
                onTap: () => _edit(context, event),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _edit(BuildContext context, [PersonalEvent? event]) async {
    final result = await Navigator.push<PersonalEvent>(
      context,
      MaterialPageRoute(
        builder: (_) => PersonalEventEditorScreen(
          language: widget.language,
          location: widget.location,
          panchang: widget.panchang,
          initial: event,
        ),
      ),
    );
    if (result != null) widget.onUpsert(result);
  }

  Future<void> _confirmDelete(BuildContext context, PersonalEvent event) async {
    final l = L10n(widget.language);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.pick('कार्यक्रम हटाएँ?', 'Delete event?')),
        content: Text(event.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.pick('रद्द करें', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l.pick('हटाएँ', 'Delete'))),
        ],
      ),
    );
    if (yes == true) widget.onDelete(event.id);
  }

  String _dateLabel(DateTime date) {
    final month = widget.language == AppLanguage.hi ? monthNamesHi[date.month - 1] : monthNamesEn[date.month - 1];
    return '${date.day} $month ${date.year}';
  }

  IconData _kindIcon(PersonalEventKind kind) => switch (kind) {
        PersonalEventKind.general => Icons.event_note_outlined,
        PersonalEventKind.birthday => Icons.cake_outlined,
        PersonalEventKind.anniversary => Icons.favorite_border,
        PersonalEventKind.puja => Icons.local_florist_outlined,
        PersonalEventKind.vrat => Icons.self_improvement_outlined,
        PersonalEventKind.family => Icons.family_restroom_outlined,
      };
}

class _BasisBadge extends StatelessWidget {
  const _BasisBadge({required this.event, required this.language});
  final PersonalEvent event;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final hindu = event.basis == PersonalEventBasis.hinduTithi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: hindu
            ? Theme.of(context).colorScheme.tertiaryContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        hindu
            ? (language == AppLanguage.hi ? 'हिन्दू तिथि' : 'Hindu Tithi')
            : (language == AppLanguage.hi ? 'सामान्य तारीख' : 'Normal date'),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
