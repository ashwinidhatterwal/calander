# Checkpoint 05 — Personal Hindu Calendar

## Goal

Move the product beyond a conventional Panchang viewer by allowing a user to maintain everyday personal events that understand both Gregorian dates and Hindu Tithis.

## Added

- `PersonalEvent` domain model.
- Gregorian annual/fixed recurrence.
- Hindu month + Paksha + Tithi annual recurrence.
- Optional Adhik Maas rule.
- Local JSON persistence through SharedPreferences.
- My Days screen with upcoming-event resolution.
- Add/edit/delete event flow.
- Event categories and icons.
- Calendar tile integration.
- Day Details integration.
- Main-calendar quick-add action.
- Hindi-first editor with English localization.
- Immediate Flutter bootstrap loading screen.
- Warm Android launch background in CI-generated Android scaffold.

## Calculation boundary

No changes were made to:

- solar/lunar astronomy algorithms
- Tithi calculation
- Nakshatra/Yoga/Karana
- Hindu month calculation
- festival selection rules

Personal Hindu events consume the existing Panchang result rather than implementing a second calendar engine.

## Persistence

The event store serializes only a small JSON list to local preferences. The UI layer receives immutable event lists and performs in-memory matching. There is no remote account or network dependency.

## Recurrence behavior

Gregorian events can be:

- fixed to one exact date; or
- repeated yearly by month/day.

Hindu events repeat annually using:

- Purnimanta Hindu month
- Shukla/Krishna Paksha
- Tithi 1–15
- normal/Adhik month flag

## Edge case

A Tithi skipped at sunrise may not receive a normal sunrise-based match. This is documented for future tradition-specific resolution work.
