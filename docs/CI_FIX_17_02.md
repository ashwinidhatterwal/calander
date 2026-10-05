# CI17-02: clock-race in native delayed-notification test

Failed QA run 37297096616, job 111720792474, source 74b2554c2277b115a3826ff53dc6132633afbf15.
Flutter analyze, Flutter tests, source checks and release APK build passed.
Native suite: 19 completed, 18 passed. Failure was CalendarAlertsTest.kt line144.

The test read System.currentTimeMillis before calling the scheduler, while the
scheduler read it again after permission/channel checks. Expecting exact
millisecond equality made the test dependent on execution speed. It now checks
that scheduledAt minus 60 seconds is within the before/after call interval.
The exact AlarmManager timestamp, pending intent, early-delivery exclusion,
retry handling and once-only delivery assertions are retained. No product
scheduling or notifications changed to satisfy the test.

Workflow hardening: Ubuntu24.04 and Java17 selected explicitly; native tests
run before release packaging; Flutter/native logs and JUnit/HTML reports saved
on success or failure. Pipefail preserves real failures through tee. No failing
application test is retried or ignored. Secret-bearing signing files are not
included in diagnostics. Existing publishing, manifest and signing checks stay.

Local: source/permission checks, workflow structure checks and ZIP verification.
Full native/Flutter suite still requires the next GitHub run. The preceding run
is evidence of 18 native successes, not a claim that the revised suite was run.
External GitHub/download/service outages cannot be guaranteed away.
