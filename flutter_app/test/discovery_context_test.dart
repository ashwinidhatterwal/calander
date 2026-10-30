import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/data/daily_discoveries.dart';

void main() {
  test(
      'readings identify their own speaker without inventing a shared dialogue',
      () {
    final contextual =
        DailyDiscoveries.entries.where((e) => e.contextHi.isNotEmpty);
    expect(contextual.length, 72);
    expect(contextual.every((e) => e.contextEn.isNotEmpty), isTrue);
    final gita = contextual.where((e) => e.group == 'gita');
    expect(gita.length, 21);
    expect(gita.every((e) => e.contextHi.contains('अर्जुन')), isTrue);
    final vidura = contextual.where((e) => e.group == 'vidura');
    expect(vidura.every((e) => e.contextHi.contains('धृतराष्ट्र')), isTrue);
    expect(contextual.firstWhere((e) => e.id == 'uddalaka-salt').contextHi,
        contains('श्वेतकेतु'));
    expect(contextual.firstWhere((e) => e.id == 'maitreyi-question').contextHi,
        contains('मैत्रेयी'));
    expect(
        DailyDiscoveries.entries
            .firstWhere((e) => e.id == 'gita-birth')
            .contextHi,
        isEmpty);
  });
}
