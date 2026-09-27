# Checkpoint 02 — Panchang + Festival Foundation

Checkpoint 02 freezes the first serious calculation/rule foundation for the Hindi-first Hindu Calendar app.

## What changed from Checkpoint 01

- Added moonrise/moonset.
- Added Kshaya and Vriddhi Tithi detection.
- Added Kshaya Maas detection/regression coverage.
- Added rule-based major festival engine.
- Added recurring Ekadashi, Purnima, Amavasya, Pradosh and Sankashti observances.
- Added all twelve Sankrantis.
- Added source-backed reviewed override mechanism for rare rule exceptions.
- Added 2026/2027 major-festival regression data.
- Expanded automated tests to 16 passing tests.
- Added 210-day/city broader invariant audit with zero failures.
- Upgraded the static Hindi-first UI prototype to display real festival output and Moon information.

## Frozen architectural decisions

1. No paid Panchang or astronomy runtime dependency.
2. Panchang calculation and festival-date rules remain separate modules.
3. Initial cultural profile is North India / Purnimanta.
4. Hindi is the default language; English is a complete alternate locale.
5. Main calendar remains intentionally simple; detailed Panchang belongs on the separate Day Details screen.
6. Rare exceptions are explicit data records with sources rather than hidden hardcoded dates.

## Known limitations accepted at this checkpoint

- Ekadashi currently uses a general sunrise rule and does not yet model full Smarta/Vaishnava distinctions or Parana.
- Holika Dahan still needs a complete Bhadra rule layer; the 2026 North-India edge date is handled by a reviewed override.
- Moonrise/moonset targets practical calendar precision, not observatory/topocentric precision.
- Regional calendars outside the North-India/Purnimanta profile are not yet supported.
- This is still the Python reference implementation; the shipping mobile engine will be Dart.

## Gate for Checkpoint 03

Checkpoint 03 may begin because:

- core calculation interfaces are stable enough to port;
- important rare month/Tithi cases are represented in tests;
- launch-critical festival rules exist as a separate engine;
- the UI data contract now includes the fields required by the planned main calendar and Day Details screens.

Checkpoint 03 target: **Dart port + Flutter Android project + Hindi-first real mobile UI + automated APK build workflow.**
