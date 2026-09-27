# Hindu Calendar — Checkpoint 04

Checkpoint 04 is the first **real-device UX and utility pass** on the Hindi-first Flutter Android app.

The Panchang and festival calculation foundation from Checkpoint 03 is intentionally unchanged. This checkpoint focuses on making the calendar easier to read and more useful without opening every date.

## Main calendar changes

- Larger card-style date tiles.
- Every tile still prioritizes the normal Gregorian date and Tithi.
- Important dates now show a **short festival/vrat label directly inside the tile**.
- Major festival examples: `दीपावली`, `जन्माष्टमी`, `करवा चौथ`, `दशहरा`, `नवरात्रि`.
- Recurring high-utility observances shown directly: `एकादशी`, `पूर्णिमा`, `अमावस्या`.
- Removed the unexplained colored-dot-only presentation.
- Added a small per-location Tithi cell cache so calendar redraws do not repeatedly recalculate the same visible dates.

## Day Details changes

Transition timings are now written in human language.

Examples:

```text
उत्तर भाद्रपद — आज सुबह 11:09 तक
कृष्ण प्रतिपदा — आज रात 9:00 तक
```

If the transition is after midnight the app explicitly says `कल` / `Tomorrow` instead of showing an ambiguous clock time.

Festival/vrat information is visually emphasized at the top of the Day page.

## Festival browser changes

- More compact festival rows.
- `आगामी / Upcoming` view.
- `पूरा वर्ष / Full year` view.
- Year navigation remains available.
- Festival rows still open the full Day Details page.

## Product direction

- Hindi first; English switch in-app.
- Familiar Gregorian monthly calendar.
- Tithi, Hindu month, festival/vrat context visible with minimal navigation.
- Detailed Panchang remains on a separate Day page.
- Offline-first.
- No paid Panchang API.
- No commercial astronomy runtime.
- No login/backend required for the core experience.

## Repository layout

```text
flutter_app/       Production Flutter/Dart app source
reference_python/  Frozen reference engine and validation suite
tools/             Checkpoint validation + parity-fixture generator
.github/            GitHub Actions Android test/build pipeline
docs/               Current checkpoint documentation
```

## Build

Push this directory as the repository root. GitHub Actions runs analysis/tests and builds a release APK artifact named:

```text
hindu-calendar-checkpoint-04-apk
```

App version: `0.4.0+4`.

The Android package identity remains provisional: `in.hinducalendar.hindu_calendar`.
