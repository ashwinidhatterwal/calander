# Build 21 — tithi-first cards and calendar PDF sharing

Based on GitHub main 47a2387 (build 19), incorporating all build 20 widget
readability and 40% transparency resource changes from the saved full source.
Version: 1.0.0+21.

## User-visible changes

- Monthly cards show bold tithi first, optional festival/event in the middle,
  and the Gregorian date at the bottom. Minimum cell height adapts to text
  scaling and prevents clipping on narrow phones.
- Three-dot menu → Share calendar PDF offers the displayed month (one page)
  or its full January–December year (12 pages, one month per page).
- Each landscape A4 page uses the app's warm cream/saffron styling. Tithi,
  paksha, festivals/vrat and national holidays are shown. Calculations use the
  saved location and the existing sunrise-tithi convention, in IST.
- A small footer promotes Hindu Calendar and links to its Google Play listing.
  No advertising covers calendar cells. Personal events are excluded.
- The export follows the selected app language. A bundled OFL-licensed Noto
  Sans Devanagari font preserves Hindi shaping in every viewer.
- Uses Android's share chooser with temporary read access to a PDF in the
  app's private cache. No storage or network permission is added.

## Implementation and practical limits

Pages are rendered at 1684×1190 and embedded losslessly in PDF 1.4. This keeps
Hindi text reliable across viewers. PDF text is raster content rather than
selectable text. A single page image is held at a time. Representative output
sizes were about 125–145 KB monthly and 1.5–1.7 MB yearly, varying by content.
The PDF is print-friendly light theme even if the app uses dark mode.

## Verification completed

- Offline Dart analyzer (Flutter 3.47.7 / Dart 3.13.5): zero issues.
- Actual Flutter engine export: Hindi and English monthly PDFs each contain
  exactly one page; full leap-year PDFs each contain exactly 12 A4 pages.
- Poppler rendered-page visual review: Hindi matras, English text, six-row
  March 2024, February 29 and festival-heavy October. Link annotations checked.
- Actual engine UI checks at 320 and 400 logical pixels: bold tithi above
  bottom date; both export choices present; no RenderFlex/layout errors.
- Existing checkpoint source checks and all six permission-audit tests pass.
- Android sharing regression tests added for Android 9 content URI access,
  MIME type/read grant and rejection of invalid PDF data/path traversal.

## Remaining checks

Full Flutter test-runner suite, native Android tests, APK/AAB compilation and
real-device share chooser delivery must pass in GitHub/on a phone. No APK or
AAB was built locally. CI still uses its existing pinned Flutter 3.47.5.
Standard local Flutter setup was blocked by automatic approval review due to
instance-metadata access. Completed local checks used a network-denied process
and public cached SDK/dependency files; no metadata access was permitted.

Upload all ZIP contents including .github, wait for QA, then run Production
Play bundle on the same commit. Test monthly/yearly sharing in both languages
before publishing version code 21.
