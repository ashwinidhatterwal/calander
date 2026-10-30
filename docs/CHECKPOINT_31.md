# Build 31 — Three focused Discover sections

Version 1.0.0+31. Builds on build 30’s verified calendar and day-details work.

Discover now presents exactly one reading in each of three fixed daily sections:

1. **Spirituality and good practices / अध्यात्म और अच्छी आदतें** — a spiritual or traditional reading, preserving observance/tithi/month relevance, followed by a short optional practice.
2. **Morality and philosophy / नैतिकता और जीवन-दर्शन** — a rotating philosophical reflection with a relevant question for everyday life.
3. **Today’s facts / आज की जानकारी** — a historical event on its matching civil date, or a rotating cultural/heritage fact explicitly labelled as a daily discovery.

The existing 89 editorial records are unchanged in number. Separate pools prevent the same reading appearing in multiple sections. The long expandable reading feed and Read more button are removed. Source links and copy actions remain. Practice prompts and reflection questions are app-authored suggestions, not scripture quotations.

## Validation

- All 84 Flutter tests passed, including the three section headings at normal/1.6 text scale in Hindi and English, calendar layouts, day details and existing engine/export regressions.
- Flutter analysis: no issues.
- New year-long selection check: 365 days have distinct sections; philosophy and general facts rotate; historical anniversaries match the date; record count stays 89.
- Rendered Hindi/English Discover screens reviewed, including reflection and fact cards.
- Production source validation and six Android permission audit tests passed.

Local validation uses Flutter 3.47.9; Android workflows remain on their existing Flutter version. APK/AAB compilation and native Gradle tests were not run locally. GitHub was not modified.
