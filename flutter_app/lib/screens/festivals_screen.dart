import 'package:flutter/material.dart';

import '../core/localization.dart';
import '../domain/festival_engine.dart';
import '../domain/models.dart';
import '../domain/panchang_engine.dart';
import 'day_details_screen.dart';

class FestivalsScreen extends StatefulWidget {
  const FestivalsScreen({
    super.key,
    required this.festival,
    required this.language,
    required this.location,
  });

  final FestivalEngine festival;
  final AppLanguage language;
  final GeoLocation location;

  @override
  State<FestivalsScreen> createState() => _FestivalsScreenState();
}

class _FestivalsScreenState extends State<FestivalsScreen> {
  int year = DateTime.now().year;
  bool upcomingOnly = true;
  Future<List<FestivalObservance>>? future;
  String? key;

  void _ensure() {
    final k = '$year|${widget.location.id}';
    if (key != k) {
      key = k;
      future = Future<List<FestivalObservance>>.sync(
        () => widget.festival.majorFestivalsForYear(year, widget.location),
      );
    }
  }

  @override
  void didUpdateWidget(covariant FestivalsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.id != widget.location.id) key = null;
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
              Text('$year', style: const TextStyle(fontWeight: FontWeight.w800)),
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
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
          child: Row(
            children: [
              ChoiceChip(
                label: Text(l.pick('आगामी', 'Upcoming')),
                selected: upcomingOnly,
                onSelected: (_) => setState(() => upcomingOnly = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(l.pick('पूरा वर्ष', 'Full year')),
                selected: !upcomingOnly,
                onSelected: (_) => setState(() => upcomingOnly = false),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<FestivalObservance>>(
            future: future,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var items = snap.data!;
              if (upcomingOnly) {
                if (year == now.year) {
                  final today = DateTime.utc(now.year, now.month, now.day);
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
                      contentPadding: const EdgeInsets.fromLTRB(14, 6, 10, 6),
                      leading: Container(
                        width: 46,
                        height: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
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
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('$month ${f.localDate.year}'),
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
}
