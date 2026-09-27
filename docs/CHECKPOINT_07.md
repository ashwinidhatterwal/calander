# Checkpoint 07 — Production Candidate

Checkpoint 07 is the release-hardening pass for Hindu Calendar 1.0.0.

## Product promise
- No ads.
- No paywall.
- No forced account.
- Core Panchang and personal-calendar functionality remain free.
- Optional developer support never unlocks digital functionality.

## Release hardening
- Version bumped to `1.0.0+7`.
- Permanent Android application id retained: `in.hinducalendar.hindu_calendar`.
- System light/dark theme support added.
- Selected language and city persist across restarts.
- Native loading surface now has both light and dark launch colors.
- Launcher/widget/single-task behavior from Checkpoint 06 retained.
- About, privacy and open-source license surfaces added.
- UPI support launch and handwritten-note request are defensive against missing external apps.

## Voluntary support design
The support entry lives under **About** and never appears as an automatic dialog or banner.

The app explicitly states that:
- support is optional;
- no feature changes if the user does not support;
- the payment is a voluntary developer tip, not a charitable donation;
- no digital feature, badge, theme or content is unlocked;
- UPI payment happens in an external app;
- the calendar does not read banking credentials or payment results.

After supporting, a user may optionally request a **physical handwritten thank-you note**. The app opens the user's email client; postal information is not stored in the calendar app.

## Production artifacts
Two workflows are now separated:

### Android QA build
Runs on pushes and produces a QA APK after analyze/test.

### Production Play bundle
Manual-only. Requires upload-key and support configuration in GitHub Actions secrets, then produces:
- signed Android App Bundle (`.aab`);
- Dart obfuscation symbols.

The production bundle is the artifact intended for Play Internal testing and later production rollout.

## Privacy / Play preparation
- Public privacy-policy HTML included under `store_web/`.
- GitHub Pages deployment workflow included.
- Hindi and English Play listing drafts included.
- Data Safety guidance included.
- Release signing / Play Console checklist included.

## Accuracy scope
The trusted Panchang/festival engine is unchanged in Checkpoint 07. The main profile remains North Indian Purnimanta. Regional traditions may differ and should not be presented as globally identical.
