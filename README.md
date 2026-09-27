# Hindu Calendar — Checkpoint 07 Production Candidate

Checkpoint 07 prepares the app for a first Google Play release while preserving the product direction established in earlier checkpoints: a familiar daily calendar with Hindu Tithi/Panchang intelligence, personal Hindu-date events, useful widgets, and a Hindi-first interface.

## Release identity

- App name: `हिन्दू कैलेंडर` / Hindu Calendar
- Version: `1.0.0+7`
- Permanent Android application id: `in.hinducalendar.hindu_calendar`
- Main Panchang profile: North India / Purnimanta
- Backend/account required: No
- Advertising: No
- Paywall: No

## Core app

- Normal month calendar with large date tiles.
- Tithi visible directly under each Gregorian date.
- Major festival/vrat label inside the date tile.
- Swipe left/right with resistance to change month.
- Tap month/year to jump directly to another month or year.
- Detailed Day page with Tithi, Paksha, Maas, Nakshatra, Yoga, Karana, Sun/Moon times and useful periods.
- Major festival browser.
- Personal **My Days** calendar.
- Personal events can follow either a Gregorian date or Hindu Maas + Paksha + Tithi.
- Local event persistence.
- Selected language and city now persist across restarts.
- Hindi and English.
- System light/dark theme.
- Theme-aware Android home-screen widgets.
- Warm light/dark native launch screen followed by branded Flutter loading screen.
- Single-task Android behavior to avoid duplicate Recents cards.

## Optional developer support

The app is fully usable without payment. There is no premium tier.

A quiet **About** screen contains an optional voluntary developer-tip flow. It never opens automatically and never grants any digital feature, content, badge, theme, or status.

The production build can inject a UPI destination through GitHub Actions secrets. After supporting, a user may optionally request a **physical handwritten thank-you note** by opening their email app and sending a postal address to the developer. The app itself does not store that postal information.

See `docs/SUPPORT_POLICY.md` and `docs/DATA_SAFETY_GUIDE.md`.

## Privacy

Core calendar data stays on the device. The project contains no advertising SDK and no behavioral analytics SDK.

A public privacy-policy page is included in `store_web/privacy.html`, plus a GitHub Pages deployment workflow.

## Build workflows

### QA APK
Pushes to `main` run `.github/workflows/android.yml`:

```text
flutter pub get
flutter analyze
flutter test
production-source validator
release QA APK
Target API verification
```

Expected artifact:

```text
hindu-calendar-1.0.0-qa-apk
```

### Play Store AAB
Run **Production Play bundle** manually after configuring release secrets. It creates a signed, obfuscated Android App Bundle plus Dart symbols.

Expected artifacts:

```text
hindu-calendar-1.0.0-play-aab
hindu-calendar-1.0.0-dart-symbols
```

The upload keystore and passwords must never be committed to this public repository.

See `docs/PLAY_STORE_RELEASE_CHECKLIST.md`.

## Validation boundary

Checkpoint 07 does not alter the Panchang astronomy/festival-rule engine. The existing reference regression suite remains the calculation trust boundary. Any future changes to Tithi/month/festival calculations should require regression coverage before release.
