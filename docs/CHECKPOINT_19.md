# Build 19 — compact translucent widgets

Both widgets request 3x1 launcher cells, with 220dp default width, 180dp minimum
resize width and 64dp minimum/default height. Existing launcher instances must
be removed and re-added to apply the new slot hints. Launchers determine actual
grid bounds, so one row is a request rather than a universal guarantee.

Move the rounded background and padding to the natural-height content column.
The root stays transparent and centres that card, even in an enlarged slot.
Use 6dp vertical padding and remove row margins. Daily date and lunar month share
one line; tithi and sun times retain separate rows. Title autosizing is retained.
Very long content may still ellipsize at the smallest size; users can enlarge it.

All four background resources use alpha 0x59: 89/255 opacity, approximately 35%
opaque and 65% transparent. Text colours remain unchanged and fully opaque.
No parent view alpha is used. Remove the formerly opaque outline.

Build version and both CI artifact labels advance to 1.0.0+19.

Passed locally: XML parse, targeted compact-card/alpha assertions, source
checkpoint validator, six permission-audit tests, scaffold shell syntax.
The prior temporary Android toolchain is no longer present; resource compilation,
Flutter/native tests and device rendering are not claimed for this revision.
Existing GitHub workflows run full checks before creating APK/AAB artifacts.

Device QA: remove/re-add both widgets, resize to one row, inspect normal/larger
font settings and long Hindi/English text, verify translucent background over
wallpaper, opaque readable text and tap-to-open behaviour.
