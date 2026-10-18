# Build 22: verified native widget layout correction

Failed QA run: https://github.com/ashwinidhatterwal/calander/actions/runs/39098047255
Commit: 6a1bd3852b8be7e949a55f03a10d3937ffcf9e52.

Analysis and all 63 Flutter tests passed. Native tests compiled and ran:
24 tests, with two WidgetLayoutTest failures on API 28 and 35. Both failures
were reproduced locally before changing the fixture or widget resources.

## Causes and fixes

The fixture measured window coordinates on unattached RemoteViews and did not
allow layout/autosizing to finish. It now uses a test Activity, drains the main
looper, completes layout passes, and measures rectangles within the widget.
System font scale is applied globally so RemoteViews-created contexts also
receive the requested scale. Every bounds, text-height and ellipsis assertion
remains enabled, without a clipping tolerance.

The corrected fixture then exposed real Android 15 Hindi clipping: a 16px text
layout in a 15px header at 180x80dp. Widgets now use the existing bundled Noto
Sans Devanagari font on Android 8+, making measurement and rendering consistent.
The scaffold copies the existing asset into Android resources; the source ZIP
does not duplicate the font. Older Android versions retain the sans-serif
fallback. Autosize minimums use dp so enlarged system text cannot force the
compact row beyond its available height; maximums still use sp.

## Executed verification

Both strict widget tests pass on API 28 and 35 with native graphics: two
widgets, two languages, three rectangles and three font scales, 72 cases total.
The final integrated source also passed through tools/verify_widget_layouts.py
in a fresh standalone Android module (BUILD SUCCESSFUL). The runner copies the
real widget resources and test rather than maintaining duplicate fixtures.
Requirements and command are in tools/widget_layout_verification/README.md.

Hindi and English renderings were visually reviewed on both APIs. Existing
source validation, all six permission-audit tests, shell syntax and diff
whitespace checks pass. No tests were skipped or assertions disabled.

This verifies the widget layout tests, not the complete app release build or
physical launchers. Commit the full updated ZIP contents to start a new QA
run. After it passes, run Production Play bundle on that same commit. Version
remains 1.0.0+22 because the failed build has not produced a release artifact.
