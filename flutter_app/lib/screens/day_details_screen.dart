import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';

class DayDetailsScreen extends StatefulWidget {
  const DayDetailsScreen({
    super.key,
    required this.date,
    required this.panchang,
    required this.festival,
    required this.language,
    required this.location,
  });

  final DateTime date;
  final PanchangEngine panchang;
  final FestivalEngine festival;
  final AppLanguage language;
  final GeoLocation location;

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
    future = Future<_DayBundle>(() {
      final day = widget.panchang.buildDay(date, widget.location);
      final major = widget.festival.majorFestivalsForYear(date.year, widget.location);
      final events = widget.festival.lightweightForDate(
        date,
        widget.location,
        major: major,
      );
      return _DayBundle(day, events);
    });
  }

  void _move(int deltaDays) {
    setState(() {
      date = date.add(Duration(days: deltaDays));
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n(widget.language);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.dayDetails),
        actions: [
          IconButton(onPressed: () => _move(-1), icon: const Icon(Icons.chevron_left)),
          IconButton(onPressed: () => _move(1), icon: const Icon(Icons.chevron_right)),
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
              if (bundle.events.isNotEmpty)
                _InfoCard(
                  title: l.pick('आज का पर्व / व्रत', 'Festival / observance'),
                  icon: Icons.celebration_outlined,
                  children: [
                    for (final event in bundle.events)
                      _ValueRow(
                        label: event.category == 'vrat' ? l.pick('व्रत', 'Vrat') : l.festivals,
                        value: l.pick(event.nameHi, event.nameEn),
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
                  _ValueRow(label: l.tithi, value: '${l.pick(p.pakshaHi, p.pakshaEn)} ${l.pick(p.tithi.hi, p.tithi.en)}'),
                  _ValueRow(label: l.pick('तिथि समाप्त', 'Tithi ends'), value: widget.panchang.hhmm(p.tithiEndUtc, widget.location)),
                  _ValueRow(label: l.pick('अगली तिथि', 'Next Tithi'), value: l.pick(p.nextTithi.hi, p.nextTithi.en)),
                  _ValueRow(label: l.month, value: '${p.adhikMonth ? '${l.adhik} ' : ''}${l.pick(p.purnimantaMonth.hi, p.purnimantaMonth.en)}'),
                  _ValueRow(label: l.nakshatra, value: '${l.pick(p.nakshatra.hi, p.nakshatra.en)} · ${widget.panchang.hhmm(p.nakshatraEndUtc, widget.location)}'),
                  _ValueRow(label: l.yoga, value: '${l.pick(p.yoga.hi, p.yoga.en)} · ${widget.panchang.hhmm(p.yogaEndUtc, widget.location)}'),
                  _ValueRow(label: l.karana, value: '${l.pick(p.karana.hi, p.karana.en)} · ${widget.panchang.hhmm(p.karanaEndUtc, widget.location)}'),
                  if (p.tithiStatus == 'kshaya')
                    _ValueRow(label: l.kshayaTithi, value: l.pick(p.skippedTithi?.hi ?? '—', p.skippedTithi?.en ?? '—')),
                  if (p.tithiStatus == 'vriddhi')
                    _ValueRow(label: l.vriddhiTithi, value: l.pick('यह तिथि दो सूर्योदय पर रहती है', 'This Tithi spans two sunrises')),
                  if (p.kshayaMonthAfter != null)
                    _ValueRow(label: l.pick('क्षय मास', 'Kshaya Maas'), value: l.pick(p.kshayaMonthAfter!.hi, p.kshayaMonthAfter!.en)),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.sunMoon,
                icon: Icons.wb_sunny_outlined,
                children: [
                  _ValueRow(label: l.sunrise, value: widget.panchang.hhmm(p.sunriseUtc, widget.location)),
                  _ValueRow(label: l.sunset, value: widget.panchang.hhmm(p.sunsetUtc, widget.location)),
                  _ValueRow(label: l.moonrise, value: widget.panchang.hhmm(p.moonriseUtc, widget.location)),
                  _ValueRow(label: l.moonset, value: widget.panchang.hhmm(p.moonsetUtc, widget.location)),
                  _ValueRow(label: l.pick('सूर्य राशि', 'Sun Rashi'), value: l.pick(p.sunRashi.hi, p.sunRashi.en)),
                  _ValueRow(label: l.pick('चंद्र राशि', 'Moon Rashi'), value: l.pick(p.moonRashi.hi, p.moonRashi.en)),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.auspicious,
                icon: Icons.light_mode_outlined,
                children: [
                  _ValueRow(label: l.abhijit, value: widget.panchang.range(p.abhijit, widget.location)),
                  _ValueRow(label: l.brahma, value: widget.panchang.range(p.brahmaMuhurta, widget.location)),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.caution,
                icon: Icons.schedule_outlined,
                children: [
                  _ValueRow(label: l.rahu, value: widget.panchang.range(p.rahuKalam, widget.location)),
                  _ValueRow(label: l.yamaganda, value: widget.panchang.range(p.yamaganda, widget.location)),
                  _ValueRow(label: l.gulika, value: widget.panchang.range(p.gulika, widget.location)),
                ],
              ),
              const SizedBox(height: 12),
              _InfoCard(
                title: l.samvat,
                icon: Icons.history_outlined,
                children: [
                  _ValueRow(label: l.pick('विक्रम संवत', 'Vikram Samvat'), value: '${p.vikramSamvat}'),
                  _ValueRow(label: l.pick('शक संवत', 'Shaka Samvat'), value: '${p.shakaSamvat}'),
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
  const _DayBundle(this.day, this.events);
  final PanchangDay day;
  final List<FestivalObservance> events;
}

class _Header extends StatelessWidget {
  const _Header({required this.p, required this.l, required this.language});
  final PanchangDay p;
  final L10n l;
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final month = language == AppLanguage.hi ? monthNamesHi[p.localDate.month - 1] : monthNamesEn[p.localDate.month - 1];
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.pick(p.weekdayHi, p.weekdayEn), style: Theme.of(context).textTheme.labelLarge),
          Text('${p.localDate.day} $month ${p.localDate.year}', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('${l.pick(p.purnimantaMonth.hi, p.purnimantaMonth.en)} · ${l.pick(p.pakshaHi, p.pakshaEn)} ${l.pick(p.tithi.hi, p.tithi.en)}', style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))]),
            const SizedBox(height: 12),
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
          Expanded(child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
