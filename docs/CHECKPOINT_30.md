# Build 30 — Hindu discoveries and clear day details

Based on the fetched calendar repository and includes the build 29 layout and workflow fixes. Compared against GitHub main 10d9f1e to preserve the existing calendar changes.

## Delivered behavior

- 89 bilingual offline editorial records: 79 cultural/devotional/teaching readings and 10 dated historical entries. All 12 Purnimanta months have relevant reading.
- Reading selection prioritises actual observances from the shared festival engine, then sunrise tithi in the matching Hindu month, then the Hindu month, then daily general rotation. The first two cards follow this order and the third adds daily variety. Read more exposes the rest without duplicates.
- Actual festival dates are calculated by the existing location-aware engine, not by a new fixed-date table. Tithi reading suggestions are labelled separately from actual observances. Annual tithi matching is suppressed in adhik months.
- Source buttons and copy buttons on each card. Faith, tradition, teaching and dated history are distinguished. Original brief paraphrases in Hindi and English; no runtime news feed or network polling.
- Discover refreshes at local midnight, on reopening, and on location changes. Annual calculations reuse the app’s festival cache.
- Day details now has a Samvat/Hindu-month header, festival details that expand on tap, a visible civil-day tithi timeline, sun/moon times, and expandable secondary Panchang and traditional time windows.
- Every tithi interval shows paksha, start and end, sunrise marker, and whether it continues beyond midnight. Three-tithi civil dates display all three intervals, without gaps. A date boundary is explicitly distinguished from a tithi transition.
- Reading body text is 17px and detail values 16–17px where space permits. Calendar grid typography remains compact to keep six weeks visible on small screens. No text is intentionally truncated in the new day-details/Discover reading cards.
- App version 1.0.0+30; QA APK version verification derives the expected build number from pubspec.yaml.

## Validation completed locally

- Flutter 3.47.9 / Dart 3.13.7: `flutter analyze --no-pub` — no issues.
- Full Flutter suite: 83 tests passed, including small-screen calendar layouts and new Hindi/English day-details and Discover checks at 1.0 and 1.6 text scale.
- Rendered Hindi and English Discover and day-details screens reviewed at 360×800, including a date with two tithi changes.
- Standalone Dart verification: all 89 bilingual/source records; all 12 months; priority and deduplication; 732 civil-day timelines, including 34 triple-tithi cases.
- Production source validation and six Android permission audit regressions passed.
- Both workflow YAML files parsed; their shell blocks passed bash syntax checking. Git diff whitespace check passed.

Android APK/AAB compilation and native Gradle tests were not run locally. CI remains configured on Flutter 3.47.5 and builds the Android artifacts. No remote GitHub source changes were made in this task.

The full editorial inventory is in DISCOVER_CONTENT_CATALOG.md; implementation notes are in DISCOVER_REVIEW.md.
