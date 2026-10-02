# Checkpoint 09 — Closed Test Feedback Update

Release identity: `1.0.0+9`, `in.hinducalendar.hindu_calendar`.

## Changes

- A first-use location sheet offers **Use current location** and all existing manual cities. Obtaining a location is an explicit, bounded, one-shot `geolocator` call, using balanced accuracy. Approximate permission is accepted. Denial, permanent denial, disabled location and timeout keep the existing location usable.
- Coordinates and UTC offset are validated and saved locally in a versioned JSON payload through the existing preferences store. Existing city IDs still load. Corrupt saved coordinates safely fall back. Refresh is the same current-location action in the location picker. No reverse geocoding or calendar network calls were added.
- This release retains the India/IST profile (UTC+05:30), including when coordinates are acquired abroad; the saved-location UI states IST. International timezone/profile support is outside this update.
- Location-dependent month cells, Today data, festival years and personal-event matches use latitude/longitude/offset keys. Changing coordinates invalidates the departing location's festival data and screen caches, while independent astronomy calculations remain unchanged. Normal startup never requests location. Widgets resync after successful location persistence.
- Today is the only persistent highlighted day. Date taps only open Day Details. Month arrows and month/year picker never select day 1. The Today card remains Today's Panchang; the month subtitle is derived from the viewed month's first day. Midnight/resume updates the date without location acquisition.
- National Holidays are civil data, independent of the Hindu festival engine. Republic Day (26 January), Independence Day (15 August) and Gandhi Jayanti (2 October) have Hindi/English names, their own category, year navigation and Upcoming/Full year filtering. Date cells display a holiday label when another festival/event label does not take priority. The model allows a future optional state code.
- Dynamic Android scaffold adds fine/coarse foreground permissions. Optional package foreground-service permissions and background location permission are explicitly removed from the merged manifest. No service configuration or position stream is used.
- The existing widget dependency brings AndroidX WorkManager wake/network/boot permissions; these normal widget-library permissions remain allowlisted. They do not enable background location, and no location work is scheduled.
- APK and AAB audits use a fail-closed permission allowlist and require both foreground permissions. Checkpoint 08's historical validator remains intact; both current workflows run the separate Checkpoint 09 validator. A dependency lockfile and the tested Flutter 3.47.5 toolchain pin are included for repeatable QA/production builds.
- Current Flutter scaffold output is normalized so Kotlin escapes never enter the Android application ID; the existing Play package stays `in.hinducalendar.hindu_calendar`.
- Privacy source documents the optional location feature. Existing production signing and package identity remain unchanged.

## Release steps

See `PLAY_STORE_RELEASE_CHECKLIST.md`. Use the existing Closed testing track and existing signing secrets. Do not replace the upload key. The source package is a release candidate until the signed production AAB passes CI and real-device checks.

## Verification

See `CHECKPOINT_09_VERIFICATION.md` for commands, actual results and outstanding items. Do not interpret structural validation as evidence of a successful signed production build.
