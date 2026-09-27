import 'package:flutter_test/flutter_test.dart';
import 'package:hindu_calendar/core/locations.dart';
import 'package:hindu_calendar/domain/panchang_engine.dart';
import 'package:hindu_calendar/domain/personal_event.dart';

void main() {
  const engine = PanchangEngine();
  const matcher = PersonalEventMatcher(engine);
  final location = locations.first;

  test('Gregorian yearly personal event follows month and day', () {
    const event = PersonalEvent(
      id: 'birthday',
      title: 'जन्मदिन',
      kind: PersonalEventKind.birthday,
      basis: PersonalEventBasis.gregorian,
      repeatYearly: true,
      gregorianYear: 2024,
      gregorianMonth: 9,
      gregorianDay: 27,
    );
    expect(matcher.occursOn(event, DateTime.utc(2026, 9, 27), location), isTrue);
    expect(matcher.occursOn(event, DateTime.utc(2026, 9, 28), location), isFalse);
  });

  test('Hindu Tithi event matches Ashwin Krishna Pratipada reference date', () {
    const event = PersonalEvent(
      id: 'tithi-event',
      title: 'तिथि कार्यक्रम',
      kind: PersonalEventKind.family,
      basis: PersonalEventBasis.hinduTithi,
      repeatYearly: true,
      hinduMonth: 7,
      hinduPaksha: PersonalEventPaksha.krishna,
      hinduTithi: 1,
    );
    expect(matcher.occursOn(event, DateTime.utc(2026, 9, 27), location), isTrue);
  });

  test('Personal event JSON round trip preserves calendar rule', () {
    const source = PersonalEvent(
      id: 'x',
      title: 'पूजा',
      note: 'घर पर',
      kind: PersonalEventKind.puja,
      basis: PersonalEventBasis.hinduTithi,
      repeatYearly: true,
      hinduMonth: 8,
      hinduPaksha: PersonalEventPaksha.shukla,
      hinduTithi: 5,
      adhikMonth: false,
    );
    final decoded = PersonalEvent.fromJson(source.toJson());
    expect(decoded.id, source.id);
    expect(decoded.title, source.title);
    expect(decoded.basis, source.basis);
    expect(decoded.hinduMonth, source.hinduMonth);
    expect(decoded.hinduPaksha, source.hinduPaksha);
    expect(decoded.hinduTithi, source.hinduTithi);
  });
}
