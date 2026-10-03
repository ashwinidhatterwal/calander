Hindu Calendar build 14 — full source package

Upload the complete contents to ashwinidhatterwal/calander.
Keep flutter_app/, tools/ and .github/ at the repository root.
Android QA build produces the APK and runs Flutter plus native tests.
After QA succeeds, run Production Play bundle on main for the signed build14 AAB.
Existing signing/support secrets and the corrected Gradle task dependency are retained.

Changes:
- Location saved message disappears after three seconds, including its Details action.
- Daily Panchang and Personal events default ON; both default to 6 AM.
- Previously saved switches and custom times are preserved.
- One-minute test requires Alarms & reminders access and explains it before scheduling.
- A persistent worker backs up the exact alarm; duplicate callbacks cannot post twice.
- Test scheduling/delivery/failure details can be copied from notification status.

Retest: menu > Notifications > Test in one minute.
If prompted, enable Alarms & reminders, return and tap the test again.
Close the app normally and check the notification panel after about one minute.
If delivery fails, copy the notification status report, including lastTestResult,
testScheduled, lastAlarm, lastTestPosted, precise and batteryRestricted.
If your old switches/times were saved, select the desired values once in Notifications.
