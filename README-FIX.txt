HINDU CALENDAR — BUILD 22 COMPLETE SOURCE

Includes widget text layout repair, portrait PDF exports with Hindu/Gregorian
month headers and more daily details, natural Hindi app promotion and a Play
Store QR, Hindu month transition labels, and correctly sized month grids.

Upload ALL ZIP contents to the repository root, including .github. Wait for
Android QA build to pass, then run Production Play bundle on the same commit.
Download hindu-calendar-1.0.0-build22-play-aab for Play Console version code 22.

After updating, re-add existing widgets so the launcher applies the new sizing.
Test both widgets with Hindi/English, enlarged system text and widget resizing.

Local analyzer, source/permission checks, actual PDF rendering/QR decoding and
in-app layout checks passed. Both native widget layout tests now pass locally
across 72 cases on Android 9/15. Full GitHub workflows and phone testing remain
pending. Exact validation: docs/CHECKPOINT_22.md.

CI correction 22.01: fixed WidgetLayoutTest's undeclared ApplicationProvider
import by using the existing Robolectric RuntimeEnvironment API. Version stays
22. Upload/commit this corrected package to start a NEW QA run. Re-running the
old failed run will use its old source. See docs/CI_FIX_22_01.md.

CI correction 22.02: reproduced both subsequent native failures, fixed the
attached-view test fixture and actual Hindi font clipping. Strict native tests
pass against this final source. See docs/CI_FIX_22_02.md. Commit the updated
contents for a NEW QA run; keep version 22.
