# Build 18 — widget layout refinement

## Changes
- Centre the whole content block with a FrameLayout and a natural-height column.
- Remove the 48dp launcher icon, 54dp badge, side margins and chevron that took
  width away from content. Delete the now-unused chip drawable.
- Use one explicit 10dp inset instead of background-owned hidden padding.
- The weighted title takes natural height when space permits and yields space
  to date/month/sun rows when constrained. Native TextView autosizing fits the
  title from 19sp down to 12sp, with two daily/three festival lines.
- Restore Android font padding for Hindi combining marks; reserve separate
  footer rows. Extremely long custom names may still end in an ellipsis.
- Narrow the daily minimum width to 160dp and festival width to 220dp. Increase
  minimum heights to 140dp/116dp so required rows have safe space. Android 12+
  placement hints are 2x2 and 3x2; launcher grid rules determine actual bounds.
- Rerender on resize through the existing HomeWidgetProvider data path.
- Warm opaque surface, restrained 20dp corners and a subtle themed outline.
- Version and QA/production artifact names advance together to 1.0.0+18.

## Verification
Passed: AAPT2 compile/link against Android API 35, source checkpoint validation,
six permission-audit tests, XML parse and shell syntax checks.
Not run: Flutter build/analyze/test, native runtime tests, launcher rendering.
Existing CI runs the Flutter/native suites before creating APK/AAB artifacts.

## Device acceptance
Install QA APK, replace both widgets, then check minimum/enlarged sizes in Hindi
and English, light/dark wallpaper, portrait/landscape and increased font scale.
Confirm title and footer glyphs stay inside the card and tapping opens the app.
