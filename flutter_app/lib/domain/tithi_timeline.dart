import 'models.dart';
import 'panchang_engine.dart';

/// Civil-day intervals, clipped to local midnight boundaries. True transition
/// times are kept separately; a displayed day boundary is not a tithi change.
class TithiInterval {
  const TithiInterval({
    required this.state,
    required this.fromUtc,
    required this.toUtc,
    required this.actualEndUtc,
    required this.atSunrise,
  });
  final TithiState state;
  final DateTime fromUtc, toUtc, actualEndUtc;
  final bool atSunrise;
}

List<TithiInterval> civilTithiTimeline(
  PanchangEngine engine,
  DateTime date,
  GeoLocation location,
) {
  final start = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).subtract(location.offset);
  final end = start.add(const Duration(days: 1));
  final sunrise = engine.sunriseSunset(date, location)[0];
  final result = <TithiInterval>[];
  var cursor = start;
  while (cursor.isBefore(end)) {
    final sample = cursor.add(const Duration(milliseconds: 1));
    final transition = engine.nextTithiTransition(sample);
    if (!transition.isAfter(cursor)) {
      throw StateError('Non-advancing tithi transition');
    }
    final clipped = transition.isBefore(end) ? transition : end;
    result.add(
      TithiInterval(
        state: engine.tithiAt(sample),
        fromUtc: cursor,
        toUtc: clipped,
        actualEndUtc: transition,
        atSunrise: !sunrise.isBefore(cursor) && sunrise.isBefore(clipped),
      ),
    );
    cursor = clipped;
  }
  return List.unmodifiable(result);
}
