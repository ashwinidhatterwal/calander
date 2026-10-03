# Checkpoint 13 — notification recovery and user-selected times

Version: 1.0.0+13. Base: GitHub main commit acff0f554106ab5684a02983fc19e2e4341cea8e; the latest successful production workflow 37017926858 built that commit as build 12. No keystore or signing identity changes.

## Confirmed defects in the released source

1. If the current date had no cached summary, CalendarAlarmReceiver skipped notification delivery, scheduled tomorrow, and only renewed the cache. The background worker wrote the cache without retrying that day's delivery.
2. The shared `delivered` date was written even when show() returned early because notification permission was blocked. Granting permission later could not recover that day's reminders.
3. Resuming the app after the fixed 5 AM target replaced a delayed alarm with tomorrow's alarm without first delivering the missed reminder.
4. Daily Panchang and personal events used one fixed 5 AM alarm and one shared delivery marker. This could not support separate times.
5. Reused notification IDs had setOnlyAlertOnce(true), so an uncleared previous notification could suppress sound on following days.
6. Permission status checked the whole app only, hiding an independently blocked reminder channel.

These are verified code defects. The exact cause on the user's phone overnight is not proven without its permission/channel/alarm diagnostics. Inexact Android alarms, disabled event reminders and device background restrictions remain possible contributors.

## Delivery design

- Separate explicit PendingIntent actions/IDs for daily and event alarms, plus a separate test alarm. Selected times are minutes since local midnight, default 05:00, persisted in native SharedPreferences. Existing on/off preferences remain intact, including explicit opt-outs. Personal events remain opt-in.
- Each reminder has its own successful-post date. Missing cache, blocked permission, blocked channel and posting exceptions never consume delivery. Empty event lists do not consume a future event delivery that day.
- deliverDue() is synchronized and shared by alarm, foreground resume, permission completion, cache completion and recovery worker. It checks only today's due reminders, never sends earlier days' stale summaries, and prevents duplicate daily posts.
- Native cache writes commit synchronously and record freshness. A background cache build cannot overwrite a newer foreground cache revision.
- Cache completion retries due reminders immediately. A persistent 15-minute WorkManager recovery task provides another opportunity to catch up/recreate alarms; Android may defer WorkManager during Doze. It checks native cached state without launching Flutter on every tick; rebuild is requested only when cache is missing/stale beyond a day.
- Existing offline headless Flutter summary worker, reboot/time/timezone/package-update recovery and saved location are retained. Exact-access changes also reschedule.
- Notification posting checks app permission and actual channel/group state, returns success/failure, and permits chime on successive days.
- Saving an event refreshes reminder cache before optional saved-event confirmation, so a posting failure cannot prevent scheduling its reminder.

## User controls

Three-dot menu > Notifications:

- Daily Panchang and Personal events toggles.
- Independent time pickers; Hindi times show पु./अप., English AM/PM.
- Gentle chime toggle with existing channel identities preserved.
- Immediate posting test, and one-minute alarm test independent of production reminders. Scheduled tests may be delayed without exact-alarm access. Neither consumes daily/event delivery markers.
- Actual notification/channel status, direct system notification settings link, optional precise-time access link, and battery/background settings link.
- Copyable local diagnostics: both next-alarm times, last alarm/post, cache readiness/freshness, permission/channel state, exact access, battery restriction/optimization, last posting result and background refresh error. No diagnostics upload.

## Permission change and Android research

Added SCHEDULE_EXACT_ALARM, optional and granted by the user through Android's Alarms & reminders settings. USE_EXACT_ALARM is not requested. Ordinary inexact alarms remain the fallback when access is absent/revoked or throws SecurityException. Foreground location and notification permission remain unchanged; no background location or foreground-service permission is introduced. The permission audit explicitly allows this one new permission and continues rejecting unrelated/sensitive permissions.

Official sources reviewed:

- https://developer.android.com/develop/background-work/services/alarms — inexact alarms can be delayed; user-selected calendar reminders may use exact alarms, check canScheduleExactAlarms and reschedule on access changes.
- https://developer.android.com/develop/ui/views/notifications/notification-permission — Android 13+ posting requires runtime notification permission.
- https://developer.android.com/reference/android/app/NotificationChannel — app, channel and channel-group blocks can independently suppress notifications.
- https://developer.android.com/develop/background-work/background-tasks/persistent/getting-started/define-work — persistent periodic work is recovery, not an exact-time guarantee.
- https://robolectric.org/getting-started/ — Android framework regression testing setup.

## Regression coverage and verification

Native tests cover permission-blocked retry, missing-cache retry, blocked channels, independent daily/event delivery, duplicate prevention, test isolation, persisted selected times, local-time scheduling and invalid preference bounds. Flutter tests cover bilingual time labels, preserved times when changing toggles, native configure arguments, immediate/delayed test requests and blocked-test feedback/settings action. Both GitHub workflows run native tests in addition to existing Flutter analysis/tests and permission audits.

Native notification compilation and nine native regressions passed in the standalone Android/Flutter-embedding harness. See BUILD_STATUS.md for scope and remaining Flutter/device execution status. A passing source validator is not a physical-device notification-delivery test.

## Device acceptance check

1. Upgrade from the Play-signed build12 to Play-signed build13 without clearing data. Verify event list, location and times.
2. Open Notifications, enable both desired reminder types, allow notifications, check channel enabled, and optionally allow precise alarms.
3. Run immediate test and verify the notification panel. Run one-minute test, close app normally and verify delivery. Grant precise access if Android defers the inexact test.
4. Create a Gregorian event for today and set both times a few minutes ahead, with different times. Close the app, verify each reminder arrives once and chimes on the next day even if the previous notification was left uncleared.
5. Repeat after reboot, a time/timezone change and permission deny/restore. Force-stop intentionally prevents Android delivery until the app is opened again.
6. If a test fails, copy the notification status report. This distinguishes Android acceptance, permission/channel blocks, missing cache and absence of an alarm callback.
