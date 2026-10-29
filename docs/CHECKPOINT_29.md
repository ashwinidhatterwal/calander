# Build 29 — Daily discoveries and Hindu calendar heading

Based on GitHub main commit 317b5969afb9b719da99dcc2076a5fd7bc63c94d.
Carries forward the earlier build 28 daily discoveries and Samvat changes.

- Fourth bottom destination: ज्ञान / Discover, with daily cultural reading and matching-date historical anniversaries.
- Offline bilingual editorial collection: 18 rotating cultural cards and 10 dated records; cards repeat after the collection cycles. Each includes a source link and copy action. No runtime feed or background polling.
- Date rollover refreshes when active or reopened.
- Primary calendar heading: Vikram Samvat, Hindu month range, then smaller Gregorian month/year. Uses the existing location-aware Panchang engine and Chaitra year boundary.
- Existing month navigation and selector retained.

Validation: source and permission checks run locally. Flutter SDK is unavailable, so Flutter analysis, widget tests, visual rendering and Android build require CI/device verification.
