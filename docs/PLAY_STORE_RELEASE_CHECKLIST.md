Current source candidate: **Checkpoint 11 / 1.0.0+11**. Use `docs/CHECKPOINT_11.md` and its verification report for current scope and outstanding checks. Upload only the production-signed bundle, after CI and device checks pass, to the existing closed testing track.

# Play Store Release Checklist — 1.0.0

## Identity
- Permanent Android application id: `in.hinducalendar.hindu_calendar`
- App name: `हिन्दू कैलेंडर` / Hindu Calendar
- Version: `1.0.0+9`
- Android launcher icon: Checkpoint 06/07 production icon

Do not change the application id after the first Play release.

## Release signing
The repository never contains the upload keystore or passwords.
For this update, reuse the existing upload keystore and GitHub Actions secrets. Do not create a replacement signing key. First-time setup only:

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
Checkpoint 09 intentionally has no paywall and no automatic support prompt.
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

## Closed-testing build +9
1. Copy the updated source into the existing repository; keep repository secrets unchanged.
2. Require **Android QA build** to pass analyze, all tests, Checkpoint 09 validation, build and merged-manifest permission audit.
3. Run **Production Play bundle** using the existing upload-key secrets.
4. Require its signed AAB build, signature verification and AAB permission audit to pass.
5. Upload that AAB to the existing Closed testing track and roll out to the existing testers.
6. Verify approximate/precise permission, denial, device location disabled, saved-location restart offline, explicit refresh, widget refresh, Today-only selection, and the three national holidays on real devices.
7. Publish the updated privacy-policy source using the existing Pages workflow.

## First release Play Console setup
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
