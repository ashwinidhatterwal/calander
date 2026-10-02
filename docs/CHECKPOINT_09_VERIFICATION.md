# Checkpoint 09 verification

Base repository commit: `ef29ed89bb82282799d5db398ceff849cc621999`.
App version: `1.0.0+9`. Android ID: `in.hinducalendar.hindu_calendar`.
Toolchain: Flutter 3.47.5 / Dart 3.13.4; Android API 36; local JDK 17.

| Check | Actual result |
| --- | --- |
| `flutter analyze --no-pub` after successful package resolution | PASS: no issues |
| `flutter test --no-pub --reporter expanded` | PASS: all 25 tests |
| Existing Panchang and festival parity tests | PASS; retained without changes |
| Panchang astronomy file compared with base commit | Byte-for-byte unchanged |
| Checkpoint 09 source validator | PASS; historical checkpoint 08 validator unchanged |
| Permission-audit regression tests | PASS: 5 tests, including identity/build9 and rejection of background/unknown permissions |
| Android scaffold generation and shell syntax | PASS; correct Kotlin packages and normalized Android ID |
| Production signing configurator on generated Gradle copy | PASS: existing signing path/configuration retained |
| QA APK compilation | PASS: release QA APK built successfully (56.1 MB) |
| Final APK identity/version/target/merged permissions | PASS: `in.hinducalendar.hindu_calendar`, version code 9, target SDK 36; final APK audit passed |
| Local AAB compilation/manifest | PASS: release AAB compiled with obfuscation and symbols (51.6 MB); QA/debug signing only, not a Play upload artifact |
| Signed production AAB using existing upload key | NOT RUN: upload-key secrets live in GitHub Actions; connected repository writing returned 403 |
| Real-device location dialogs, widget rendering and startup timing | NOT RUN in this workspace; device checks remain before rollout |

## Added Flutter regression coverage

Location persistence and migration from manual city IDs; corrupt/out-of-range data fallback; refresh with the same ID but different coordinates; selective yearly cache invalidation; denial/permanent denial/disabled service/timeout; bounded one-shot acquisition; no location request on normal startup or before tapping the first-use offer; Today-only highlight after returning from Day Details and using month arrows/month-year picker; bilingual fixed national holiday dates and separate category.

## Production handoff

Upload the source to the existing repository, let **Android QA build** pass, then run **Production Play bundle** with the existing secrets. Its signed AAB is the Play upload artifact. Continue the existing Closed testing track. This package remains a Checkpoint 09 release candidate until the signed production build and device checks pass.

## APK permissions observed

Fine/coarse foreground location, network-state, wake-lock, boot-completed (existing widget/AndroidX WorkManager dependency), and the app-local dynamic-receiver permission. No background location, foreground location-service, contacts, SMS, camera, microphone or broad storage permission appears.

The downloadable QA APK uses the generated debug key, as the QA workflow does. It cannot update an installed Play build signed with a different key. Use the signed production AAB for updates to closed testers.
