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
