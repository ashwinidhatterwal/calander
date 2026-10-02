import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_theme.dart';
import '../core/localization.dart';
import '../core/locations.dart';
import '../domain/festival_engine.dart';
import '../domain/civil_holidays.dart';
import '../data/current_location_service.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import '../domain/personal_event.dart';
import 'about_support_screen.dart';
import 'notifications_screen.dart';
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
    required this.themePreference,
    required this.onThemeChanged,
    this.offerCurrentLocation = false,
    this.onRefreshNotifications,
    this.onLocationOfferSeen,
  });

  final Future<void> Function()? onRefreshNotifications;
  final bool offerCurrentLocation;
  final Future<void> Function()? onLocationOfferSeen;
  final PanchangEngine panchang;
  final FestivalEngine festival;
  final AppLanguage language;
  final GeoLocation location;
  final List<PersonalEvent> personalEvents;
  final ValueChanged<PersonalEvent> onUpsertPersonalEvent;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final Future<void> Function(GeoLocation) onLocationChanged;
  final AppThemePreference themePreference;
  final ValueChanged<AppThemePreference> onThemeChanged;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with WidgetsBindingObserver {
  late DateTime visibleMonth;
  DateTime get todayDate {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  Timer? _midnightTimer;
  bool _locating = false;
  Future<PanchangDay>? todayFuture;
  Future<List<FestivalObservance>>? majorFuture;
  String? _futureKey;
  String? _majorKey;

  final Map<String, _CalendarCellData> _cellCache = {};
  double _monthDragDx = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();

    visibleMonth = DateTime.utc(now.year, now.month, 1);
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnight();
    if (widget.offerCurrentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await widget.onLocationOfferSeen?.call();
        if (mounted) _pickLocation();
      });
    }
  }

  void _scheduleMidnight() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    _midnightTimer =
        Timer(DateTime(now.year, now.month, now.day + 1).difference(now), () {
      if (mounted) setState(() => _futureKey = null);
      _scheduleMidnight();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
      _scheduleMidnight();
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.cacheKey != widget.location.cacheKey) {
      _futureKey = null;
      _majorKey = null;
      _cellCache.clear();
    }
  }

  void _ensureFutures() {
    final dayKey = '${todayDate.toIso8601String()}|${widget.location.cacheKey}';
    if (_futureKey != dayKey) {
      _futureKey = dayKey;
      todayFuture = Future<PanchangDay>.sync(
        () => widget.panchang.buildDay(todayDate, widget.location),
      );
    }

    final majorKey = '${visibleMonth.year}|${widget.location.cacheKey}';
    if (_majorKey != majorKey) {
      _majorKey = majorKey;
      majorFuture = widget.festival
          .majorFestivalsAsync(visibleMonth.year, widget.location);
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
                            if (_locating)
                              const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                            else
                              const Icon(Icons.location_on_outlined, size: 16),
                            const SizedBox(width: 4),
                            Flexible(
                                child: Text(
                                    l.pick(widget.location.cityHi,
                                        widget.location.cityEn),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'about') {
                    _openAboutSupport();
                    return;
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NotificationsScreen(
                              language: widget.language,
                              onRefresh: widget.onRefreshNotifications ??
                                  () async {})));
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'notifications',
                      child: Text(l.pick('सूचनाएँ', 'Notifications'))),
                  PopupMenuItem(
                      value: 'about',
                      child: Text(l.pick(
                          'सेटिंग और ऐप के बारे में', 'Settings & About'))),
                ],
              ),
            ],
          ),
        ),
        FutureBuilder<PanchangDay>(
          future: todayFuture,
          builder: (context, snap) => _TodayCard(
            day: snap.data,
            l: l,
            panchang: widget.panchang,
            location: widget.location,
            todayDate: todayDate,
            onTap: () => _openDay(todayDate),
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
          _monthDragDx =
              (_monthDragDx + details.delta.dx).clamp(-120.0, 120.0).toDouble();
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
        duration: _monthDragDx == 0
            ? const Duration(milliseconds: 180)
            : Duration.zero,
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
                      future: todayFuture,
                      builder: (context, snap) {
                        final month = widget.language == AppLanguage.hi
                            ? monthNamesHi[visibleMonth.month - 1]
                            : monthNamesEn[visibleMonth.month - 1];
                        final monthCell = _cellData(visibleMonth);
                        final hinduMonth =
                            l.pick(monthCell.month.hi, monthCell.month.en);
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pickMonthYear,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                        child: Text(
                                      '$month ${visibleMonth.year}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w800),
                                    )),
                                    const SizedBox(width: 3),
                                    const Icon(Icons.arrow_drop_down, size: 20),
                                  ],
                                ),
                                Text(
                                  '${monthCell.adhik ? '${l.adhik} ' : ''}$hinduMonth ${l.month}',
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
                  for (final w in (widget.language == AppLanguage.hi
                      ? shortWeekHi
                      : shortWeekEn))
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
                builder: (context, snap) =>
                    _calendarGrid(snap.data ?? const []),
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
        final majorEvents =
            major.where((x) => _sameDate(x.localDate, d)).toList();
        final personalForDay = widget.personalEvents
            .where((event) => _personalEventMatches(event, d, cell))
            .toList(growable: false);
        final holiday =
            nationalHolidays.where((h) => h.occursOn(d)).firstOrNull;
        final eventLabel = _eventLabel(cell, majorEvents, personalForDay) ??
            (holiday == null
                ? null
                : L10n(widget.language).pick(holiday.nameHi, holiday.nameEn));
        final personalOnly = majorEvents.isEmpty && personalForDay.isNotEmpty;
        final isToday =
            d.year == now.year && d.month == now.month && d.day == now.day;

        final scheme = Theme.of(context).colorScheme;
        final normalText = scheme.onSurface;
        final mutedText = normalText.withAlpha(80);
        final normalSub = scheme.onSurfaceVariant;
        final mutedSub = normalSub.withAlpha(70);

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final tileColor =
            isDark ? const Color(0xFF2D221E) : const Color(0xFFFFF0E7);
        final tileBorder =
            isDark ? const Color(0xFF523E35) : const Color(0xFFE7CFC2);

        Color background;
        if (isToday && inside) {
          background =
              isDark ? const Color(0xFF3A2B22) : const Color(0xFFFFE0CF);
        } else if (inside) {
          background = tileColor;
        } else {
          background = Colors.transparent;
        }

        return InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: () => _openDay(d),
          child: AnimatedContainer(
            key: ValueKey(
                'calendar-cell-${d.year}-${d.month}-${d.day}-${isToday && inside}'),
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.fromLTRB(3, 6, 3, 5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isToday && inside
                    ? scheme.primary.withAlpha(180)
                    : (inside ? tileBorder : Colors.transparent),
                width: isToday && inside ? 1.2 : 0.8,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
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
    final key = '${d.year}-${d.month}-${d.day}|${widget.location.cacheKey}';
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
      final keep =
          _cellCache.entries.toList().reversed.take(100).toList().reversed;
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
      if (event.gregorianMonth != date.month ||
          event.gregorianDay != date.day) {
        return false;
      }
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
            final monthNames =
                widget.language == AppLanguage.hi ? monthNamesHi : monthNamesEn;
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
                            widget.language == AppLanguage.hi
                                ? 'महीना और वर्ष चुनें'
                                : 'Choose month and year',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        IconButton(
                          tooltip: widget.language == AppLanguage.hi
                              ? 'आज'
                              : 'Today',
                          onPressed: () {
                            final now = DateTime.now();
                            Navigator.pop(
                                context, DateTime.utc(now.year, now.month, 1));
                          },
                          icon: const Icon(Icons.today_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                Theme.of(context).colorScheme.outlineVariant),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: year > 1900
                                ? () => setSheetState(() => year--)
                                : null,
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
                                    DropdownMenuItem(
                                        value: y,
                                        child: Center(child: Text('$y'))),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setSheetState(() => year = value);
                                  }
                                },
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: year < 2100
                                ? () => setSheetState(() => year++)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, i) {
                        final active = i + 1 == visibleMonth.month &&
                            year == visibleMonth.year;
                        return FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            backgroundColor: active
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                          ),
                          onPressed: () => Navigator.pop(
                              context, DateTime.utc(year, i + 1, 1)),
                          child:
                              Text(monthNames[i], textAlign: TextAlign.center),
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
    if (selected == null || !mounted) return;
    setState(() {
      visibleMonth = selected;
      _monthDragDx = 0;
    });
  }

  void _moveMonth(int delta) {
    setState(() {
      visibleMonth =
          DateTime.utc(visibleMonth.year, visibleMonth.month + delta, 1);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      visibleMonth = DateTime.utc(now.year, now.month, 1);
    });
  }

  Future<void> _pickLocation() async {
    final choice = await showModalBottomSheet<GeoLocation>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.my_location),
            title: Text(L10n(widget.language)
                .pick('वर्तमान स्थान इस्तेमाल करें', 'Use current location')),
            subtitle: Text(L10n(widget.language).pick(
                'एक बार स्थान लें; फिर ऑफ़लाइन इस्तेमाल करें',
                'Save once, then use offline. Tap again to refresh.')),
            onTap: () {
              Navigator.pop(context);
              _useCurrentLocation();
            },
          ),
          if (widget.location.id == 'current')
            ListTile(
              leading: const Icon(Icons.check),
              title: Text(L10n(widget.language)
                  .pick('सहेजा हुआ वर्तमान स्थान', 'Saved current location')),
              subtitle: Text(L10n(widget.language).pick(
                  '${widget.location.cityHi} · ${widget.location.stateHi}',
                  '${widget.location.cityEn} · ${widget.location.stateEn}')),
            ),
          for (final x in locations)
            ListTile(
              leading: const Icon(Icons.location_city_outlined),
              title:
                  Text(widget.language == AppLanguage.hi ? x.cityHi : x.cityEn),
              subtitle: Text(
                widget.language == AppLanguage.hi ? x.stateHi : x.stateEn,
              ),
              trailing: x.cacheKey == widget.location.cacheKey
                  ? const Icon(Icons.check)
                  : null,
              onTap: () => Navigator.pop(context, x),
            ),
        ],
      ),
    );
    if (choice != null && mounted && !_locating) {
      setState(() => _locating = true);
      try {
        await widget.onLocationChanged(choice);
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n(widget.language).pick(
                'स्थान सहेजा नहीं जा सका। दोबारा कोशिश करें।',
                'Could not save location. Please retry.'))));
      } finally {
        if (mounted) setState(() => _locating = false);
      }
    }
  }

  void _showLocationDiagnostics(String report) {
    final l = L10n(widget.language);
    showDialog<void>(context: context, builder: (context) => AlertDialog(
      title: Text(l.pick('स्थान जाँच', 'Location diagnostics')),
      content: SingleChildScrollView(child: SelectableText(report)),
      actions: [
        TextButton(onPressed: () async {
          await Clipboard.setData(ClipboardData(text: report));
          if (context.mounted) Navigator.pop(context);
        }, child: Text(l.pick('कॉपी करें', 'Copy'))),
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text(l.pick('बंद करें', 'Close'))),
      ],
    ));
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    final l = L10n(widget.language);
    try {
      final value = await const CurrentLocationService().obtain();
      if (!mounted) return;
      try {
        await widget.onLocationChanged(value);
      } catch (error) {
        LocationDiagnostics.error('Save/update failed', error);
        throw const CurrentLocationException('saveFailed');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.pick('स्थान सहेजा गया। गणना IST में है।',
              'Location saved. Calculations use IST.')),
          action: SnackBarAction(label: l.pick('विवरण', 'Details'),
              onPressed: () => _showLocationDiagnostics(LocationDiagnostics.report))));
    } catch (error) {
      LocationDiagnostics.error('Location flow stopped', error);
      if (!mounted) return;
      final code =
          error is CurrentLocationException ? error.code
              : error is TimeoutException ? 'timeout' : 'unavailable';
      final message = switch (code) {
        'noProvider' => l.pick(
            'GPS या नेटवर्क स्थान उपलब्ध नहीं है। फ़ोन का स्थान और सटीक अनुमति जाँचें।',
            'No GPS/network provider is available. Check device location and precise permission.'),
        'provider' => l.pick(
            'फ़ोन की स्थान सेवा ने त्रुटि दी। विवरण देखें या दोबारा कोशिश करें।',
            'The phone location provider returned an error. View details or retry.'),
        'saveFailed' => l.pick(
            'स्थान मिल गया, लेकिन सहेजा नहीं जा सका। दोबारा कोशिश करें।',
            'Location found, but could not be saved. Please retry.'),
        'timeout' => l.pick(
            'फ़ोन से स्थान मिलने में समय लगा। खुली जगह में दोबारा कोशिश करें; सटीक स्थान अनुमति से मदद मिलेगी।',
            'The phone could not get a location fix in time. Retry outdoors; precise location permission can help.'),
        'disabled' => l.pick('फ़ोन का स्थान चालू करें या शहर चुनें।',
            'Turn on device location or choose a city.'),
        'deniedForever' => l.pick(
            'ऐप की सेटिंग में स्थान अनुमति दें या शहर चुनें।',
            'Allow location in app settings or choose a city.'),
        'denied' => l.pick('स्थान अनुमति नहीं मिली। शहर चुन सकते हैं।',
            'Location permission denied. You can choose a city.'),
        _ => l.pick('स्थान नहीं मिला। दोबारा कोशिश करें या शहर चुनें।',
            'Location unavailable. Retry or choose a city.'),
      };
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message),
              duration: const Duration(seconds: 12),
              action: SnackBarAction(label: l.pick('विवरण', 'Details'),
                  onPressed: () => _showLocationDiagnostics(LocationDiagnostics.report))));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _openAboutSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AboutSupportScreen(
          language: widget.language,
          initialTheme: widget.themePreference,
          onThemeChanged: widget.onThemeChanged,
        ),
      ),
    );
  }

  Future<void> _addPersonalEvent() async {
    final result = await Navigator.of(context).push<PersonalEvent>(
      MaterialPageRoute(
        builder: (_) => PersonalEventEditorScreen(
          language: widget.language,
          location: widget.location,
          panchang: widget.panchang,
          initialDate: todayDate,
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
  const _CalendarCellData(
      this.tithi, this.pakshaHi, this.pakshaEn, this.month, this.adhik);
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
    required this.todayDate,
    required this.onTap,
  });

  final PanchangDay? day;
  final L10n l;
  final PanchangEngine panchang;
  final GeoLocation location;
  final DateTime todayDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = todayDate.year == now.year &&
        todayDate.month == now.month &&
        todayDate.day == now.day;
    final title = isToday
        ? l.today
        : '${todayDate.day} ${l.language == AppLanguage.hi ? monthNamesHi[todayDate.month - 1] : monthNamesEn[todayDate.month - 1]}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        key: const ValueKey('today-panchang-card'),
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
                            '${l.sunrise} ${panchang.time12(day!.sunriseUtc, location, amLabel: l.pick('पु.', 'AM'), pmLabel: l.pick('अप.', 'PM'))}',
                          ),
                          Text(
                            '${l.sunset} ${panchang.time12(day!.sunsetUtc, location, amLabel: l.pick('पु.', 'AM'), pmLabel: l.pick('अप.', 'PM'))}',
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
