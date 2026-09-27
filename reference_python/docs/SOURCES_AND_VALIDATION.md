# Sources and Validation Policy — Checkpoint 02

## Principle

The shipped app must not depend on a paid Panchang/astronomy API and must not copy another publisher's prose. Core Panchang values are calculated locally. External sources are used to validate calculations, document tradition-specific rules and review rare exceptions.

## Primary official reference

### Government of India — Rashtriya Panchang / Positional Astronomy Centre

The India Meteorological Department / Positional Astronomy Centre publishes the Rashtriya Panchang as standardized calendric source material. It is the highest-priority reference when we construct the long-term golden dataset.

- https://mausam.imd.gov.in/responsive/rashtriyPanchang.php
- https://packolkata.imd.gov.in/panchang/en/preface

## Solar cross-check

### NOAA Solar Calculator methodology

Sunrise/sunset uses the standard apparent sunrise/sunset zenith and equation-of-time/hour-angle approach documented by NOAA.

- https://gml.noaa.gov/grad/solcalc/calcdetails.html
- https://gml.noaa.gov/grad/solcalc/solareqns.PDF

## Festival regression references used in Checkpoint 02

Commercial/community Panchang publications are secondary regression references rather than runtime dependencies. Current golden cases retain source URLs in `data/validation_cases.json` and `data/festival_overrides.json`.

Examples include reviewed 2026–27 dates/timings for:

- Krishna Janmashtami
- Ganesh Chaturthi
- Raksha Bandhan
- Vijayadashami
- Diwali
- Karwa Chauth
- Bhai Dooj
- Holika Dahan / Holi
- Navratri commencement
- Makara Sankranti

Government holiday lists are also useful for confirming the civil observance date of major North-Indian festivals, but a holiday list is not treated as an astronomical formula source.

## Historical edge cases

Kshaya Maas is rare. The engine has a regression for the documented 1983 case in which the Pausha lunar interval is followed by a skipped Magha month and an Adhik Phalguna period. This exists to prevent a normal-month shortcut from silently corrupting rare years.

## Moonrise validation

Checkpoint 02 uses published New Delhi timings as regression targets with an explicit tolerance rather than claiming observatory-grade precision.

Examples:

- Karwa Chauth 2026, New Delhi: published moonrise about 20:17; reference engine about 20:12.
- Janmashtami 2026, New Delhi: published moonrise about 23:29; reference engine about 23:24.

The product needs practical minute-level utility. A future astronomy refinement can reduce these differences while preserving the same public engine interface.

## Validation layers

### Unit/golden tests

`python -m pytest -q`

These check known dates, transitions, festival rules and rare regressions.

### Broader invariant matrix

`python tools/validate_matrix.py`

Checkpoint 02 validates sampled dates across:

- Sri Ganganagar
- Delhi
- Jaipur
- Varanasi
- Lucknow
- Bhopal
- Chandigarh

The matrix checks ordering/range invariants, local-date correctness for rise/set events, Tithi anomaly states, and major-festival rule resolution.

## Rules for adding a golden test

Every external regression should retain as much of the following as practical:

- date
- city / coordinates
- regional calendar profile
- expected value
- allowed timing tolerance
- source name
- source URL
- verification date
- explanation of any regional/sect-specific convention

## Copyright/content rule

External sources may be used for facts, validation and rule research. Long descriptions, translations, festival articles and educational explanations must be written independently for the app.
