# Build 24 - reduce PDF opening complexity

Built from the saved build 23 full-source package. Changes are confined to
PDF font assets, exporter drawing, its native layout test, version/artifact
labels, and source-validation checks. No Dart logic or widget layout changes.

## Cause and implementation

The supplied October PDF uses 17 Type 3 fonts. The bundled Noto font has
variable weight/width axes; Android/Skia may turn variable and synthetically
bold glyphs into Type 3 drawing programs instead of embedded font subsets.
The exporter now loads static 400 and 700 weight TrueType instances, with
GSUB/GPOS Hindi shaping preserved, once per document. It uses the bold face
rather than Paint.isFakeBoldText. The original variable font remains for
widgets to preserve their validated font metrics.

Identical QR pixel rows are merged into bands. For the actual bundled QR,
this reduces black rectangles from 2,124 to 354, preserving pixels and the
permanent Play listing URL. The 37-point footer icon is downsampled from
1024 to 128 pixels at decode time. Existing portrait geometry, colors,
calendar payload, vector text and footer-link code remain.

## Validation performed for this build

- Exporter and footer-link Kotlin compiled successfully against Android 35
  stubs with the Kotlin compiler. This is a production-source compilation,
  not a full Android APK build or Android runtime test.
- Source validator: 79 checks pass, including static-font table checks and
  bundled font paths. Permission audit: all 6 tests pass.
- A focused desktop Skia/HarfBuzz experiment reproduced Type 3 output with
  the variable font and embedded Type 0 fonts with the static faces. The
  resulting shaped Hindi/English text rendered correctly on visual review.
  This is evidence for the font change, not a benchmark of the complete
  exported calendar or a promise about every Android viewer.
- QR row coalescing was checked against the actual QR bitmap. No module or
  destination changes; new rectangles cover the same black pixels.
- Native page-design test updated to use the two production PDF faces and
  revised drawMonth signature. The existing widget font is unchanged.

## Remaining checks

Flutter/full Android build and native Robolectric tests were NOT rerun in
this workspace. Run both existing GitHub workflows on this commit. Then
regenerate monthly/yearly PDFs on the phone and compare opening in the same
viewer. Actual phone speed improvement is unconfirmed until that retest.
Previously exported PDFs retain their old font/drawing structure.
