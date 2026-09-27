# Checkpoint 06 — Navigation, Identity and Widgets

Checkpoint 06 keeps the Panchang and festival calculation engine unchanged and focuses on product polish around the Android shell.

## Changes

- New sober Hindu Calendar launcher mark used for the Android icon and Flutter loading screen.
- Event editor example changed from a bereavement-specific phrase to `घर की वार्षिक पूजा` / `Annual family puja`.
- Calendar month can be changed by horizontal swipe. The page moves only a small distance while dragging and requires a deliberate threshold/velocity before changing month, creating mild resistance against accidental switches.
- Gregorian month/year header is tappable and opens a month/year picker (1900–2100).
- Android activity launch mode is changed from `singleTop` to `singleTask` to keep one calendar task in Recents. Widget launches also reuse that task.
- Added two Android home-screen widgets:
  - **Today Panchang**: weekday/date, Paksha + Tithi, Hindu month, sunrise and sunset.
  - **Upcoming**: next major festival/vrat or personal `My Day` event.
- Widgets are theme-aware:
  - Android 12+ uses the phone's Material You system accent/neutral palette.
  - Older Android versions use automatic light/dark resources.
- Flutter precomputes 14 daily widget summaries so the Today widget can roll forward without reopening the app every day. Upcoming items are also stored as an ordered queue.
- Widget synchronization is asynchronous and optional; widget failures cannot block app startup.

## Android task duplication note

Older builds used Flutter's default `singleTop` launch mode. Some launch/update paths can leave more than one task card visible in Recents. Checkpoint 06 uses `singleTask`, so new launches should route into the existing task. After installing this build, dismiss any old duplicate Recents cards once; they are leftovers from previous tasks and should not be recreated.

## Calculation scope

No changes were made to Panchang astronomy, Hindu month handling, Adhik/Kshaya Maas rules, festival selection rules, or reference fixtures in this checkpoint.
