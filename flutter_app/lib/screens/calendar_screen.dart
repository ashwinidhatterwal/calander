import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/localization.dart';
import '../core/locations.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';
import 'day_details_screen.dart';
import 'personal_event_editor_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.panchang,
    required this.festival,
    required this.language,
    required this.location,
    required this.personalEvents,
    required this.onUpsertPersonalEvent,
    required this.onLanguageChanged,
    required this.onLocationChanged,
  });

  final PanchangEngine panchang;
  final FestivalEngine festival;
  final AppLanguage language;
  final GeoLocation location;
  final List<PersonalEvent> personalEvents;
  final ValueChanged<PersonalEvent> onUpsertPersonalEvent;
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

  final Map<String, _CalendarCellData> _cellCache = {};
  double _monthDragDx = 0;

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
      _cellCache.clear();
    }
  }

  void _ensureFutures() {
    final dayKey = '${selectedDate.toIso8601String()}|${widget.location.id}';
    if (_futureKey != dayKey) {
      _futureKey = dayKey;
      selectedFuture = Future<PanchangDay>.sync(
        () => widget.panchang.buildDay(selectedDate, widget.location),
      );
    }

    final majorKey = '${visibleMonth.year}|${widget.location.id}';
    if (_majorKey != majorKey) {
      _majorKey = majorKey;
      majorFuture = Future<List<FestivalObservance>>.sync(
        () => widget.festival.majorFestivalsForYear(
          visibleMonth.year,
          widget.location,
        ),
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
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
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
              IconButton(
                tooltip: l.pick('कार्यक्रम जोड़ें', 'Add event'),
                onPressed: _addPersonalEvent,
                icon: const Icon(Icons.add_circle_outline),
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
            selectedDate: selectedDate,
            onTap: () => _openDay(selectedDate),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: _monthPanel(l)),
      ],
    );
  }

  Widget _monthPanel(L10n l) {
    final resistedOffset = (_monthDragDx * 0.16).clamp(-18.0, 18.0).toDouble();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        setState(() {
          _monthDragDx = (_monthDragDx + details.delta.dx).clamp(-120.0, 120.0).toDouble();
        });
      },
      onHorizontalDragCancel: () => setState(() => _monthDragDx = 0),
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        final shouldMove = _monthDragDx.abs() >= 58 || velocity.abs() >= 650;
        final direction = _monthDragDx < 0 || velocity < -650 ? 1 : -1;
        setState(() => _monthDragDx = 0);
        if (shouldMove) {
          HapticFeedback.selectionClick();
          _moveMonth(direction);
        }
      },
      child: AnimatedContainer(
        duration: _monthDragDx == 0 ? const Duration(milliseconds: 180) : Duration.zero,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(resistedOffset, 0, 0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _moveMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
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
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pickMonthYear,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$month ${visibleMonth.year}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                  ],
                                ),
                                Text(
                                  '${snap.data?.adhikMonth == true ? '${l.adhik} ' : ''}$hinduMonth ${l.month}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    onPressed: () => _moveMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                  TextButton(onPressed: _goToday, child: Text(l.today)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  for (final w in (widget.language == AppLanguage.hi ? shortWeekHi : shortWeekEn))
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          child: Text(
                            w,
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
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
        ),
      ),
    );
  }

  Widget _calendarGrid(List<FestivalObservance> major) {
    final first = DateTime.utc(visibleMonth.year, visibleMonth.month, 1);
    final offset = first.weekday % 7;
    final start = first.subtract(Duration(days: offset));
    final now = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: .62,
        mainAxisSpacing: 6,
        crossAxisSpacing: 5,
      ),
      itemCount: 42,
      itemBuilder: (context, i) {
        final d = start.add(Duration(days: i));
        final inside = d.month == visibleMonth.month;
        final cell = _cellData(d);
        final majorEvents = major.where((x) => _sameDate(x.localDate, d)).toList();
        final personalForDay = widget.personalEvents
            .where((event) => _personalEventMatches(event, d, cell))
            .toList(growable: false);
        final eventLabel = _eventLabel(cell, majorEvents, personalForDay);
        final personalOnly = majorEvents.isEmpty && personalForDay.isNotEmpty;
        final isSelected = _sameDate(d, selectedDate);
        final isToday = d.year == now.year && d.month == now.month && d.day == now.day;

        final scheme = Theme.of(context).colorScheme;
        final normalText = scheme.onSurface;
        final mutedText = normalText.withAlpha(80);
        final normalSub = scheme.onSurfaceVariant;
        final mutedSub = normalSub.withAlpha(70);

        Color background;
        if (isSelected) {
          background = scheme.primaryContainer;
        } else if (isToday) {
          background = scheme.secondaryContainer.withAlpha(150);
        } else if (inside) {
          background = scheme.surfaceContainerLow.withAlpha(125);
        } else {
          background = Colors.transparent;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(13),
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
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(3, 6, 3, 5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isToday
                    ? scheme.primary.withAlpha(150)
                    : (inside
                        ? scheme.outlineVariant.withAlpha(65)
                        : Colors.transparent),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  '${d.day}',
                  style: TextStyle(
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: inside ? normalText : mutedText,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.language == AppLanguage.hi
                      ? cell.tithi.value.hi
                      : cell.tithi.value.en,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.05,
                    fontWeight: FontWeight.w500,
                    color: inside ? normalSub : mutedSub,
                  ),
                ),
                const Spacer(),
                if (eventLabel != null && inside)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                    decoration: BoxDecoration(
                      color: majorEvents.isNotEmpty
                          ? scheme.primaryContainer.withAlpha(190)
                          : personalOnly
                              ? scheme.secondaryContainer.withAlpha(190)
                              : scheme.tertiaryContainer.withAlpha(170),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(
                      eventLabel,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 8.3,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: majorEvents.isNotEmpty
                            ? scheme.onPrimaryContainer
                            : personalOnly
                                ? scheme.onSecondaryContainer
                                : scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  _CalendarCellData _cellData(DateTime d) {
    final key = '${d.year}-${d.month}-${d.day}|${widget.location.id}';
    final cached = _cellCache[key];
    if (cached != null) return cached;

    final value = widget.panchang.monthCell(d, widget.location);
    final rawIndex = value.pakshaHi.startsWith('शुक्ल')
        ? value.tithi.index
        : value.tithi.index + 15;
    final cell = _CalendarCellData(
      TithiState(value.tithi, value.pakshaHi, value.pakshaEn, rawIndex),
      value.pakshaHi,
      value.pakshaEn,
      value.month,
      value.adhik,
    );
    _cellCache[key] = cell;

    if (_cellCache.length > 160) {
      final keep = _cellCache.entries.toList().reversed.take(100).toList().reversed;
      _cellCache
        ..clear()
        ..addEntries(keep);
    }
    return cell;
  }

  String? _eventLabel(
    _CalendarCellData cell,
    List<FestivalObservance> majorEvents,
    List<PersonalEvent> personalEvents,
  ) {
    if (majorEvents.isNotEmpty) {
      return _shortEventName(majorEvents.first);
    }
    if (personalEvents.isNotEmpty) {
      return personalEvents.first.title;
    }
    if (cell.tithi.value.index == 11) {
      return widget.language == AppLanguage.hi ? 'एकादशी' : 'Ekadashi';
    }
    if (cell.tithi.rawIndex == 15) {
      return widget.language == AppLanguage.hi ? 'पूर्णिमा' : 'Purnima';
    }
    if (cell.tithi.rawIndex == 30) {
      return widget.language == AppLanguage.hi ? 'अमावस्या' : 'Amavasya';
    }
    return null;
  }

  bool _personalEventMatches(
    PersonalEvent event,
    DateTime date,
    _CalendarCellData cell,
  ) {
    if (event.basis == PersonalEventBasis.gregorian) {
      if (event.gregorianMonth != date.month || event.gregorianDay != date.day) return false;
      return event.repeatYearly || event.gregorianYear == date.year;
    }
    final isShukla = cell.pakshaHi.startsWith('शुक्ल');
    return event.hinduMonth == cell.month.index &&
        event.hinduTithi == cell.tithi.value.index &&
        event.adhikMonth == cell.adhik &&
        (event.hinduPaksha == PersonalEventPaksha.shukla) == isShukla;
  }

  String _shortEventName(FestivalObservance event) {
    const hi = <String, String>{
      'maha_shivaratri': 'शिवरात्रि',
      'holika_dahan': 'होलिका',
      'holi': 'होली',
      'rama_navami': 'राम नवमी',
      'raksha_bandhan': 'राखी',
      'janmashtami': 'जन्माष्टमी',
      'ganesh_chaturthi': 'गणेश चतुर्थी',
      'shardiya_navratri': 'नवरात्रि',
      'vijayadashami': 'दशहरा',
      'karwa_chauth': 'करवा चौथ',
      'dhanteras': 'धनतेरस',
      'diwali': 'दीपावली',
      'govardhan_puja': 'गोवर्धन',
      'bhai_dooj': 'भाई दूज',
    };
    const en = <String, String>{
      'maha_shivaratri': 'Shivaratri',
      'holika_dahan': 'Holika',
      'holi': 'Holi',
      'rama_navami': 'Ram Navami',
      'raksha_bandhan': 'Rakhi',
      'janmashtami': 'Janmashtami',
      'ganesh_chaturthi': 'Ganesh Ch.',
      'shardiya_navratri': 'Navratri',
      'vijayadashami': 'Dussehra',
      'karwa_chauth': 'Karwa Chauth',
      'dhanteras': 'Dhanteras',
      'diwali': 'Diwali',
      'govardhan_puja': 'Govardhan',
      'bhai_dooj': 'Bhai Dooj',
    };
    return widget.language == AppLanguage.hi
        ? (hi[event.id] ?? event.nameHi)
        : (en[event.id] ?? event.nameEn);
  }

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _pickMonthYear() async {
    var year = visibleMonth.year;
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final monthNames = widget.language == AppLanguage.hi ? monthNamesHi : monthNamesEn;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.language == AppLanguage.hi ? 'महीना और वर्ष चुनें' : 'Choose month and year',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          tooltip: widget.language == AppLanguage.hi ? 'आज' : 'Today',
                          onPressed: () {
                            final now = DateTime.now();
                            Navigator.pop(context, DateTime.utc(now.year, now.month, 1));
                          },
                          icon: const Icon(Icons.today_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: year > 1900 ? () => setSheetState(() => year--) : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: year,
                                isExpanded: true,
                                alignment: Alignment.center,
                                items: [
                                  for (var y = 1900; y <= 2100; y++)
                                    DropdownMenuItem(value: y, child: Center(child: Text('$y'))),
                                ],
                                onChanged: (value) {
                                  if (value != null) setSheetState(() => year = value);
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: year < 2100 ? () => setSheetState(() => year++) : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, i) {
                        final active = i + 1 == visibleMonth.month && year == visibleMonth.year;
                        return FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            backgroundColor: active ? Theme.of(context).colorScheme.primaryContainer : null,
                          ),
                          onPressed: () => Navigator.pop(context, DateTime.utc(year, i + 1, 1)),
                          child: Text(monthNames[i], textAlign: TextAlign.center),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (selected == null) return;
    setState(() {
      visibleMonth = selected;
      selectedDate = selected;
      _futureKey = null;
      _majorKey = null;
      _monthDragDx = 0;
    });
  }

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
              subtitle: Text(
                widget.language == AppLanguage.hi ? x.stateHi : x.stateEn,
              ),
              trailing: x.id == widget.location.id
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, x),
            ),
        ],
      ),
    );
    if (choice != null) widget.onLocationChanged(choice);
  }

  Future<void> _addPersonalEvent() async {
    final result = await Navigator.of(context).push<PersonalEvent>(
      MaterialPageRoute(
        builder: (_) => PersonalEventEditorScreen(
          language: widget.language,
          location: widget.location,
          panchang: widget.panchang,
          initialDate: selectedDate,
        ),
      ),
    );
    if (result != null) widget.onUpsertPersonalEvent(result);
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
          personalEvents: widget.personalEvents,
        ),
      ),
    );
  }
}

