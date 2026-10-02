import 'async_calendar_helper.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
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
  int failuresRemaining = 0;
  Position? lastKnown;
  DateTime? primaryTimestamp;
  int nativeReads = 0;
  @override
  Future<Position?> getLastKnownPosition({bool forceLocationManager = false}) async => lastKnown;

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
    if (timeout || failuresRemaining > 0) {
      if (failuresRemaining > 0) failuresRemaining--;
      throw TimeoutException('No fix');
    }
    return Position(latitude: 28.7, longitude: 74.3, timestamp: primaryTimestamp ?? DateTime.now(),
      accuracy: 1000, altitude: 0, altitudeAccuracy: 0, heading: 0,
      headingAccuracy: 0, speed: 0, speedAccuracy: 0);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('in.hinducalendar/device');
  late FakeLocator fake;
  late GeolocatorPlatform original;
  setUp(() {
    original = GeolocatorPlatform.instance;
    fake = FakeLocator();
    GeolocatorPlatform.instance = fake;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'locationStatus') {
        return <String, dynamic>{'enabled': fake.enabled, 'gpsEnabled': fake.enabled,
          'networkEnabled': fake.enabled};
      }
      if (call.method == 'currentPosition') {
        fake.nativeReads++;
        if (fake.timeout) throw PlatformException(code: 'location_timeout');
        return <String, dynamic>{'latitude': 29.58, 'longitude': 74.29,
          'accuracy': 30.0, 'timestamp': DateTime.now().millisecondsSinceEpoch,
          'provider': 'gps'};
      }
      if (call.method == 'district') {
        return <String, dynamic>{'districtEn': 'Bikaner Division',
          'districtHi': 'बीकानेर डिवीजन', 'stateEn': 'Rajasthan',
          'stateHi': 'राजस्थान', 'countryCode': 'IN'};
      }
      return null;
    });
  });
  tearDown(() {
    GeolocatorPlatform.instance = original;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  const service = CurrentLocationService();

  test('one bounded position request accepts approximate foreground fix', () async {
    final location = await service.obtain();
    expect(location.latitude, 28.7);
    expect(location.utcOffsetMinutes, 330);
    expect(fake.reads, 1);
    expect(fake.settings!.accuracy, LocationAccuracy.high);
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
    fake.lastKnown = Position(latitude: 29.58, longitude: 74.29,
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        accuracy: 10, altitude: 0, altitudeAccuracy: 0, heading: 0,
        headingAccuracy: 0, speed: 0, speedAccuracy: 0);
    await expectLater(service.obtain(), throwsA(isA<CurrentLocationException>()
        .having((error) => error.code, 'code', 'timeout')));
    expect(fake.reads, 1);
    expect(fake.nativeReads, 1);
    expect(LocationDiagnostics.report, contains('location_timeout'));
  });
  test('failed fused request uses explicit native GPS/network fallback', () async {
    fake.failuresRemaining = 1;
    final location = await service.obtain();
    expect(location.latitude, 29.58);
    expect(location.cityEn, 'Hanumangarh');
    expect(location.cityHi, 'हनुमानगढ़');
    expect(fake.reads, 1);
    expect(fake.nativeReads, 1);
    expect(LocationDiagnostics.report, contains('Native provider: gps'));
  });
  test('stale primary fix is rejected before native recovery', () async {
    fake.primaryTimestamp = DateTime.now().subtract(const Duration(hours: 1));
    final location = await service.obtain();
    expect(location.latitude, 29.58);
    expect(fake.nativeReads, 1);
    expect(LocationDiagnostics.report, contains('Primary fix rejected'));
  });
  test('recent accurate cached fix recovers a timeout', () async {
    fake.timeout = true;
    fake.lastKnown = Position(latitude: 29.58, longitude: 74.29,
        timestamp: DateTime.now().subtract(const Duration(seconds: 30)),
        accuracy: 50, altitude: 0, altitudeAccuracy: 0, heading: 0,
        headingAccuracy: 0, speed: 0, speedAccuracy: 0);
    final location = await service.obtain();
    expect(location.latitude, 29.58);
    expect(location.longitude, 74.29);
    expect(location.cityEn, 'Hanumangarh');
    expect(location.cityHi, 'हनुमानगढ़');
    expect(fake.reads, 1);
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
