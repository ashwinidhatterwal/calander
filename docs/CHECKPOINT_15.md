# Checkpoint 15

Source: GitHub main commit 85cbcc613f923d5f3ac236499fb9a71c539cb620, build14.
Version: 1.0.0+15.

The user confirmed notification delivery is working. The settings screen now
removes immediate/delayed test controls, the technical status/report row, their
handlers and the unused Clipboard import. Reminder switches, independent times,
chime, notification permissions, precise-alarm access and conditional battery
settings remain. The footer is shortened. Native delivery/recovery and internal
regression coverage are unchanged; no new permissions or signing changes.

## Tithi explanation verified

The engine's buildDay samples tithiAt(sunrise), calculates tithiEndUtc, nextTithi
and sunrise-to-sunrise skipped/repeated tithi status. The month tile and Today
card display the sunrise tithi. Day Details displays Tithi ends and Next Tithi.

An executed standalone probe of the actual Dart engine for 2026-10-03, coordinates
29.58N/74.32E (Hanumangarh), UTC+05:30 returned:
- Sunrise: 06:26:55 IST; tithi at sunrise: Saptami.
- Saptami end: 08:01:30 IST; next tithi: Ashtami.
- At 16:00 IST: Ashtami.

A separately published Hanumangarh Panchang lists Saptami until approximately
08:00 and then Ashtami: https://xastro.app/panchang/hanumangarh/2026-10-03
Both occur sequentially on the same civil date. The single sunrise-based main
label does not describe every tithi during that date or dynamically switch after
the transition. No calendar algorithm/display changes are included in this UI
cleanup. Minute-level differences between engines are not resolved by this probe.

## Verification

57 checkpoint15 source checks, six permission audit tests, Dart parser/formatter,
workflow YAML and whitespace checks passed. Native source is identical to build14,
whose notifications the user verified. Updated Flutter settings widget tests
remain in the package; full Flutter analysis/tests and APK/AAB generation run on
GitHub. No full local Flutter build or additional physical-phone test is claimed.
