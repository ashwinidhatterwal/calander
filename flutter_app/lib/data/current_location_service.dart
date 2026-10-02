import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import 'district_lookup.dart';

class CurrentLocationException implements Exception {
  const CurrentLocationException(this.code);
  final String code;
}

class LocationDiagnostics {
  static final List<String> _steps = [];
  static void start() {
    _steps.clear();
    note('Location request: ${DateTime.now().toIso8601String()}');
  }
  static void note(String value) => _steps.add(value);
  static void error(String stage, Object error) {
    note('$stage: ${error.runtimeType}'
        '${error is PlatformException ? ' / ${error.code} / ${error.details}' : ''}'
        '${error is CurrentLocationException ? ' / ${error.code}' : ''}');
  }
  static String get report => _steps.join('\n');
}

/// Called only after an explicit user action; no streams or startup requests.
class CurrentLocationService {
  const CurrentLocationService();

  /// One-time label repair for older builds, using saved coordinates only.
  Future<GeoLocation> repairSavedDistrict(GeoLocation saved) async {
    if (saved.id != 'current' ||
        (!isDivisionLabel(saved.cityEn) && !isDivisionLabel(saved.cityHi))) {
      return saved;
    }
    final district = await offlineDistrict(saved.latitude, saved.longitude);
    if (district == null) return saved;
    return GeoLocation(
      id: saved.id,
      cityHi: districtNameHi(district),
      cityEn: district,
      stateHi: saved.stateHi,
      stateEn: saved.stateEn,
      countryCode: saved.countryCode,
      latitude: saved.latitude,
      longitude: saved.longitude,
      utcOffsetMinutes: saved.utcOffsetMinutes,
    );
  }

  bool _validPosition(Position position) =>
      position.latitude.isFinite && position.longitude.isFinite &&
      position.latitude >= -90 && position.latitude <= 90 &&
      position.longitude >= -180 && position.longitude <= 180 &&
      position.accuracy.isFinite && position.accuracy >= 0 &&
      DateTime.now().difference(position.timestamp) >= const Duration(seconds: -5) &&
      DateTime.now().difference(position.timestamp) <= const Duration(minutes: 2);