class _CalendarCellData {
  const _CalendarCellData(this.tithi, this.pakshaHi, this.pakshaEn, this.month, this.adhik);
  final TithiState tithi;
  final String pakshaHi;
  final String pakshaEn;
  final NamedValue month;
  final bool adhik;
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.day,
    required this.l,
    required this.panchang,
    required this.location,
    required this.selectedDate,
    required this.onTap,
  });

  final PanchangDay? day;
  final L10n l;
  final PanchangEngine panchang;
  final GeoLocation location;
  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
    final title = isToday
        ? l.today
        : '${selectedDate.day} ${l.language == AppLanguage.hi ? monthNamesHi[selectedDate.month - 1] : monthNamesEn[selectedDate.month - 1]}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: day == null
                ? const SizedBox(
                    height: 70,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title · ${l.pick(day!.weekdayHi, day!.weekdayEn)}',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${l.pick(day!.pakshaHi, day!.pakshaEn)} ${l.pick(day!.tithi.hi, day!.tithi.en)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${day!.adhikMonth ? '${l.adhik} ' : ''}${l.pick(day!.purnimantaMonth.hi, day!.purnimantaMonth.en)} ${l.month}',
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${l.sunrise} ${panchang.hhmm(day!.sunriseUtc, location)}',
                          ),
                          Text(
                            '${l.sunset} ${panchang.hhmm(day!.sunsetUtc, location)}',
                          ),
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
