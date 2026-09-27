# CI Fix 03

After GitHub Actions run #2, the remaining widget-test timer was traced to
`CalendarScreen._ensureFutures()`. Both CalendarScreen computations now use
`Future.sync(...)`.

A matching `Future(...)` pattern in `DayDetailsScreen._load()` was also changed
to `Future.sync(...)` proactively so Day-page widget tests do not hit the same
pending-timer failure later.

These changes do not modify Panchang or festival calculations.
