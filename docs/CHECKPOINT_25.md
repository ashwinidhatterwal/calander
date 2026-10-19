# Build 25 - month labels and adaptive date cards

## Behaviour

PDF cards use the Hindu month already calculated for each civil date at
sunrise, including Adhik prefixes and the saved location/language. The month
occupies the line below tithi. Paksha moves to the bottom left; Gregorian
date remains bottom right. Other PDF positions, theme, fonts and QR are kept.

The app grid fills its actual LayoutBuilder viewport rather than being capped
at 88 text-scaled pixels. Four/five/six rows share available height after
spacing and bottom padding. Tile height never falls below 52 pixels times
text scale (at least 1). Small vertical windows can scroll. Below 298 logical
pixels, the grid retains 36-pixel columns and allows horizontal scrolling.
The 0.01-pixel sizing tolerance prevents rounding-only vertical scrollbars.

## Validation

- Production Dart sizing helper executed: 84 combinations across four/five/six
  rows, seven viewport heights and four text scales pass, plus month-grid and
  unbounded-height checks. Dart analysis of the pure layout helper passes.
- All 48 regular/Adhik month labels across Hindi and English fit the PDF line,
  using shaped advances from the actual bundled font. Longest is Adhika
  Margashirsha, 124.475 out of 138.57 design pixels available.
- Compact six-row card design samples rendered with the actual fonts and
  inspected, including long Hindi/English month labels and paksha/date spacing.
- Native PDF exporter and footer-link Kotlin compiled successfully against
  Android 35 stubs (production source compilation, not runtime tests).
- Source validator: 81 checks pass. Permission audit: 6 tests pass.
- Flutter regression coverage extended for tall screens, viewport/minimum
  sizing and every PDF card's date-specific month. Native PDF page-drawing
  fixture includes a long Adhik month label.

## Remaining verification

Full Flutter UI tests, native runtime tests, APK and signed AAB builds must
run in GitHub; this workspace has no Flutter SDK. The desktop font/layout
checks do not replace the Android PDF runtime or device UI tests. Test normal,
large-text and split-screen layouts, and new Hindi/English month/year PDFs,
on the phone before public rollout.
