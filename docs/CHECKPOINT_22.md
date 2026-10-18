# Build 22 — widget layout repair, portrait PDFs and accurate month grid

Based on current GitHub main 7f5c255 / build 21. Version: 1.0.0+22.

## Widgets

The old wrap-content vertical container contained weighted zero-height text
rows. Android had no dependable height to distribute to those rows. Both
widgets now use a bounded content container, distinct weighted text slots,
consistent 2dp outer / 10dp horizontal / 5dp vertical insets, font padding for
Hindi matras and native autosizing. The today header uses weekday/date rather
than squeezing an additional lunar month into the same line.

The default home-screen placement is two cells high with a 96dp minimum,
preventing a three-row widget from being forced into a single short cell.
The existing 40% transparency and opaque text are retained. Existing widgets
may need to be removed and added again to apply new launcher sizing metadata.
Resizing still refreshes the current widget data.

Native layout regressions cover both widget layouts, Hindi/English content,
compact/resized rectangles, font scales 1 / 1.3 / 1.6, on Android 9 and 15.
They check row bounds, text-layout height and ellipsis. Both tests now pass
locally against the final source: 72 combinations total. The fixture attaches
RemoteViews to a real test Activity and completes autosizing before measuring.
Android 8+ widgets use the app's bundled Hindi font for consistent measurement
and rendering. The autosize floor uses dp so enlarged system text does not
raise the minimum above the compact row height; the maximum still uses sp.
Launcher/device verification remains required. See CI_FIX_22_02.md.

## PDF

- All month pages are A4 portrait; monthly stays 1 page and yearly stays 12.
- Hindu month range and Gregorian month/year are both shown in the header,
  with Vikram Samvat, selected location and sunrise-tithi convention.
- Each card adds nakshatra, sunrise, sunset and tithi ending time to the
  existing tithi, paksha and festival/vrat. +1 explicitly means the next day.
- A separate footer promotes the app in natural Hindi with the app graphic
  and QR. Both footer link and QR use the permanent Google Play listing:
  https://play.google.com/store/apps/details?id=in.hinducalendar.hindu_calendar
- This is not a version-pinned APK/AAB URL. Google Play determines the latest
  compatible live version available to that account and release track. During
  closed testing, access still requires an eligible tester account. The public
  listing was not retrievable during this check; public availability is not
  claimed. No custom redirect service or future QR regeneration is needed.
- Personal events remain excluded from shared PDFs.

## In-app month grid

- The date where the sunrise Hindu month or Adhik status changes shows the
  new Hindu month name. This uses the same Purnimanta system as the app.
- Grid length is calculated as complete Sunday–Saturday weeks ending with
  the week containing the Gregorian month's last date: 4, 5 or 6 rows.
- Only unused cells in that last week show next-month dates; the extra whole
  next-month row and excessive bottom padding are removed.
- Card height accounts for the new month label and text scaling.

## Local verification completed

- Dart analyzer: zero issues.
- Actual Flutter engine: Hindi/English 1-page and 12-page portrait exports.
- Poppler/PDF checks confirm A4 portrait dimensions, page counts and links.
- Independent QR decoder reads the exact Play listing URL from both rendered
  language PDFs and the final October 2026 Hanumangarh sample.
- Rendered-page visual review covers six-row March 2024, both languages and
  the final five-row October 2026 sample, including Hindi text and footer.
- Actual UI-engine checks at 320/400 logical pixels pass for tithi/date order,
  month transition labels, final-week count, export choices and layout errors.
- Existing source checks, six permission tests and archive checks pass.
- Native widget tests pass with AGP 8.7.3, Gradle 8.11.1, Kotlin 2.1.0,
  Java 17 and Robolectric 4.17 native graphics on API 28 and 35. Rendered widgets
  were visually reviewed in Hindi/English on both APIs. The reusable
  tools/verify_widget_layouts.py stages the actual app resources and test.

The preceding GitHub run passed analysis and all 63 Flutter tests. The updated
full GitHub suite, APK/AAB compilation and launcher/phone tests remain pending.
Local engine verification used a network-denied process with
public SDK/dependency files; no cloud instance-metadata access was allowed.
