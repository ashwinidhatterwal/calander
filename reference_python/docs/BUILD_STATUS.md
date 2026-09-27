# Build Status — Checkpoint 02

## Status

**Checkpoint 02 is complete as a reference-engine milestone.** It is not yet the Flutter/Android application.

## Panchang engine now implemented

- Dependency-free Sun and Moon calculations for the product's modern-date target range.
- Lahiri/Chitrapaksha sidereal conversion.
- Tithi and exact next transition.
- Paksha.
- Nakshatra and transition.
- Yoga and transition.
- Karana and transition.
- Sunrise and sunset.
- Moonrise and moonset.
- Sun and Moon Rashi.
- Amanta lunar month.
- North-Indian Purnimanta lunar month.
- Adhik Maas detection.
- Kshaya Maas detection foundation, including the documented 1983 Pausha–Magha case.
- Kshaya Tithi / Vriddhi Tithi detection at consecutive sunrises.
- Vikram Samvat and Shaka Samvat year.
- Rahu Kalam, Yamaganda, Gulika, Abhijit Muhurta and Brahma Muhurta.

## Festival/observance engine now implemented

Major North-India/Purnimanta rules currently include:

- Maha Shivaratri
- Holika Dahan
- Holi / Dhulandi
- Rama Navami
- Raksha Bandhan
- Krishna Janmashtami
- Ganesh Chaturthi
- Shardiya Navratri start
- Vijayadashami / Dussehra
- Karwa Chauth
- Dhanteras
- Diwali
- Govardhan Puja
- Bhai Dooj

Recurring observances implemented:

- Ekadashi (general sunrise rule; sect-specific refinement remains pending)
- Purnima
- Amavasya
- Pradosh
- Sankashti Chaturthi
- all 12 Sankrantis

Festival selection is kept separate from astronomy. Rule selectors include sunrise, Madhyahna, first third of daylight, Aparahna, Pradosha, Nishita and moonrise.

## Reviewed exception mechanism

Rare disputed/complex years can be placed in `data/festival_overrides.json` with source links and a reason. The 2026 North-India Holika Dahan edge case is the first such record. The runtime rule code therefore does not need hidden one-off date constants.

## Automated validation

### Fast regression suite

`python -m pytest -q`

Current result:

**16 passed**

Coverage includes:

- core Panchang calculations
- transition ordering
- Adhik Shravan 2023
- Kshaya Tithi examples in 2027
- Kshaya Maas / following Adhik Phalguna in 1983
- reviewed major-festival dates for 2026 and 2027
- Delhi moonrise regressions for Janmashtami and Karwa Chauth 2026
- Makara Sankranti 2026

### Broader invariant matrix

`python tools/validate_matrix.py`

Current Checkpoint 02 report:

- 7 cities
- 30 sampled/edge dates per city
- 210 Panchang day calculations
- 28 major-festival records resolved for 2026–27
- 0 invariant failures

The machine-readable result is stored in `data/checkpoint02_validation_report.json`.

This matrix is a structural/regression check, not proof that every religious observance is universally correct. Regional and sect-specific traditions still require their own profiles.

## Prototype upgraded

The Hindi-first static prototype now consumes Checkpoint 02 data and shows:

- Tithi on the month grid
- festival/vrat badges
- separate Day Details page
- Moonrise / Moonset
- actual major and recurring observances from the rule engine
- Hindi / English switching
- Kshaya/Vriddhi Tithi warning support
- calendar reference information

## Deliberately still pending

- complete Bhadra logic for Holika Dahan instead of the reviewed 2026 override
- Smarta/Vaishnava Ekadashi distinction and Parana rules
- region profiles outside the initial North-India/Purnimanta experience
- deeper festival list beyond the launch-critical set
- complete golden timing dataset against Rashtriya Panchang across many years
- Dart port
- Flutter UI
- Android notifications/local storage
- APK/AAB build pipeline

## Next checkpoint

**Checkpoint 03: Dart/Flutter product build.**

The stable calculation/rule interfaces should be ported to Dart, followed by the real Hindi-first month calendar and Day Details screens. GitHub Actions should then run Dart/Flutter tests and create a test APK artifact.
