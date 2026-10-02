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
- Panchang calculation methods retained. The latest patch adds a display-only
  12-hour formatter; the engine file is therefore no longer byte-identical.
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

## District spelling and sunset display patch

- Native and Dart division checks now reject Hindi डिवीजन / डीवीजन variants.
- Existing saved division names are repaired on launch from saved coordinates.
- Today sunset uses 12-hour AM/PM display with the location time offset.
- Prior lint and scrolling-test fixes are included.
- Source validator, five permission tests, and spelling checks passed locally.
- Added Dart regressions for saved Hindi division repair and noon/midnight.
  Flutter analysis, tests, Android compilation, and device validation remain
  pending for this patch. Earlier GitHub build success does not validate it.

## Location acquisition and Hindi time patch

The screenshot's generic error does not establish a specific GPS/provider fault.
The source previously had one medium-accuracy request limited to 20 seconds.
On failure this patch accepts only a device fix no older than two minutes with
accuracy at most 2 km, or retries using Android LocationManager at high accuracy
for up to 30 seconds. Startup never requests GPS and no location stream exists.
Native naming failure does not prevent saving valid coordinates. Newly acquired
coordinates are resolved against offline district geometry even if the native
geocoder returns a plausible but wrong administrative name. Geometry reflects
the bundled dataset and may need updates following district reorganizations.
Timeout and saving failures have separate messages. No preset city is chosen
as a successful result of a failed GPS acquisition.

Hindi sunset uses पु. / अप.; English uses AM / PM. Sunrise retains its current
format because the request concerned sunset. Added Flutter regressions cover
provider retry, recent cached fixes, stale cached rejection, actual district
resolution, and Hindi time suffixes. These tests still require GitHub execution;
Flutter is not installed in this workspace. Source and permission checks passed.
