import 'async_calendar_helper.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hindu_calendar/data/current_location_service.dart';
import 'package:hindu_calendar/main.dart';

class FakeLocator extends GeolocatorPlatform {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  int reads = 0;
  int requests = 0;
  bool timeout = false;
  LocationSettings? settings;
  @override
  Future<bool> isLocationServiceEnabled() async => enabled;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return requestedPermission;
  }
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    reads++;
    settings = locationSettings;
    if (timeout) throw TimeoutException('No fix');
    return Position(latitude: 28.7, longitude: 74.3, timestamp: DateTime.now(),
      accuracy: 1000, altitude: 0, altitudeAccuracy: 0, heading: 0,
      headingAccuracy: 0, speed: 0, speedAccuracy: 0);
  }
}

void main() {
  late FakeLocator fake;
  late GeolocatorPlatform original;
  setUp(() {
    original = GeolocatorPlatform.instance;
    fake = FakeLocator();
    GeolocatorPlatform.instance = fake;
  });
  tearDown(() => GeolocatorPlatform.instance = original);
  const service = CurrentLocationService();

  test('one bounded position request accepts approximate foreground fix', () async {
    final location = await service.obtain();
    expect(location.latitude, 28.7);
    expect(location.utcOffsetMinutes, 330);
    expect(fake.reads, 1);
    expect(fake.settings!.accuracy, LocationAccuracy.medium);
    expect(fake.settings!.timeLimit, const Duration(seconds: 20));
  });
  test('disabled service does not request permissions or position', () async {
    fake.enabled = false;
    await expectLater(service.obtain(), throwsA(isA<CurrentLocationException>()));
    expect(fake.reads, 0);
    expect(fake.requests, 0);
  });
  test('denied permission stops acquisition, permanent denial is not reprompted', () async {
    fake.permission = LocationPermission.denied;
    fake.requestedPermission = LocationPermission.denied;
    await expectLater(service.obtain(), throwsA(isA<CurrentLocationException>()));
    expect(fake.requests, 1);
    expect(fake.reads, 0);
    fake.permission = LocationPermission.deniedForever;
    await expectLater(service.obtain(), throwsA(isA<CurrentLocationException>()));
    expect(fake.requests, 1);
  });
  test('timeout does not silently choose stale coordinates', () async {
    fake.timeout = true;
    await expectLater(service.obtain(), throwsA(isA<TimeoutException>()));
  });
  testWidgets('ordinary startup never requests a current location', (tester) async {
    await tester.pumpWidget(const HinduCalendarApp(holikaOverrides: {}));
    await settleCalendar(tester);
    expect(fake.reads, 0);
    expect(fake.requests, 0);
  });

  testWidgets('first-use offer waits for a tap before permission request', (tester) async {
    var offerRemembered = false;
    await tester.pumpWidget(HinduCalendarApp(holikaOverrides: const {},
      offerCurrentLocation: true,
      onLocationOfferSeen: () async => offerRemembered = true));
    await settleCalendar(tester);
    expect(offerRemembered, isTrue);
    expect(find.text('वर्तमान स्थान इस्तेमाल करें'), findsOneWidget);
    expect(fake.reads, 0);
    expect(fake.requests, 0);
  });

}
