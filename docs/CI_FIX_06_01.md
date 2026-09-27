# Checkpoint 06 CI Fix 01

GitHub Actions run #6 reached the release Android build after both analysis and
Flutter tests passed. The native Kotlin widget providers then failed to compile.

## Cause

The Android application id/namespace is:

`in.hinducalendar.hindu_calendar`

`in` is a Kotlin keyword. Flutter's generated Kotlin source escapes that package
segment, but the Checkpoint 06 widget provider sources did not.

Invalid:
`package in.hinducalendar.hindu_calendar`

Correct Kotlin syntax:
`package `in`.hinducalendar.hindu_calendar`

## Fix

Both native home-screen widget providers now use the escaped Kotlin package.
The Android application id has NOT changed, so this remains the same installed app.

No Panchang, Tithi, month, festival, personal-event, or UI calculation logic changed.
