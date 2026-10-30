# Build 35 — Contextual readings, gentle ratings and developer contact

Version 1.0.0+35. Based on build 34, whose GitHub QA run 41008923668 passed both native regressions and APK compilation. All 260 source files from that commit (737509db4ff46a056ea580d28247297c183287ab) matched the baseline archive before editing.

## Context for the teachings

72 readings now identify the speaker/listener or the original teaching setting. All 21 Gita readings say **श्रीकृष्ण ने अर्जुन को समझाया—**, and their Hindi bhavarth addresses the reader in the natural voice of the teaching. Other entries preserve their own context: Yama/Nachiketa, Uddalaka/Shvetaketu, Yajnavalkya/Maitreyi, Vidura/Dhritarashtra, teachers addressing departing students, or a named work/lecture. A dialogue is not invented for aphorisms or historical facts.

Original Sanskrit, source references and the bhavarth/story-retelling labels remain distinct. Context appears in the app, copied text and branded Panchang images. The existing three sections and 155-record inventory remain.

## Non-intrusive Play Store rating invitation

- The first prompt becomes eligible 24 full hours after Android's PackageManager firstInstallTime. App updates keep the original installation baseline. If the platform timestamp is unavailable, a persisted first-use timestamp supplies a conservative fallback.
- Closing with X, Not now, Android Back or the outside barrier defers another invitation for **28 days**. The cooldown is persisted before display, including across process death/restarts.
- **Don’t ask again / फिर न पूछें** disables automatic prompts. Successfully opening Google Play also stops automatic reminders; the app does not claim to know whether a rating was submitted.
- The dialog appears only on the foreground home route, after eight quiet seconds. It defers to location dialogs, editors, sharing previews and ongoing pointer interactions. There is at most one automatic offer per foreground session. It never runs in notification/background workers.
- The neutral invitation links to the app's Play listing. No star rating is preselected and no opinion question filters who can leave a public review. A manual Rate on Google Play entry remains in About. The Play app is tried first, then the HTTPS listing.
- Local preferences only; no added SDK, background service, notification or permission.

The rating action opens the Play listing instead of depending on an unconditionally visible in-app-review API flow. See [Google Play review guidance](https://developer.android.com/guide/playcore/in-app-review#quotas) for CTA and quota behaviour.

## About developer section

A developer card shows **Ashwini Dhatterwal** (optional DEVELOPER_NAME override) and the existing **SUPPORT_EMAIL** configured for the release. The email is reused rather than replacing it with an inferred personal address or a placeholder. Existing QA and production workflows already pass SUPPORT_EMAIL; production validates that it is present. Local builds without it show a graceful unavailable state.

The contact can be selected, copied or opened in the user's email composer. No email is sent automatically. The card uses flexible text and wrapped actions for narrow screens and larger text sizes. Existing support, privacy, appearance and licenses remain available.

## Validation

All 112 Flutter tests passed. This includes installation-age/cold-start persistence, exact 28-day retry boundary, opt-out/reinstall behaviour, the native timestamp bridge contract, editor/background/idle deferral, store-opening lifecycle changes, dismissal methods, developer-email copying, source-specific speaker context and all prior calendar/sharing regressions. Flutter analysis reports no issues. Source validation, all six permission-audit tests, workflow YAML and shell syntax checks also passed. Pure-Dart verification passes for 155 sourced records, all 12 Hindu months and 732 civil-day timelines, including 34 triple-tithi cases. Screens were rendered at 360-pixel width in Hindi and English, normal/1.6 text scale, with light/dark rating-dialog variants. Shared-poster context was visually reviewed.

No Android SDK/Gradle runner or physical Android device is available locally. The new installation-time bridge must therefore be compiled and exercised by the next GitHub build/device run. The previously fixed native sharing regression tests remain included. GitHub was not modified by this delivery.
