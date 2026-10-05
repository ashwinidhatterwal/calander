import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/localization.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/data/notification_service.dart';

void main() {
  final delhi = locations.firstWhere((x) => x.id == 'delhi');
  for (final language in AppLanguage.values) {
    test('$language reminder places tithi in title, festival before date', () {
      final day = notificationPayload((
        DateTime.utc(2026, 10, 19),
        delhi,
        language,
        <int, DateTime>{},
        []
      ))['2026-10-19']!;
      final hi = language == AppLanguage.hi;
      expect(day['title'], hi ? 'शुक्ल पक्ष अष्टमी' : 'Shukla Paksha Ashtami');
      expect(day['title'], isNot(contains('2026')));
      expect(day['body']!.split('\n').first,
          contains(hi ? 'दुर्गा अष्टमी' : 'Durga Ashtami'));
      expect(day['body']!.split('\n').last, day['date']);
      expect(day['body'],
          isNot(contains(hi ? 'मासिक दुर्गाष्टमी' : 'Masik Durgashtami')));
    });
    test('$language ordinary day keeps date and empty personal events', () {
      final day = notificationPayload((
        DateTime.utc(2026, 10, 5),
        delhi,
        language,
        <int, DateTime>{},
        []
      ))['2026-10-05']!;
      expect(day['title'], isNotEmpty);
      expect(day['body'], day['date']);
      expect(day['events'], '');
    });
  }
}
