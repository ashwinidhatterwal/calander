# Checkpoint 11 verification — source candidate only

Version: 1.0.0+11. Package: in.hinducalendar.hindu_calendar.

Passed in this continuation:

- Checkpoint 11 source validator, including actual district geometry checks.
- Five permission-audit regression tests; special alarm, background location and
  unrelated sensitive permissions are rejected.
- git diff --check.
- Shell syntax validation for the Android scaffold script.
- All 16 Python reference astronomy/festival test functions, executed directly
  because pytest is absent. This is not the Flutter parity test suite.
- Panchang astronomy file byte comparison with checkpoint 10 source: unchanged.
  SHA-256: 195f401fbd82e18e842c1a9976d882f5947482659f3022cf460000a5e1cb6ce0.
- 36 distinct state/UT codes present in bundled 2026 reference holidays.

Added, but NOT executed here: checkpoint11_test.dart covers district geometry,
division-label detection, unchanged valid saved names, regional holiday coverage,
sorting, duplicate national holidays and future-year scoping. Existing parity and
UX tests are retained and run by both CI workflows.

Pending (not claimed as passed):

- flutter analyze and the complete Flutter test suite for build +11.
- Fresh QA APK and obfuscated AAB compilation.
- Final +11 merged-manifest audit and signature inspection.
- Production upload-key signing via existing GitHub Actions secrets.
- Physical-device checks: actual district name, notification delivery after normal
  close/reboot, opt-out preservation, notification permission denial, duplicate
  Recents cards, launcher widgets and battery-management delay.

The previous toolchain paths (/tmp/flutter-current/flutter, /tmp/android-sdk) and
package cache no longer exist. Flutter and Dart are not on PATH; the attempted SDK
and release-index download requests returned HTTP 404 in this environment. Prior
build +10 results do not validate +11. No fresh +11 APK/AAB is included, and no
repository push or Play upload has been performed.

Run Android QA build and Production Play bundle after applying this source. Both
workflows validate build 11. Remain on the existing closed-testing track. Do not
publish this candidate until those checks and device tests pass.
