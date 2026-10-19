/// Sunday-first full weeks, ending with the week containing this month's last
/// civil date. Only unused cells in that final week belong to the next month.
List<DateTime> monthGridDates(DateTime month) {
  final first = DateTime.utc(month.year, month.month, 1);
  final offset = first.weekday % 7;
  final days = DateTime.utc(first.year, first.month + 1, 0).day;
  final count = ((offset + days + 6) ~/ 7) * 7;
  final start = first.subtract(Duration(days: offset));
  return List.generate(count, (i) => start.add(Duration(days: i)));
}

/// Fill the viewport without shrinking below the space needed by card labels.
/// The grid scrolls if its minimum content height exceeds the viewport.
double calendarTileHeight({
  required double viewportHeight,
  required int rows,
  required double textScale,
}) {
  assert(rows >= 4 && rows <= 6);
  final scale = textScale.isFinite && textScale > 1 ? textScale : 1.0;
  final minimum = 52.0 * scale;
  if (!viewportHeight.isFinite) {
    return minimum;
  }
  // Leave a sub-pixel tolerance so floating-point rounding cannot create
  // a spurious scroll extent when full weeks fit exactly.
  final available = (viewportHeight - 12 - (rows - 1) * 5 - .01) / rows;
  return available < minimum ? minimum : available;
}
