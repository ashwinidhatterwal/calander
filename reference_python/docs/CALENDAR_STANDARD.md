# Calendar Standard — Checkpoint 02 Decision Record

## Product default

- Default language: **Hindi (`hi-IN`)**.
- Optional full-app switch: **English (`en-IN`)**.
- Initial regional profile: **North India / Purnimanta**.
- Also calculate and retain **Amanta** month for transparency and later regional expansion.
- Main calendar-cell Tithi: Tithi prevailing at **local sunrise**.
- Day Details: exact transition time, next Tithi, Panchang values and important observances.
- Location: city/coordinates based. GPS is optional.

## Architecture rule

Astronomical state and religious/festival date selection are separate layers.

```text
Astronomy Engine
      ↓
Panchang Engine
      ↓
Festival Rule Engine
      ↓
Calendar / Day Details UI
```

A festival rule can therefore be corrected without changing Moon/Sun calculations, and an astronomy improvement can be tested without changing editorial content.

## Astronomy policy

The product must not require a paid astronomy or Panchang license.

Checkpoint 02 uses project-owned Python source based on standard astronomical equations and lunar periodic terms. There is no runtime dependency on Swiss Ephemeris or a commercial Panchang API.

### Time/coordinate conventions

- Astronomy calculations use UTC internally.
- User-facing values are converted to the selected city's timezone.
- Tropical Sun/Moon longitude is converted to sidereal longitude using Lahiri/Chitrapaksha ayanamsha for Nakshatra, Yoga, Rashi and month logic.
- Tithi depends on Moon–Sun angular separation, so the common ayanamsha cancels.

## Tithi

Thirty 12-degree divisions of Moon–Sun elongation.

- Shukla Paksha: first 15 divisions.
- Krishna Paksha: second 15 divisions.
- Shukla 15: Purnima.
- Krishna 15: Amavasya.

The app stores both the Tithi at sunrise and its next transition time.

### Kshaya and Vriddhi Tithi

Consecutive local sunrises are compared.

- same Tithi at both sunrises → `vriddhi`
- one Tithi skipped between sunrise labels → `kshaya`
- otherwise → `normal`

Known 2027 Kshaya Pratipada cases are retained as regression tests.

## Nakshatra

27 equal sidereal ecliptic divisions of 13°20′. The current Nakshatra and next transition time are calculated.

## Yoga

27 equal divisions of normalized sidereal Sun + Moon longitude. The current Yoga and next transition are calculated.

## Karana

60 half-Tithi divisions of 6°. The traditional movable/fixed Karana sequence is applied. `NamedValue.index` represents the half-Tithi serial (1–60), not merely the 11 unique Karana names.

## Lunar month

### Amanta

The month is derived from the sidereal solar sign associated with the new-moon interval.

### North-Indian Purnimanta

For ordinary months, Krishna Paksha is displayed using the following North-Indian Purnimanta month while Shukla Paksha follows the Amanta month label. Adhik/Kshaya logic is resolved from new-moon and solar-ingress structure rather than a simple month-name offset.

### Adhik Maas

When a lunar month contains no solar ingress, it is marked Adhik.

### Kshaya Maas

When two solar ingresses occur within the relevant lunar month, the skipped following month is exposed through `kshaya_month_after`. The documented 1983 Pausha–Magha Kshaya case is part of the test suite; the following Adhik Phalguna is also checked.

## Sunrise / sunset

Apparent upper-limb sunrise/sunset uses a 90.833° zenith with local coordinates.

## Moonrise / moonset

Checkpoint 02 adds a compact geocentric lunar rise/set calculation using lunar longitude/latitude periodic terms, equatorial conversion and altitude root finding across the local civil day.

This implementation targets practical Panchang utility, not observatory-grade topocentric astronomy. Published moonrise regressions are therefore maintained with explicit tolerances.

## Daily periods

Rahu Kalam, Yamaganda and Gulika divide daylight into eight segments and apply weekday-specific segment rules.

Abhijit is centered on local solar midday. Brahma Muhurta is represented as the interval 96–48 minutes before sunrise in this profile.

## Festival rule selectors

Checkpoint 02 supports these date-selection windows:

- `sunrise`
- `madhyahna`
- `first_third_day`
- `aparahna`
- `aparahna_with_sunrise`
- `pradosha`
- `nishita`
- `moonrise`

The engine checks whether the required Tithi/month/Paksha overlaps the relevant window rather than assuming the Tithi at midnight determines a festival.

## Reviewed overrides

Rules with exceptional Bhadra/regional complications may temporarily use a reviewed record in `data/festival_overrides.json`.

An override must contain:

- festival ID
- regional profile
- year
- selected civil date
- reason
- reference URLs

The goal is to keep exceptions visible, auditable and removable once the full underlying rule is implemented.

## Validation policy

Every release should maintain tests for:

- Tithi transitions near sunrise
- skipped and repeated Tithis
- Purnima / Amavasya
- month changes
- Adhik Maas
- Kshaya Maas
- Nakshatra/Yoga/Karana transitions
- moonrise-sensitive festivals
- day-part-sensitive festivals
- major festival dates
- multiple Indian cities

The initial app must clearly identify itself as the **North-India/Purnimanta** profile rather than implying that one festival convention applies universally throughout Hindu traditions.
