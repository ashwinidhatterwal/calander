# Hindu Calendar — Checkpoint 12 Location Reliability and Today Times

Build 1.0.0+12 adds explicit GPS/network acquisition, visible failure diagnostics, coordinate-based districts, and localized 12-hour sunrise/sunset. Includes prior reminder, holiday and UI fixes. See `docs/CHECKPOINT_12.md` for research, scope and verification status.

## Release identity

- App name: `हिन्दू कैलेंडर` / Hindu Calendar
- Version: `1.0.0+12`
- Android application id: `in.hinducalendar.hindu_calendar`
- Main Panchang profile: North India / Purnimanta
- Backend/account required: No
- Advertising: No
- Paywall: No

## Core app

- Normal month calendar with large, clearly separated date tiles.
- Tithi visible directly under each Gregorian date.
- Major festival/vrat label inside the date tile.
- Swipe left/right with resistance to change month.
- Tap month/year to jump directly to another month or year.
- Detailed Day page with Tithi, Paksha, Maas, Nakshatra, Yoga, Karana, Sun/Moon times and useful periods.
- Major festival browser with a bilingual Holidays category combining national and local state dates.
- Personal **My Days** calendar.
- Personal events can follow either a Gregorian date or Hindu Maas + Paksha + Tithi.
- Local event persistence.
- Selected language, manual city or saved current coordinates, and appearance persist across restarts.
- First-use current-location offer; foreground location only after a tap, with refresh and manual-city fallback.
- Today is the only persistent highlighted date, and the top Panchang card always shows Today.
- Coordinates and UTC offset participate in all location-dependent cache keys.
- Hindi and English.
- **Light mode is the default.**
- Optional dark mode is available under About → Appearance.
- Android home-screen widgets continue to follow the phone's widget/system theme.
- Widget picker previews use the real widget layouts with representative sample data.
- Warm native launch surface followed by branded Flutter loading screen.
- Single-task Android behavior to avoid duplicate Recents cards.

## Optional developer support

The app is fully usable without payment. There is no premium tier and no automatic support prompt.

The support section lives quietly inside **About**. Its wording is intentionally personal rather than promotional: if the app is useful and the user wants to help future development, they can optionally send the developer a contribution of their choice through an external UPI app.

Supporting never changes or unlocks any digital feature.

As a personal thank-you, a supporter may optionally email their name and postal address to request a physical handwritten note from the developer. The app itself does not store the postal address.

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
Checkpoint 12 source validator
release QA APK
Target API verification
permission audit
```

Expected artifact:

```text
hindu-calendar-1.0.0-build11-qa-apk
```

### Play Store AAB

Run **Production Play bundle** manually after configuring release secrets. It creates a signed, obfuscated Android App Bundle plus Dart symbols.

Expected artifacts:

```text
hindu-calendar-1.0.0-build11-play-aab
hindu-calendar-1.0.0-build11-dart-symbols
```

The upload keystore and passwords must never be committed to this public repository.

## Validation boundary

Checkpoint 11 changes reminders, task launches, district labels and civil holiday presentation. It does **not** alter Panchang astronomy, Tithi/month calculations, festival-date selection rules, or personal-event matching. Ordinary notification permission is required; Android may defer delivery after 5 AM. Force-stop blocks reminders until the app is reopened. District fallback data is a reference dataset, not a certified current administrative map.
