# Play Store Release Checklist — 1.0.0

## Identity
- Permanent Android application id: `in.hinducalendar.hindu_calendar`
- App name: `हिन्दू कैलेंडर` / Hindu Calendar
- Version: `1.0.0+7`
- Android launcher icon: Checkpoint 06/07 production icon

Do not change the application id after the first Play release.

## Release signing
The repository never contains the upload keystore or passwords.
Create an upload keystore and add these GitHub Actions secrets:

- `UPLOAD_KEYSTORE_BASE64`
- `UPLOAD_STORE_PASSWORD`
- `UPLOAD_KEY_ALIAS`
- `UPLOAD_KEY_PASSWORD`

Encode the keystore on Linux/macOS:

```bash
base64 -w 0 upload-keystore.jks
```

On macOS where `-w` is unavailable:

```bash
base64 < upload-keystore.jks | tr -d '\n'
```

Then paste the resulting value into `UPLOAD_KEYSTORE_BASE64`.
Never commit the keystore or any password to the public repository.

## Optional support configuration
Checkpoint 07 intentionally has no paywall and no automatic support prompt.
To activate voluntary developer support in production, configure:

- `SUPPORT_UPI_ID`
- `SUPPORT_PAYEE_NAME`
- `SUPPORT_EMAIL`

`SUPPORT_EMAIL` is also used for optional handwritten thank-you-note requests.

## GitHub workflows
- **Android QA build**: runs on pushes, analyzes/tests and creates a QA APK.
- **Production Play bundle**: manual only, requires release secrets and creates a signed `.aab` plus Dart debug symbols.
- **Privacy policy site**: publishes `store_web/privacy.html` with GitHub Pages.

The Play Store upload artifact is the signed AAB from **Production Play bundle**, not the QA APK.

## Play Console
Before production rollout:
1. Enroll in Play App Signing.
2. Upload the signed AAB to an Internal testing track first.
3. Complete App access, Ads, Content rating, Target audience, Data safety and Privacy policy sections.
4. Use the public GitHub Pages privacy-policy URL.
5. Add support contact details.
6. Upload store screenshots and feature graphic.
7. Test install/update from Play Internal testing on at least two Android versions.
8. Verify widgets, dark/light theme, personal-event persistence, city/language persistence and UPI/email external-app flow.
9. Review the Pre-launch report before moving to production.

## Accuracy scope
The calendar currently targets a North Indian Purnimanta profile. Do not market the app as universally authoritative for every regional tradition. Keep Panchang-engine regression tests mandatory for any future astronomical/rule change.
