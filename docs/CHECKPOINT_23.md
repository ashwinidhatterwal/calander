# Build 23 - compact month grid and scalable PDF text

## Changes

- Month card height uses the grid's actual available viewport and number of
  weeks. Reduced padding and a bounded, fitted title keep tithi bold at the
  top and date at the bottom. Month-transition and festival labels fit the
  intervening space. Large accessibility text can still scroll.
- The Today summary and app heading use bounded text so they do not consume
  the calendar viewport on narrow screens.
- PDF export retains the existing A4 portrait design and all date calculations.
  The Flutter service sends month data to Android; Android PdfDocument draws
  shaped Hindi/English text with the bundled font and vector card/QR shapes.
  Only the small app icon is raster. Footer link annotations are appended in
  an incremental PDF update, retaining original font and content streams.
- Version code and workflow artifact names/checks move together to 23.
- Build 22's widget font/layout repairs, Android 9 startup compatibility,
  reminders, main Durga Ashtami rules and final-week grid rules are retained.

## Validation

- Dart analyzer: no issues.
- Complete Flutter suite: 67 tests passed. This includes month/year export data,
  leap day, bilingual labels, PDF menu choices, Hindu-month transitions, and
  complete six-row month visibility at 360x740 and 400x800 in Hindi/English.
- Source validator: 74 checks passed.
- Android permission audit: 6 tests passed.
- Native Android/Robolectric harness: four parameterized JUnit executions
  passed on API 28 and 35. These cover 72 widget combinations and four PDF
  page-design drawing scenarios, using actual native font/Canvas rendering.
  Robolectric does not implement PdfDocument's PDF-generation JNI, so these
  tests deliberately test page drawing rather than pretend to generate PDFs.
- Real Android 9 runtime: all four exports generated successfully from the
  Flutter service's actual computed payloads. Monthly exports have 1 page;
  yearly exports have 12 pages, all portrait 595x842 points.
- All 26 exported pages were parsed independently: vector font resources are
  retained; the small app icon is the only raster image on each page. Glyph
  procedures contain vector paths rather than image drawing.
- Hindi and English six-row pages were rendered and visually inspected, also
  at high zoom. Both rendered QR codes decode to the permanent Play listing;
  all page footer links point to that same listing.

## Remaining checks

Full Flutter Android QA APK and signed Play AAB builds must pass on GitHub on
this exact source commit. The full app's sharing chooser and launcher behavior
still require phone testing; the local Android verification app is not a full
Flutter app release. Signing secrets and package/application ID are unchanged.
