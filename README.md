# Hindu Calendar — Checkpoint 13 Notification Reliability

Build 1.0.0+13 fixes missed-reminder recovery, separates Panchang and event timing, and adds immediate/background notification tests with visible status. All location, Hindi time-format and calendar fixes are retained. See `docs/CHECKPOINT_13.md`.

## Release identity

- App name: `हिन्दू कैलेंडर` / Hindu Calendar
- Version: `1.0.0+13`
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
Checkpoint 13 source validator
release QA APK
native notification regression tests
Target API verification
permission audit
```

Expected artifact:

```text
hindu-calendar-1.0.0-build13-qa-apk
```

### Play Store AAB

Run **Production Play bundle** manually after configuring release secrets. It creates a signed, obfuscated Android App Bundle plus Dart symbols.

Expected artifacts:

```text
hindu-calendar-1.0.0-build13-play-aab
hindu-calendar-1.0.0-build13-dart-symbols
```

The upload keystore and passwords must never be committed to this public repository.

## Validation boundary

This checkpoint changes notifications and their settings; astronomy, festival dates and personal-event date matching are unchanged. Notification permission and an enabled notification channel are required. Optional user-granted **Alarms & reminders** access enables precise selected times; inexact fallback remains available. Force-stop requires reopening the app. A successful test means Android accepted the notification, not that the user saw it or heard it through DND.

See `docs/BUILD_STATUS.md` for checks actually executed and remaining device validation.
