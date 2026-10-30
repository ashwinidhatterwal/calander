# Build 32 — Specific teachings and stories in Discover

Version 1.0.0+32. Includes the complete previous calendar, Vikram Samvat, day-details and three-section Discover implementation.

Discover now has 48 additional original bilingual readings (137 records total), including 10 from the Kautilya/Chanakya tradition's Arthashastra, 12 from the Upanishads, four each from Vidura, Tiruvalluvar, Patanjali, Kabir, Vivekananda and the Dhammapada, and two Jain teachings. The Hindu spiritual and philosophical traditions remain the main focus. Buddhist and Jain teachings are identified explicitly rather than presented as Hindu scripture.

Each new card shows the named thinker or tradition, the passage/chapter reference, a paraphrase or story-retelling label, a concise explanation, an individual practice/reflection and a working source action. The app-authored prompts are suggestions, not statements attributed to the ancient author. Tagore's numbered Kabir selections are identified by that collection rather than an invented original doha number. Arthashastra references identify book and chapter; they are not unsourced internet quotations labelled Chanakya Niti.

The three fixed sections remain. Actual festival and matching tithi readings keep spiritual priority; on other days a varied cycle of specific spiritual readings replaces generic monthly overviews. The philosophy cycle includes the new teachers alongside the existing eight Gita readings, spreading a teacher's entries through the cycle. Every new reading is reachable. Today’s facts retains dated anniversaries when available and labelled heritage facts otherwise. The deeper collection does not create a longer feed.

All readings are bundled offline. Sources were checked on 30 October 2026. Reading suggestions do not establish festival dates or claim religious narratives as documented history. Traditional accounts are summarized respectfully; no long modern translations or articles are reproduced.

## Validation

- All 86 Flutter tests passed, including 360-day new-content reachability and teacher rotation, 365-day section separation and fact selection, festival/tithi priority, calendar/day-details regressions and narrow-screen Hindi/English layout at normal and 1.6 text scale.
- Flutter analysis: no issues found.
- Rendered Hindi/English Discover screens reviewed, including the teacher/reference labels and individual reflection panels.
- Source validator and all six Android permission audit tests passed.
- Both workflow YAML files parse; their shell steps pass bash syntax checks; package and artifact labels identify build 32.
- Pure-Dart verification passes for 137 sourced bilingual records, every Hindu month and 732 civil-day tithi timelines. Local Flutter checks use 3.47.9; the existing Android workflows retain their configured Flutter version. APK/AAB compilation and native Gradle checks are not available in this local environment. GitHub is not modified by this delivery.
