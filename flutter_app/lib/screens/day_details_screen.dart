import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';

class DayDetailsScreen extends StatefulWidget {
  const DayDetailsScreen({
    super.key,
    required this.date,
    required this.panchang,
    required this.festival,
    required this.language,
    required this.location,
    this.personalEvents = const [],
  });

  final DateTime date;
  final PanchangEngine panchang;
  final FestivalEngine festival;
  final AppLanguage language;
  final GeoLocation location;
  final List<PersonalEvent> personalEvents;

  @override
  State<DayDetailsScreen> createState() => _DayDetailsScreenState();
}

class _DayDetailsScreenState extends State<DayDetailsScreen> {
  late DateTime date;
  late Future<_DayBundle> future;

  @override
  void initState() {
    super.initState();
    date = widget.date;
    _load();
  }

  void _load() {
    future = Future<_DayBundle>.sync(() {
      final day = widget.panchang.buildDay(date, widget.location);
      final major = widget.festival.majorFestivalsForYear(date.year, widget.location);
      final events = widget.festival.lightweightForDate(
        date,
        widget.location,
        major: major,
      );
      final personal = PersonalEventMatcher(widget.panchang)
          .eventsOnDate(widget.personalEvents, date, widget.location);
      return _DayBundle(day, events, personal);
    });
  }

  void _move(int deltaDays) {
    setState(() {
      date = date.add(Duration(days: deltaDays));
      _load();
    });
  }

  String _until(DateTime utc) {
    final l = L10n(widget.language);
    final local = utc.add(widget.location.offset);
    final shown = DateTime.utc(date.year, date.month, date.day);
    final target = DateTime.utc(local.year, local.month, local.day);
    final delta = target.difference(shown).inDays;

    String prefix;
    if (delta == 0) {
      prefix = l.pick('आज', 'Today');
    } else if (delta == 1) {
      prefix = l.pick('अगले दिन', 'Next day');
    } else {
      final month = widget.language == AppLanguage.hi
          ? monthNamesHi[local.month - 1]
          : monthNamesEn[local.month - 1];
      prefix = '${local.day} $month';
    }

    if (widget.language == AppLanguage.en) {
      final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
      final minute = local.minute.toString().padLeft(2, '0');
      final suffix = local.hour < 12 ? 'AM' : 'PM';
      return '$prefix $hour:$minute $suffix';
    }

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final dayPart = local.hour < 4
        ? 'रात'
        : local.hour < 12
            ? 'सुबह'
            : local.hour < 17
                ? 'दोपहर'
                : local.hour < 20
                    ? 'शाम'
                    : 'रात';
    return '$prefix $dayPart $hour:$minute बजे';
  }

