import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../domain/festival_engine.dart';
import '../domain/festival_descriptions.dart';
import '../domain/civil_holidays.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';
import 'day_details_screen.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({
    super.key,
    required this.festival,
    required this.language,
    required this.location,
    this.personalEvents = const [],
  });

  final FestivalEngine festival;
  final AppLanguage language;
  final GeoLocation location;
  final List<PersonalEvent> personalEvents;

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  int year = DateTime.now().year;
  bool upcomingOnly = true;
  bool showHolidays = false;
  Future<List<FestivalObservance>>? future;
  String? key;

  void _ensure() {
    final k = '$year|${widget.location.cacheKey}';
    if (key != k) {
      key = k;
      future = widget.festival.majorFestivalsAsync(year, widget.location);
    }
  }

  @override
  void didUpdateWidget(covariant FestivalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.cacheKey != widget.location.cacheKey) key = null;
  }

  @override
  Widget build(BuildContext context) {
    _ensure();
    final l = L10n(widget.language);
    final now = DateTime.now();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l.festivals,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  year--;
                  key = null;
                }),
                icon: const Icon(Icons.chevron_left),
              ),
              Text('$year',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              IconButton(
                onPressed: () => setState(() {
                  year++;
                  key = null;
                }),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(children: [
              for (final national in [false, true])
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(right: national ? 0 : 8),
                        child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                backgroundColor:
                                    showHolidays == national
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerLow,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 10)),
                            onPressed: () =>
                                setState(() => showHolidays = national),
                            child: Text(
                                national
                                    ? l.pick('अवकाश', 'Holidays')
                                    : l.pick(
                                        'पर्व / व्रत', 'Festivals & Vrats'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis))))
            ])),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(children: [
              ChoiceChip(
                  label: Text(l.pick('आगामी', 'Upcoming')),
                  selected: upcomingOnly,
                  onSelected: (_) => setState(() => upcomingOnly = true)),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: Text(l.pick('पूरा वर्ष', 'Full year')),
                  selected: !upcomingOnly,
                  onSelected: (_) => setState(() => upcomingOnly = false)),
            ])),
        Expanded(
          child: showHolidays
              ? _holidayList(l, now)
              : FutureBuilder<List<FestivalObservance>>(
                  future: future,
                  builder: (context, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    var items = snap.data!;
                    if (upcomingOnly) {
                      if (year == now.year) {
                        final today =
                            DateTime.utc(now.year, now.month, now.day);
                        items = items
                            .where((f) => !f.localDate.isBefore(today))
                            .toList(growable: false);
                      } else if (year < now.year) {
                        items = const [];
                      }
                    }

                    if (items.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            l.pick(
                              'इस वर्ष के लिए कोई आगामी प्रमुख पर्व नहीं है।',
                              'No upcoming major festivals for this year.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, i) {
                        final f = items[i];
                        final month = widget.language == AppLanguage.hi
                            ? monthNamesHi[f.localDate.month - 1]
                            : monthNamesEn[f.localDate.month - 1];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            dense: true,
                            visualDensity: const VisualDensity(vertical: -1),
                            contentPadding:
                                const EdgeInsets.fromLTRB(14, 6, 10, 6),
                            leading: Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${f.localDate.day}',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            title: Text(
                              l.pick(f.nameHi, f.nameEn),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                                '$month ${f.localDate.year}\n${festivalDescription(f.id, widget.language == AppLanguage.hi)}'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DayDetailsScreen(
                                  date: f.localDate,
                                  panchang: const PanchangEngine(),
                                  festival: widget.festival,
                                  language: widget.language,
                                  location: widget.location,
                                  personalEvents: widget.personalEvents,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _holidayList(L10n l, DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final region =
        holidayRegion(widget.location.stateEn, widget.location.countryCode);
    final items = holidaysForRegion(year, region)
        .where((h) => !upcomingOnly || !h.dateInYear(year).isBefore(today))
        .toList();
    final scope = region == null
        ? l.pick('राज्य की पहचान नहीं हुई: केवल राष्ट्रीय अवकाश। स्थान रीफ़्रेश करें।',
            'State not identified: national holidays only. Refresh location.')
        : year != 2026
            ? l.pick('इस वर्ष की राज्य सूची उपलब्ध नहीं है: केवल राष्ट्रीय अवकाश।',
                'State list unavailable for this year: national holidays only.')
            : l.pick(
                '${widget.location.stateHi.isEmpty ? widget.location.stateEn : widget.location.stateHi} • राष्ट्रीय और स्थानीय अवकाश। राज्य सूची 2026 के लिए है; सरकारी आदेश और चाँद दिखने से तारीख बदल सकती है।',
                '${widget.location.stateEn} • National and local holidays. State dates cover 2026; government orders and moon sightings may change dates.');
    final heading = Padding(
      padding: const EdgeInsets.all(12),
      child: Text(scope,
          textAlign: TextAlign.center),
    );
    return Column(children: [
      heading,
      Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          l.pick('इस वर्ष कोई आगामी अवकाश नहीं है।',
                              'No upcoming holidays for this year / filter.'),
                          textAlign: TextAlign.center)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, i) {
                    final holiday = items[i];
                    final date = holiday.dateInYear(year);
                    final month = (widget.language == AppLanguage.hi
                        ? monthNamesHi
                        : monthNamesEn)[date.month - 1];
                    return Card(
                        child: ListTile(
                            leading: const Icon(Icons.flag_outlined),
                            title: Text(l.pick(holiday.nameHi, holiday.nameEn)),
                            subtitle: Text('${date.day} $month $year')));
                  }))
    ]);
  }
}
