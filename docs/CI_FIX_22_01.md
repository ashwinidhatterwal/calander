# Build 22 native test compilation correction

Historical first correction. The subsequent run exposed two layout failures;
see CI_FIX_22_02.md for the current, locally executed correction.

Failed QA run: https://github.com/ashwinidhatterwal/calander/actions/runs/39096030758
Commit: 50858abb10e1af49742388c927af739a64363b35.

Flutter analysis and all 63 Flutter tests passed. Native test compilation stopped
before APK packaging because WidgetLayoutTest imported
androidx.test.core.app.ApplicationProvider without declaring AndroidX Test Core.

The test now obtains its explicitly typed Context from
org.robolectric.RuntimeEnvironment.getApplication(), the same API already used
by CalendarAlertsTest in this project. Robolectric is already an explicit test
dependency. This removes the missing dependency instead of adding a library.
All widget layout assertions remain enabled.

Only the test import and context setup changed. App behavior, widget resources,
PDF layout/QR, signing configuration and version code 22 are unchanged.

Validation: compared the complete local source against the failed-run commit;
only WidgetLayoutTest differs before packaging/documentation updates. Existing
source checks and all 6 permission-audit tests pass. Native test compilation
and execution need a fresh GitHub run; they have not been verified locally.

Upload the corrected complete ZIP contents and commit to create a new QA run.
Rerunning the old failed job uses its old commit. After the new QA run passes,
start Production Play bundle on that same updated commit.