  Future<Position> _obtainPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (_validPosition(position)) {
        LocationDiagnostics.note('Primary high-accuracy fix: ±${position.accuracy.round()} m');
        return position;
      }
      LocationDiagnostics.note('Primary fix rejected: invalid or stale');
    } catch (error) { LocationDiagnostics.error('Primary high-accuracy request failed', error); }
    try {
      final cached = await Geolocator.getLastKnownPosition()
          .timeout(const Duration(seconds: 2));
      if (cached != null && _validPosition(cached)) {
        final age = DateTime.now().difference(cached.timestamp);
        if (!age.isNegative && age <= const Duration(minutes: 2) &&
            cached.accuracy.isFinite && cached.accuracy >= 0 &&
            cached.accuracy <= 2000) {
          LocationDiagnostics.note('Recent cached fix: ${age.inSeconds}s old, ±${cached.accuracy.round()} m');
          return cached;
        }
      }
      LocationDiagnostics.note('No acceptable cached fix');
    } catch (error) { LocationDiagnostics.error('Cached fix unavailable', error); }
    try {
      final position = defaultTargetPlatform == TargetPlatform.android
          ? await _nativePosition()
          : await Geolocator.getCurrentPosition(locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high,
                  timeLimit: Duration(seconds: 45)));
      if (!_validPosition(position)) {
        throw const CurrentLocationException('unavailable');
      }
      LocationDiagnostics.note('Fallback fix: ±${position.accuracy.round()} m');
      return position;
    } catch (error) {
      LocationDiagnostics.error('Explicit GPS/network fallback failed', error);
      if (error is CurrentLocationException) rethrow;
      final code = error is PlatformException ? error.code : '';
      throw CurrentLocationException(error is TimeoutException || code == 'location_timeout'
          ? 'timeout' : code == 'location_permission' ? 'denied'
          : code == 'location_disabled' ? 'disabled'
          : code == 'location_no_provider' ? 'noProvider' : 'provider');
    }
  }

  Future<Position> _nativePosition() async {
    final raw = await const MethodChannel('in.hinducalendar/device')
        .invokeMethod<Map<dynamic, dynamic>>('currentPosition')
        .timeout(const Duration(seconds: 48));
    if (raw == null) throw const CurrentLocationException('unavailable');
    LocationDiagnostics.note('Native provider: ${raw['provider']}');
    return Position(
      latitude: (raw['latitude'] as num).toDouble(),
      longitude: (raw['longitude'] as num).toDouble(),
      accuracy: (raw['accuracy'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch((raw['timestamp'] as num).toInt()),
      altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0,
      speed: 0, speedAccuracy: 0,
    );
  }

  Future<bool> _locationEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final status = await const MethodChannel('in.hinducalendar/device')
            .invokeMethod<Map<dynamic, dynamic>>('locationStatus')
            .timeout(const Duration(seconds: 3));
        if (status != null) {
          LocationDiagnostics.note('Android location status: $status');
          return status['enabled'] == true;
        }
      } catch (error) { LocationDiagnostics.error('Native status unavailable', error); }
    }
    return Geolocator.isLocationServiceEnabled().timeout(const Duration(seconds: 3));
  }

  Future<GeoLocation> obtain() async {
    LocationDiagnostics.start();
    if (!await _locationEnabled()) {
      throw const CurrentLocationException('disabled');
    }
    var permission = await Geolocator.checkPermission();
    LocationDiagnostics.note('Permission before request: ${permission.name}');
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      LocationDiagnostics.note('Permission after request: ${permission.name}');
    }
    if (permission == LocationPermission.deniedForever) {
      throw const CurrentLocationException('deniedForever');
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const CurrentLocationException('denied');
    }
    try {
      final accuracy = await Geolocator.getLocationAccuracy()
          .timeout(const Duration(seconds: 2));
      LocationDiagnostics.note('Permission accuracy: ${accuracy.name}');
    } catch (error) { LocationDiagnostics.error('Accuracy status unavailable', error); }
    final position = await _obtainPosition();
    Map<String, dynamic> names = {};
    try {
      names = Map<String, dynamic>.from(
          await const MethodChannel('in.hinducalendar/device')
                  .invokeMethod<Map<dynamic, dynamic>>('district', {
                'latitude': position.latitude,
                'longitude': position.longitude
              }).timeout(const Duration(seconds: 6)) ??
              {});
    } catch (error) { LocationDiagnostics.error('Native geocoder unavailable', error); }
    var districtEn = names['districtEn'] as String? ?? '';
    var districtHi = names['districtHi'] as String? ?? '';
    // Resolve the actual point against district boundaries, regardless of
    // which administrative level the phone's geocoder happens to return.
    try {
      final district = await offlineDistrict(position.latitude, position.longitude);
      if (district != null) {
        districtEn = district;
        districtHi = districtNameHi(district);
        LocationDiagnostics.note('District resolved from coordinates: $district');
      }
    } catch (error) { LocationDiagnostics.error('Offline district lookup failed', error); }
    if (isDivisionLabel(districtEn)) districtEn = '';
    if (isDivisionLabel(districtHi)) districtHi = '';
    if (districtHi.isEmpty) {
      districtHi = districtNameHi(districtEn);
    }
    final location = GeoLocation(
      id: 'current',
      cityHi: districtHi.isEmpty ? 'सहेजा हुआ स्थान' : districtHi,
      cityEn: districtEn.isEmpty ? 'Saved location' : districtEn,
      stateHi: names['stateHi'] as String? ?? '',
      stateEn: names['stateEn'] as String? ?? '',
      countryCode: names['countryCode'] as String? ?? '',
      latitude: position.latitude,
      longitude: position.longitude,
      // This release retains its India/IST Panchang profile, including abroad.
      utcOffsetMinutes: 330,
    );
    if (!location.hasValidCoordinates) {
      throw const CurrentLocationException('unavailable');
    }
    LocationDiagnostics.note('Resolved coordinates: ${location.latitude}, ${location.longitude}');
    return location;
  }
}

String districtNameHi(String name) => switch (name.toLowerCase()) {
  'hanumangarh' => 'हनुमानगढ़',
  'bikaner' => 'बीकानेर',
  'ganganagar' || 'sri ganganagar' => 'श्री गंगानगर',
  _ => name,
};
