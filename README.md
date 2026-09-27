# Hindu Calendar — Checkpoint 06

Checkpoint 06 turns the app from a Panchang viewer into the beginning of a **personal Hindu life calendar**.

The trusted Panchang/festival calculation engine remains unchanged. This checkpoint adds a local personal-event layer and a proper startup experience.

## Main product addition — मेरे दिन / My Days

Users can create personal events such as:

- जन्मदिन / Birthday
- वर्षगाँठ / Anniversary
- पूजा / Puja
- व्रत / Vrat
- परिवार / Family event
- General event

Each event can follow either:

### 1. Normal Gregorian date

Example:

```text
12 March
Repeat every year ✓
```

or a one-time exact Gregorian date.

### 2. Hindu Tithi

Example:

```text
कार्तिक
कृष्ण पक्ष
नवमी
```

The app then matches that event against the Panchang engine each year instead of locking it to one Gregorian date.

Tithi events also support an `अधिक मास` flag for events that specifically belong to an Adhik month.

## Where personal events appear

- New **मेरे दिन / My Days** bottom-navigation tab.
- Upcoming personal-event list.
- Calendar date tiles, alongside festival/vrat information.
- Day Details page under a dedicated `मेरे दिन` card.
- `+` shortcut in the main calendar header creates an event for the currently selected date.

All personal events are stored **only on the device** using local preferences. No login, Firebase, server, or account is introduced.

## Startup / loading screen

The old startup path loaded an asset before `runApp()`, which could leave an empty/black frame while Flutter initialized.

Checkpoint 06 now:

1. calls `runApp()` immediately;
2. renders a warm branded Hindi loading screen;
3. loads festival overrides and personal events behind it;
4. transitions into the calendar when ready.

The GitHub Android workflow also replaces the generated Android launch background with the same warm background (`#FFF8F1`) so the native launch frame and Flutter loading screen feel continuous.

## Calendar refinements retained/improved

- Large card-style date tiles.
- Gregorian date remains visually dominant.
- Tithi remains visible under the date.
- Major festival/vrat names remain visible directly inside tiles.
- Personal event title can occupy the event area when there is no major festival on that date.
- Event labels can use two lines instead of truncating immediately.
- Extra bottom grid padding reduces bottom-row obstruction near Android navigation.

## Day Details refinements

- Personal events appear above Panchang details.
- Festival cards are more compact.
- Nakshatra/Yoga/Karana transition values use a deliberate two-line layout instead of awkwardly wrapping `तक` onto its own line.

## Privacy / backend

Checkpoint 06 still needs no backend for its core experience.

Stored locally:

- personal events

Not stored remotely:

- names
- family events
- birthdays
- Hindu-Tithi recurrence rules

## Known limitation

Hindu personal-event recurrence currently matches the Tithi that prevails at local sunrise, using the North-Indian Purnimanta month profile already used by the app. This is deterministic and appropriate for ordinary calendar use, but a rare **Kshaya/skipped Tithi** can require tradition-specific handling. Such edge cases should be expanded before positioning the feature for formal ritual/legal scheduling.

## Build

Push this directory as the repository root. GitHub Actions runs:

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Expected artifact:

```text
hindu-calendar-checkpoint-06-apk
```

App version: `0.6.0+6`.

The Android package identity remains provisional: `in.hinducalendar.hindu_calendar`.

## Checkpoint 06

Checkpoint 06 adds the final Android-shell polish around the existing calendar engine: branded launcher/loading icon, resisted month swiping, tap-to-jump month/year selection, single-task Recents behavior, and two theme-aware Android home-screen widgets (Today Panchang + Upcoming festival/My Day). See `docs/CHECKPOINT_06.md`.
