# Hindu Calendar — Checkpoint 03

Checkpoint 03 turns the validated Python reference engine into the first **real Flutter Android application source tree**.

## Product direction

- Hindi-first interface; English switch available in-app.
- Familiar monthly Gregorian calendar.
- Each date shows its Hindu Tithi.
- Hindu month is visible in the main calendar header/today card.
- Major festival/vrat dates are marked in the calendar.
- Tapping a date opens a separate Day Details page.
- The Day page contains Panchang, Sun/Moon, Muhurat, Rahu Kaal, Samvat, and anomaly information.
- Core calculations run locally; there is no paid Panchang API or commercial astronomy runtime.

## Repository layout

```text
flutter_app/       Production Flutter/Dart app source
reference_python/  Frozen Checkpoint-02 reference engine and validation suite
tools/             Checkpoint validation + parity-fixture generator
.github/            GitHub Actions Android test/build pipeline
docs/               Checkpoint documentation
```

## What is verified here

- The frozen Python engine still passes all 16 Checkpoint-02 tests.
- 10 cross-language parity fixtures were generated directly from the Python reference engine.
- 2026 and 2027 major-festival parity fixtures are included.
- The checkpoint structural validator passes.
- Flutter source has no paid astronomy dependency and no runtime web/API dependency.

## What is not verified in this container

Flutter and the Android SDK are not installed in this execution environment, so `flutter analyze`, `flutter test`, and `flutter build apk` cannot be executed locally here.

The included GitHub Actions workflow installs stable Flutter, generates the Android platform scaffold, runs analysis/tests, builds a release APK, and uploads that APK as an Actions artifact.

## Build through GitHub Actions

Push this entire checkpoint directory as the repository root. Then either push to `main` or run **Android build** manually from GitHub Actions.

The workflow will:

1. install stable Flutter;
2. generate the Android platform folder;
3. apply the Hindi app label;
4. run `flutter analyze`;
5. run the Python-to-Dart parity tests;
6. build `app-release.apk`;
7. upload it as `hindu-calendar-checkpoint-03-apk`.

The Android package identity is currently provisional: `in.hinducalendar.hindu_calendar`. Choose the final brand/package ID before Play Store publication.
