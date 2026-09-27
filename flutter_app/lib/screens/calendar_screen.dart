import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../core/locations.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import 'day_details_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.panchang,
    required this.festival,
    required this.language,
    required this.location,
    required this.onLanguageChanged,
    required this.onLocationChanged,
  });

  final PanchangEngine panchang;
  final FestivalEngine festival;
  final AppLanguage language;
  final GeoLocation location;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<GeoLocation> onLocationChanged;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime visibleMonth;
  late DateTime selectedDate;
  Future<PanchangDay>? selectedFuture;
  Future<List<FestivalObservance>>? majorFuture;
  String? _futureKey;
  String? _majorKey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    selectedDate = DateTime.utc(now.year, now.month, now.day);
    visibleMonth = DateTime.utc(now.year, now.month, 1);
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.id != widget.location.id) {
      _futureKey = null;
      _majorKey = null;
    }
  }

  void _ensureFutures() {
    final dayKey = '${selectedDate.toIso8601String()}|${widget.location.id}';
    if (_futureKey != dayKey) {
      _futureKey = dayKey;
      selectedFuture = Future<PanchangDay>(
        () => widget.panchang.buildDay(selectedDate, widget.location),
      );
    }

    final majorKey = '${visibleMonth.year}|${widget.location.id}';
    if (_majorKey != majorKey) {
      _majorKey = majorKey;
      majorFuture = Future<List<FestivalObservance>>(
        () => widget.festival.majorFestivalsForYear(visibleMonth.year, widget.location),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _ensureFutures();
    final l = L10n(widget.language);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.appName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _pickLocation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: 4),
                            Text(l.pick(widget.location.cityHi, widget.location.cityEn)),
                            const Icon(Icons.expand_more, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<AppLanguage>(
                tooltip: l.languageLabel,
                initialValue: widget.language,
                onSelected: widget.onLanguageChanged,
                itemBuilder: (_) => [
                  PopupMenuItem(value: AppLanguage.hi, child: Text(l.hindi)),
                  PopupMenuItem(value: AppLanguage.en, child: Text(l.english)),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Text(
                    widget.language == AppLanguage.hi ? 'अ' : 'EN',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        FutureBuilder<PanchangDay>(
          future: selectedFuture,
          builder: (context, snap) => _TodayCard(
            day: snap.data,
            l: l,
            panchang: widget.panchang,
            location: widget.location,
            onTap: () => _openDay(selectedDate),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(onPressed: () => _moveMonth(-1), icon: const Icon(Icons.chevron_left)),
              Expanded(
                child: FutureBuilder<PanchangDay>(
                  future: selectedFuture,
                  builder: (context, snap) {
                    final month = widget.language == AppLanguage.hi
                        ? monthNamesHi[visibleMonth.month - 1]
                        : monthNamesEn[visibleMonth.month - 1];
                    final hinduMonth = snap.hasData
                        ? l.pick(snap.data!.purnimantaMonth.hi, snap.data!.purnimantaMonth.en)
                        : '…';
                    return Column(
                      children: [
                        Text(
                          '$month ${visibleMonth.year}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${snap.data?.adhikMonth == true ? '${l.adhik} ' : ''}$hinduMonth ${l.month}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
              IconButton(onPressed: () => _moveMonth(1), icon: const Icon(Icons.chevron_right)),
              TextButton(onPressed: _goToday, child: Text(l.today)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final w in (widget.language == AppLanguage.hi ? shortWeekHi : shortWeekEn))
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(w, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<FestivalObservance>>(
            future: majorFuture,
            builder: (context, snap) => _calendarGrid(snap.data ?? const []),
          ),
        ),
      ],
    );
  }

  Widget _calendarGrid(List<FestivalObservance> major) {
    final first = DateTime.utc(visibleMonth.year, visibleMonth.month, 1);
    final offset = first.weekday % 7;
    final start = first.subtract(Duration(days: offset));
    final now = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 18),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: .72,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: 42,
      itemBuilder: (context, i) {
        final d = start.add(Duration(days: i));
        final inside = d.month == visibleMonth.month;
        final sunrise = widget.panchang.sunriseSunset(d, widget.location)[0];
        final tithi = widget.panchang.tithiAt(sunrise);
        final events = major.where((x) => _sameDate(x.localDate, d)).toList();
        final recurring = tithi.value.index == 11 || tithi.rawIndex == 15 || tithi.rawIndex == 30;
        final isSelected = _sameDate(d, selectedDate);
        final isToday = d.year == now.year && d.month == now.month && d.day == now.day;

        final normalText = Theme.of(context).colorScheme.onSurface;
        final mutedText = normalText.withAlpha(90);
        final normalSub = Theme.of(context).colorScheme.onSurfaceVariant;
        final mutedSub = normalSub.withAlpha(82);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              selectedDate = d;
              visibleMonth = DateTime.utc(d.year, d.month, 1);
              _futureKey = null;
              _majorKey = null;
            });
            _openDay(d);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primaryContainer
                  : (isToday ? Theme.of(context).colorScheme.secondaryContainer.withAlpha(140) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isToday ? Border.all(color: Theme.of(context).colorScheme.primary.withAlpha(128)) : null,
            ),
            child: Column(
              children: [
                Text(
                  '${d.day}',
                  style: TextStyle(fontWeight: FontWeight.w800, color: inside ? normalText : mutedText),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.language == AppLanguage.hi ? tithi.value.hi : tithi.value.en,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, height: 1.1, color: inside ? normalSub : mutedSub),
                ),
                const Spacer(),
                if (events.isNotEmpty || recurring)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: events.isNotEmpty
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  void _moveMonth(int delta) {
    setState(() {
      visibleMonth = DateTime.utc(visibleMonth.year, visibleMonth.month + delta, 1);
      selectedDate = visibleMonth;
      _futureKey = null;
      _majorKey = null;
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      selectedDate = DateTime.utc(now.year, now.month, now.day);
      visibleMonth = DateTime.utc(now.year, now.month, 1);
      _futureKey = null;
      _majorKey = null;
    });
  }

  Future<void> _pickLocation() async {
    final choice = await showModalBottomSheet<GeoLocation>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        children: [
          for (final x in locations)
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title: Text(widget.language == AppLanguage.hi ? x.cityHi : x.cityEn),
              subtitle: Text(widget.language == AppLanguage.hi ? x.stateHi : x.stateEn),
              trailing: x.id == widget.location.id ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, x),
            ),
        ],
      ),
    );
    if (choice != null) widget.onLocationChanged(choice);
  }

  void _openDay(DateTime d) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DayDetailsScreen(
          date: d,
          panchang: widget.panchang,
          festival: widget.festival,
          language: widget.language,
          location: widget.location,
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.day,
    required this.l,
    required this.panchang,
    required this.location,
    required this.onTap,
  });

  final PanchangDay? day;
  final L10n l;
  final PanchangEngine panchang;
  final GeoLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: day == null
                ? const SizedBox(height: 70, child: Center(child: CircularProgressIndicator()))
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${l.today} · ${l.pick(day!.weekdayHi, day!.weekdayEn)}', style: Theme.of(context).textTheme.labelLarge),
                            const SizedBox(height: 6),
                            Text(
                              '${l.pick(day!.pakshaHi, day!.pakshaEn)} ${l.pick(day!.tithi.hi, day!.tithi.en)}',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text('${day!.adhikMonth ? '${l.adhik} ' : ''}${l.pick(day!.purnimantaMonth.hi, day!.purnimantaMonth.en)} ${l.month}'),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${l.sunrise} ${panchang.hhmm(day!.sunriseUtc, location)}'),
                          Text('${l.sunset} ${panchang.hhmm(day!.sunsetUtc, location)}'),
                          const SizedBox(height: 8),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
