import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import 'district_lookup.dart';

class CurrentLocationException implements Exception {
  const CurrentLocationException(this.code);
  final String code;
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

  Future<GeoLocation> obtain() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const CurrentLocationException('disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const CurrentLocationException('deniedForever');
    }
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      throw const CurrentLocationException('denied');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );
    Map<String, dynamic> names = {};
    try {
      names = Map<String, dynamic>.from(
          await const MethodChannel('in.hinducalendar/device')
                  .invokeMethod<Map<dynamic, dynamic>>('district', {
                'latitude': position.latitude,
                'longitude': position.longitude
              }).timeout(const Duration(seconds: 6)) ??
              {});
    } catch (_) {/* Naming is optional; coordinates still work offline. */}
    var districtEn = names['districtEn'] as String? ?? '';
    var districtHi = names['districtHi'] as String? ?? '';
    if (districtEn.isEmpty || isDivisionLabel(districtEn)) {
      try {
        districtEn = await offlineDistrict(position.latitude, position.longitude) ?? '';
      } catch (_) { /* Optional fallback cannot prevent saving coordinates. */ }
    }
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
    return location;
  }
}

String districtNameHi(String name) => switch (name.toLowerCase()) {
  'hanumangarh' => 'हनुमानगढ़',
  'bikaner' => 'बीकानेर',
  'ganganagar' || 'sri ganganagar' => 'श्री गंगानगर',
  _ => name,
};
