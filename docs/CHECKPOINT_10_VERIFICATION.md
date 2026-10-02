# Checkpoint 10 verification — release candidate

Version: **1.0.0+10**. Package: **in.hinducalendar.hindu_calendar**.

| Check | Result |
| --- | --- |
| Flutter 3.47.5 / Dart 3.13.4 analyze | PASS: no issues |
| All Flutter tests | PASS: 30 tests, including retained Panchang and festival parity tests |
| Permission-audit regression tests | PASS: 5 tests; rejects unrelated sensitive permissions and missing intended permissions |
| Checkpoint 10 source validator | PASS |
| QA release APK | PASS: built and APK signature verified (QA/debug key) |
| Obfuscated release AAB | PASS: built, JAR signature verified (QA/debug key) |
| APK and AAB merged manifest audit | PASS: package unchanged; versionCode 10; approved permissions only |
| Hindi festival layout visual check | PASS at 400 × 860 logical pixels with loaded Devanagari font; date/month selectors remain bounded |
| Android district lookup on a device | PENDING closed-test verification |
| Native launcher widget rendering | PENDING checks on light/dark wallpapers and resized widgets |
| Notifications with app closed/reboot/exact permission denied | PENDING Android device verification |
| Production upload-key signing | PENDING existing GitHub Actions signing secrets; local AAB is not Play-ready |

Merged permissions: ACCESS_COARSE_LOCATION, ACCESS_FINE_LOCATION, ACCESS_NETWORK_STATE,
POST_NOTIFICATIONS, RECEIVE_BOOT_COMPLETED, SCHEDULE_EXACT_ALARM, WAKE_LOCK, and the app's
DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION. Neither merged artifact requests background
location or a location foreground service. No INTERNET permission is present in these
release manifests; optional Android Geocoder lookup is delegated to the system provider.

The local APK is for QA only. To continue closed testing, apply the source package to the
repository and run the existing Production Play bundle workflow with the existing secrets.
Upload the resulting production-signed +10 AAB to the existing closed testing track.

Connected GitHub writing previously returned 403 Resource not accessible by integration.
The delivery therefore uses the authorized ZIP fallback. No Play upload was performed.

Development tool analytics were explicitly disabled for Flutter and Dart after automatic
approval review rejected earlier commands attempting Google Analytics connections. Final
analysis, tests, APK and AAB checks completed with telemetry disabled.
