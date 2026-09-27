# Checkpoint 03 — CI Fix Revision

This revision contains the full Checkpoint 03 package plus the first GitHub Actions compiler/test fix discovered during the real Android CI run.

## Fixed

`flutter_app/lib/screens/festivals_screen.dart`

The Festivals screen previously created its asynchronous festival computation with `Future(...)`. Flutter's widget smoke test reported a pending zero-duration timer after widget disposal, causing `flutter test` to fail even though the Panchang and festival parity tests passed.

The computation now uses `Future.sync(...)`, which avoids leaving the pending timer in the widget test while preserving the same festival calculation behavior.

## First CI run status before this fix

- Flutter setup: PASS
- Android scaffold generation: PASS
- `flutter pub get`: PASS
- `flutter analyze`: PASS (no issues)
- Panchang parity: PASS
- 2026 festival parity: PASS
- 2027 festival parity: PASS
- Widget smoke test: FAIL (pending Timer)
- APK build: skipped because tests stopped the job

Push this revision to `main`; GitHub Actions should run again and proceed to the APK build if no further compiler/runtime test issue is found.
