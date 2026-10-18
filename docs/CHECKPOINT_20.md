# Build 20 — larger, aligned widget text

Baseline: current GitHub main 47a23877591b00adbc0b3baf19ff2eaebf1cac1f;
183 packaged source/configuration files matched before modification.

Main text: 18sp -> 20sp. Metadata: 10sp -> 12sp. Footer: 11sp -> 13sp.
All text rows now support native TextView autosizing. Header/footer rows share
constrained height with the main title, so rigid rows do not squeeze the title.
Normal-height cards remain natural-height and centred with 6dp vertical padding.
One-row placement and resize metadata from build19 retained. Hindi font padding,
wrapping and centre alignment remain enabled.

All four background colour variants use alpha 0x99 = 153/255, exactly 60%
opacity / 40% transparency. Text colours are unchanged and opaque. No parent
alpha affects the text. Very long content at the smallest size can still require
an enlarged widget to display in full; Android launcher bounds are not universal.

Passed locally: checkpoint validator, six permission-audit tests, scaffold shell
syntax, XML parsing, targeted alpha/alignment/sizing/font-fitting assertions.
Full Flutter/native compile/test and launcher rendering were not available here.
Existing GitHub workflows run those suites before producing APK/AAB artifacts.

Device acceptance: inspect both widgets with Hindi/English, long festival names,
normal/larger fonts and small/enlarged slots. Verify footer and Hindi marks remain
inside the card, background transparency and fully opaque text, tap-to-open.
