# Checkpoint 17 — Panchang notifications and Durga observances

Based on GitHub main 17127180df7c54d2eda9cea5394d0e47246fcf59 (build16).

## Underlying causes and changes

The notification payload used Gregorian date as the native title, making the
Panchang secondary. Title now contains paksha/tithi, body starts with festival
and vrat names, and date follows. The date is separately cached for personal
reminders; native event delivery accepts both the new and old payloads.

The major rule catalogue lacked Durga Ashtami altogether. Added Ashwin and
Chaitra Shukla Ashtami rules and Chaitra Navratri start. Dates are computed for
saved coordinates and the existing North-Indian/Purnimanta sunrise profile.
Python reference and dated fixtures were extended, without changing the old
festival date assertions. Specific ritual/sect muhurta variations are not
represented as universal dates.

The calendar grid also maintained a separate hard-coded recurring list. It
now uses sunriseObservances shared by the engine used in details and morning
notifications. Per user request only the main Chaitra and Sharadiya Navratri
Durga Ashtami observances are added, with no monthly Durgashtami rule or
extra previous-sunrise calculation. Grid badges can name two simultaneous
major observances. No year-wide moonrise work was added to grid rendering.

## Verification

Dated references: Delhi/Hanumangarh Ashwin Ashtami 2026-10-19 and 2027-10-07;
Chaitra Ashtami 2026-03-26; Chaitra Navratri start 2026-03-19.

Primary published references used for comparison (not scraped into app):
https://www.drikpanchang.com/navratri/durga-puja/mahashtami-date-time.html?geoname-id=1273294
https://www.drikpanchang.com/navratri/durga-puja/mahashtami-date-time.html?geoname-id=1261481&year=2027
https://www.drikpanchang.com/festivals/lunar-month/festivals-chaitra.html?lang=en
https://www.drikpanchang.com/vrats/masik-durgashtami-dates.html?time-format=12hour&year=2026

Local: Python festival regressions (8), standalone pure-Dart checks against
actual synchronous domain/payload code, source/permission
checks, Dart parser, workflow YAML, git diff whitespace, ZIP CRC/checksums.
The temporary standalone harness substitutes only Flutter's unused async
compute bridge and extracts the unchanged synchronous payload function. It
is not a Flutter UI or Android device/integration test.

New Flutter tests check bilingual content order, dated festival output and
absence of monthly labels. New native notification test checks both titles and
expanded content. Existing API24/28/29/31 task compatibility tests remain.
Both GitHub build workflows run Flutter and native regressions. No local
Flutter/native suite, signed build or physical device test is claimed.

## Home-screen icon question

No icon change was made. Standard launcher icons are packaged resources;
activity-alias switching can select prebuilt tithi icons, but does not provide
a cross-launcher guaranteed live calendar icon. Prefer an icon-sized widget
with current tithi and an app-open tap action. Current larger widgets remain.