  String _festivalNote(FestivalObservance event) {
    if (widget.language == AppLanguage.en) {
      if (event.id == 'janmashtami') {
        return 'This date follows the commonly used North Indian Panchang method. Some Vaishnava traditions may observe Janmashtami differently.';
      }
      if (event.id == 'holika_dahan') {
        return 'Holika Dahan can depend on detailed Bhadra and Pradosha rules, so some traditions may show a different observance date.';
      }
      return event.notesEn ?? '';
    }

    if (event.id == 'janmashtami') {
      return 'यह तिथि उत्तर भारत में प्रचलित पंचांग पद्धति के अनुसार है। कुछ वैष्णव परंपराओं में जन्माष्टमी की तिथि अलग हो सकती है।';
    }
    if (event.id == 'holika_dahan') {
      return 'होलिका दहन में भद्रा और प्रदोष जैसे नियम महत्वपूर्ण होते हैं, इसलिए कुछ परंपराओं में तिथि अलग दिखाई दे सकती है।';
    }
    return event.notesHi ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.dayDetails),
        actions: [
          IconButton(
            tooltip: l.pick('पिछला दिन', 'Previous day'),
            onPressed: () => _move(-1),
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: l.pick('अगला दिन', 'Next day'),
            onPressed: () => _move(1),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      body: FutureBuilder<_DayBundle>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final bundle = snap.data!;
          final p = bundle.day;
          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 32),
            children: [
              _Header(p: p, l: l, language: widget.language),
              const SizedBox(height: 12),
              if (bundle.personalEvents.isNotEmpty) ...[
                _InfoCard(
                  title: l.myDays,
                  icon: Icons.event_repeat_outlined,
                  emphasized: true,
                  compact: true,
                  children: [
                    for (final event in bundle.personalEvents)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bookmark_outline),
                        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                        subtitle: event.note.isEmpty ? null : Text(event.note),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (bundle.events.isNotEmpty)
                _InfoCard(
                  title: l.pick('आज का पर्व / व्रत', 'Festival / observance'),
                  icon: Icons.celebration_outlined,
                  emphasized: true,
                  compact: true,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final event in bundle.events)
                          Chip(
                            avatar: Icon(
                              event.category == 'vrat'
                                  ? Icons.self_improvement_outlined
                                  : Icons.celebration_outlined,
                              size: 18,
                            ),
                            label: Text(
                              l.pick(event.nameHi, event.nameEn),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                    for (final event in bundle.events)
                      if (_festivalNote(event).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(_festivalNote(event)),
                        ),
                  ],
                )
              else
                _InfoCard(
                  title: l.pick('आज का पर्व', 'Festival'),
                  icon: Icons.celebration_outlined,
                  children: [Text(l.noMajorFestival)],
                ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.panchang,
                icon: Icons.auto_awesome_outlined,
                children: [
                  _ValueRow(
                    label: l.tithi,
                    value:
                        '${l.pick(p.pakshaHi, p.pakshaEn)} ${l.pick(p.tithi.hi, p.tithi.en)}',
                  ),
                  _ValueRow(
                    label: l.pick('तिथि समाप्त', 'Tithi ends'),
                    value: '${_until(p.tithiEndUtc)} ${l.pick('तक', '')}'.trim(),
                  ),
                  _ValueRow(
                    label: l.pick('अगली तिथि', 'Next Tithi'),
                    value: l.pick(p.nextTithi.hi, p.nextTithi.en),
                  ),
                  _ValueRow(
                    label: l.month,
                    value:
                        '${p.adhikMonth ? '${l.adhik} ' : ''}${l.pick(p.purnimantaMonth.hi, p.purnimantaMonth.en)}',
                  ),
                  _ValueRow(
                    label: l.nakshatra,
                    value:
                        '${l.pick(p.nakshatra.hi, p.nakshatra.en)}\n${_until(p.nakshatraEndUtc)} ${l.pick('तक', '')}'.trim(),
                  ),
                  _ValueRow(
                    label: l.yoga,
                    value:
                        '${l.pick(p.yoga.hi, p.yoga.en)}\n${_until(p.yogaEndUtc)} ${l.pick('तक', '')}'.trim(),
                  ),
                  _ValueRow(
                    label: l.karana,
                    value:
                        '${l.pick(p.karana.hi, p.karana.en)}\n${_until(p.karanaEndUtc)} ${l.pick('तक', '')}'.trim(),
                  ),
                  if (p.tithiStatus == 'kshaya')
                    _ValueRow(
                      label: l.kshayaTithi,
                      value: l.pick(
                        p.skippedTithi?.hi ?? '—',
                        p.skippedTithi?.en ?? '—',
                      ),
                    ),
                  if (p.tithiStatus == 'vriddhi')
                    _ValueRow(
                      label: l.vriddhiTithi,
                      value: l.pick(
                        'यह तिथि दो सूर्योदय पर रहती है',
                        'This Tithi spans two sunrises',
                      ),
                    ),
                  if (p.kshayaMonthAfter != null)
                    _ValueRow(
                      label: l.pick('क्षय मास', 'Kshaya Maas'),
                      value: l.pick(
                        p.kshayaMonthAfter!.hi,
                        p.kshayaMonthAfter!.en,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.sunMoon,
                icon: Icons.wb_sunny_outlined,
                children: [
                  _ValueRow(
                    label: l.sunrise,
                    value: widget.panchang.hhmm(p.sunriseUtc, widget.location),
                  ),
                  _ValueRow(
                    label: l.sunset,
                    value: widget.panchang.hhmm(p.sunsetUtc, widget.location),
                  ),
                  _ValueRow(
                    label: l.moonrise,
                    value: widget.panchang.hhmm(p.moonriseUtc, widget.location),
                  ),
                  _ValueRow(
                    label: l.moonset,
                    value: widget.panchang.hhmm(p.moonsetUtc, widget.location),
                  ),
                  _ValueRow(
                    label: l.pick('सूर्य राशि', 'Sun Rashi'),
                    value: l.pick(p.sunRashi.hi, p.sunRashi.en),
                  ),
                  _ValueRow(
                    label: l.pick('चंद्र राशि', 'Moon Rashi'),
                    value: l.pick(p.moonRashi.hi, p.moonRashi.en),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.auspicious,
                icon: Icons.light_mode_outlined,
                children: [
                  _ValueRow(
                    label: l.abhijit,
                    value: widget.panchang.range(p.abhijit, widget.location),
                  ),
                  _ValueRow(
                    label: l.brahma,
                    value: widget.panchang.range(p.brahmaMuhurta, widget.location),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.caution,
                icon: Icons.schedule_outlined,
                children: [
                  _ValueRow(
                    label: l.rahu,
                    value: widget.panchang.range(p.rahuKalam, widget.location),
                  ),
                  _ValueRow(
                    label: l.yamaganda,
                    value: widget.panchang.range(p.yamaganda, widget.location),
                  ),
                  _ValueRow(
                    label: l.gulika,
                    value: widget.panchang.range(p.gulika, widget.location),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.samvat,
                icon: Icons.history_outlined,
                children: [
                  _ValueRow(
                    label: l.pick('विक्रम संवत', 'Vikram Samvat'),
                    value: '${p.vikramSamvat}',
                  ),
                  _ValueRow(
                    label: l.pick('शक संवत', 'Shaka Samvat'),
                    value: '${p.shakaSamvat}',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DayBundle {
  const _DayBundle(this.day, this.events, this.personalEvents);
  final PanchangDay day;
  final List<FestivalObservance> events;
  final List<PersonalEvent> personalEvents;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.p,
    required this.l,
    required this.language,
  });

  final PanchangDay p;
  final L10n l;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final month = language == AppLanguage.hi
        ? monthNamesHi[p.localDate.month - 1]
        : monthNamesEn[p.localDate.month - 1];
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.pick(p.weekdayHi, p.weekdayEn),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Text(
            '${p.localDate.day} $month ${p.localDate.year}',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            '${l.pick(p.purnimantaMonth.hi, p.purnimantaMonth.en)} · ${l.pick(p.pakshaHi, p.pakshaEn)} ${l.pick(p.tithi.hi, p.tithi.en)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
    this.emphasized = false,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: emphasized
          ? Theme.of(context).colorScheme.primaryContainer.withAlpha(80)
          : null,
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
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
            ),
            SizedBox(height: compact ? 7 : 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
