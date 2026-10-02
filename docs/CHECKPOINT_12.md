# Checkpoint 12 — location acquisition and localized Today times

Version: 1.0.0+12. Android package: in.hinducalendar.hindu_calendar.

## Changes

- Both Today sunrise and sunset use local 12-hour formatting. Hindi suffixes
  are पु. and अप.; English suffixes are AM and PM. Noon and midnight remain 12.
- First acquisition uses high accuracy. The previous medium setting maps to
  balanced-power fused requests rather than high-accuracy requests.
- Android's enabled status is checked through the system LocationManager so a
  Play Services settings failure does not falsely block an enabled GPS.
- After a failed primary request, a cached fix is accepted only if no older than
  two minutes and accuracy is at most 2 km. Invalid and stale fixes are rejected.
- The fallback explicitly calls GPS and network providers. It does not ask the
  Geolocator LocationManager backend to choose a provider, since that backend
  prefers system fused on recent Android versions. GPS is requested only when
  fine permission is granted; approximate permission still supports network.
- Native one-shot requests cancel on completion, timeout or activity destruction.
  A generation guard prevents old callbacks affecting a new request.
- The native fallback ends within 45 seconds. With a primary timeout, cache check
  and optional naming, a cold acquisition can take roughly 75 seconds.
- Offline district geometry resolves acquired coordinates independently of the
  administrative level returned by the geocoder. The result is not hardcoded to
  Hanumangarh. Existing division names receive coordinate-based repair.
- Location persistence no longer waits for year-long festival calculation.
  Failed preference writes now report an error instead of claiming success.
- The Details action on location success/failure shows an in-memory report:
  permission status, provider attempts, actual error codes, accuracy, and resolved
  coordinates/district. The user can copy it. Nothing is uploaded or logged to a
  server, and this report is not persistently stored.

## Confirmed weaknesses versus device-specific cause

The balanced-priority request, fused-preferred plugin fallback, discarded error
codes, calculation dependency and unchecked preference writes are source-confirmed
weaknesses fixed here. They do not establish which one caused the user's phone's
past failure. That requires the new report or an Android device log. No fake city
is returned as a successful GPS result, and no startup/background GPS is added.

## Research

Primary source references used to check provider selection, permissions and API:

- https://github.com/Baseflow/flutter-geolocator/blob/main/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/LocationManagerClient.java
- https://github.com/Baseflow/flutter-geolocator/blob/main/geolocator_android/android/src/main/java/com/baseflow/geolocator/location/FusedLocationClient.java
- https://pub.dev/documentation/geolocator/latest/
- https://developer.android.com/develop/sensors-and-location/location/permissions/runtime
- https://developer.android.com/reference/androidx/core/location/LocationManagerCompat

Android approximate permission can yield slower/less precise fixes. A coordinate
close to a district boundary can still be ambiguous within the device accuracy.
Bundled geometry needs maintenance after district reorganizations.

## Verification

Passed locally: checkpoint 12 source and district-geometry validator; five
permission-audit tests; scaffold shell syntax; ZIP and complete checksum checks.
Flutter regressions updated/added: stale fix rejection, explicit native fallback,
Hanumangarh naming despite division geocoder output, diagnostic error preservation,
localized sunrise and sunset in both languages, and noon/midnight.

NOT executed locally: Flutter analyze/tests, Kotlin compilation, new APK/AAB,
physical-device acquisition, Android permission toggles and lifecycle cleanup.
Flutter/Android toolchains are absent here. The old successful GitHub build 11
runs do not validate build 12. Both workflows run these checks after upload.

## Install and review

Upload the entire package including .github. Run Android QA build. Install the new
build 12 APK and tap location -> Use current location. Verify the actual district,
local sunrise/sunset suffixes, and saved coordinates after reopening. If it fails,
tap Details and copy the report; it distinguishes the actual failing stage.
Run Production Play bundle for an upload-key signed AAB. Keep the same package
and closed-testing track. No fresh APK/AAB is included in this source ZIP.
