# Checkpoint 14

Version: 1.0.0+14. Builds on build13, including CI fix 13-02, verified by successful
GitHub QA run 37104758173 at commit 0a36bae83a5396607dd228d16a6bbbbdb98ed9ae.

## Location feedback

Flutter's current SnackBar defaults to persistent when it has an action. The
location success message had a Details action and no explicit persist value.
It now sets persist:false and duration:3 seconds. The location error message
also opts out of persistence while retaining its longer 12-second reading time.
Both Hindi and English paths retain Details. GPS and district logic are unchanged.

## Delayed notification testing

Previously the one-minute test used the general reminder alarm helper, which
silently fell back to setAndAllowWhileIdle if exact access was unavailable.
Android does not promise a one-minute deadline for that inexact API. Without
phone diagnostics we cannot prove that this was the only cause on the tester's
phone, but it was a confirmed defect in the test contract.

The screen now rechecks current permission/channel/exact access before testing.
It explains precise access and links to Alarms & reminders before scheduling.
The native layer independently refuses an inexact one-minute test and reports
precise_permission_required, including permission revocation during scheduling.

A successful delayed test commits its title, body and due time before setting an
exact allow-while-idle alarm. A unique WorkManager job with the same due time
backs up delivery across process death and reboot. Due-time/generation checks
reject early or superseded callbacks. A shared synchronized delivery path clears
pending state only after Android accepts the notification, so alarm, worker and
foreground recovery cannot duplicate it. Permission/channel failures remain
recoverable. Tests older than 15 minutes expire visibly rather than retry forever
or unexpectedly posting a stale test. The backup worker is approximate recovery;
it does not claim exact delivery. Android/OEM restrictions still require a phone
retest. Daily and event reminders retain their ordinary-alarm fallback.

The local report now distinguishes lastTestResult, testScheduled, lastTestPosted,
testBackupError and lastAlarm from ordinary reminder/cache state.

## Defaults

For preferences the user has not saved: Daily Panchang ON, Personal events ON,
and both times 06:00. Native scheduling, delivery, initialization, event-save
confirmation, Flutter configuration and the settings-screen time fallback agree.
Explicit saved opt-outs and selected times remain unchanged. Earlier builds did
not track whether a stored 05:00 was manually chosen or simply saved as the old
default, so no speculative migration overwrites those stored values.

## References

- https://api.flutter.dev/flutter/material/SnackBar/persist.html
- https://developer.android.com/develop/background-work/services/alarms

See BUILD_STATUS.md for executed checks and device-validation limits.
