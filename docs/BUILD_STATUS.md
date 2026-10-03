# Build status — checkpoint 14

Source version 1.0.0+14. The build13 baseline passed GitHub QA run 37104758173
at 0a36bae83a5396607dd228d16a6bbbbdb98ed9ae. The asset-task dependency repair
from CI fix 13-02 is retained in both QA and production scaffolding.

Passed locally for build14:
- Native Android compilation of CalendarAlerts, MainActivity, DeviceLocation and
  ReminderPolicy against real Android/Flutter classes and app resources.
- CalendarAlertsTest: 12 tests; ReminderPolicyTest: 2 tests; zero failures/errors.
  This includes API31 exact-alarm access denial, selected/default preferences,
  delayed test scheduling and due-time gating, superseded callbacks, duplicate
  suppression, permission recovery, stale-test expiration and prior daily/event
  cache and delivery regressions.
- 57 checkpoint14 source/geometry checks and six permission-audit unit tests.
- Scaffold shell/embedded Python syntax, workflow YAML and whitespace checks.
- Standalone Dart formatter/parser checked all changed Dart sources and tests.

Native harness: SDK36 compile target, Robolectric4.17 with API28/API31 simulations,
Gradle8.14.3, AGP8.11.1, Kotlin2.1.0, JDK17, Flutter3.47.5 embedding and real native
notification/widget resources. Unchanged HomeWidget provider classes are excluded
from this independent harness because the full Flutter plugin graph is not
installed locally. This is not a complete APK/AAB or physical Android16 test.

Flutter widget regressions were added for both Hindi/English location message
expiration, the exact-access settings flow and both 6AM defaults. Those tests,
full Flutter analysis and APK/AAB generation require the updated GitHub workflows.
Local Flutter dependency setup was previously blocked by automatic approval review
for an attempted cloud instance-metadata connection; no workaround was attempted.
Standalone native testing and offline Dart formatting do not run Flutter pub.

The tester confirmed the immediate notification works on their phone. The delayed
path must be retested after installing build14 and granting Alarms & reminders.
Without a device report, the precise cause on that phone is not conclusively
identified; the confirmed silent inexact fallback has been removed from the
one-minute test and new persistent recovery/diagnostics cover delayed failures.

Package release steps: upload the full source ZIP, wait for new QA success, then
run Production Play bundle for the signed build14 Play Store AAB. Signing secrets
and application ID are unchanged. Saved switches and custom times are retained.
