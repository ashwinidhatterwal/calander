# Checkpoint 11 — Source candidate, 1.0.0+11

Package remains `in.hinducalendar.hindu_calendar`.

- Morning Panchang defaults on for users without an explicit saved preference.
  Existing opt-outs remain off. Notification permission is requested on first use.
- Removed special exact-alarm permission and settings. Delivery targets approximately
  5 AM using an inexact Android alarm; battery management can delay it.
- Existing offline rolling summaries and background renewal remain. Closing the app
  normally does not cancel alarms; force-stop does until the next launch.
- Shared widget/notification launch intent, singleTask, explicit task affinity and
  documentLaunchMode=never prevent creating separate app tasks. Old duplicates are
  removed when the main activity starts. Device verification is still required.
- Reject geocoder division labels. A bundled district-boundary lookup resolves
  ambiguous names off the UI isolate. Existing division labels receive a one-time
  repair using saved coordinates only. Panchang coordinates are never changed by
  naming. No GPS request at ordinary startup.
- Holidays combines national and effective-state entries in date order. Reference
  2026 lists cover 28 states and 8 union territories; future state years are not
  inferred. Unknown state/year is clearly labelled. These are reference holiday
  dates, not guaranteed legal leave entitlements; moon sightings and new orders
  can change them.
- All checkpoint 09/10 UX, festival descriptions, background calculations and widget
  appearance changes are retained. Astronomy source is unchanged.

District fallback adds about 5.6 MB uncompressed; it is loaded only for missing or
division labels. Native valid district names take precedence, particularly after
district reorganizations. Fallback names outside the explicitly translated districts
may appear in English in Hindi mode rather than inventing a translation.

## Build and release

Apply this source to the existing repository. Run Android QA build and Production
Play bundle using existing secrets. Both workflows run analyze, the full Flutter
test suite, checkpoint 11 checks and final merged-permission audits. Production
uses the existing upload key. Do not upload a QA-signed artifact to Play.

Before release, test approximate-location permission, saved-location refresh,
Hanumangarh vs Bikaner labels, widget and notification launches in Recents, morning
reminders after normal close and reboot, permission denial, and explicit opt-out.
Upload production-signed build +11 to the same closed testing track.
