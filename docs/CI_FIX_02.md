# CI Fix 02

GitHub Actions run #2 showed one remaining widget-smoke-test failure:

- `CalendarScreen._ensureFutures()` created zero-duration timers through `Future(() => ...)`.
- Flutter's test binding disposed the widget while those timers were still pending.

Fix:
- Changed both CalendarScreen deferred computations to `Future.sync(...)`.
- Kept the earlier FestivalsScreen `Future.sync(...)` fix.

This does not change Panchang or festival calculation logic. It only removes unnecessary event-loop timers from UI initialization.
