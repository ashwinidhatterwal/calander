# Hindu Calendar — Checkpoint 02 Foundation

A Hindi-first Hindu Calendar reference implementation designed to become an offline-first Flutter Android app.

## Product direction

The main screen behaves like a normal monthly calendar and shows only high-value information: Gregorian date, Tithi and important festival/vrat markers. Tapping a date opens a separate Day Details screen containing the complete Panchang for that day.

Hindi (`hi-IN`) is the default product language. English (`en-IN`) is optional.

## Implemented calculation engine

- Tithi / Paksha + transitions
- Nakshatra + transition
- Yoga + transition
- Karana + transition
- Amanta + North-Indian Purnimanta month
- Adhik Maas
- Kshaya Maas foundation
- Kshaya / Vriddhi Tithi detection
- sunrise / sunset
- moonrise / moonset
- Sun / Moon Rashi
- Vikram / Shaka Samvat
- Rahu Kalam / Yamaganda / Gulika
- Abhijit / Brahma Muhurta

No commercial astronomy or Panchang runtime dependency is required.

## Festival engine

Major rules currently cover Maha Shivaratri, Holika Dahan/Holi, Rama Navami, Raksha Bandhan, Janmashtami, Ganesh Chaturthi, Shardiya Navratri, Vijayadashami, Karwa Chauth, Dhanteras, Diwali, Govardhan Puja and Bhai Dooj.

Recurring observances currently include Ekadashi, Purnima, Amavasya, Pradosh, Sankashti Chaturthi and all 12 Sankrantis.

## Run one Panchang day

```bash
python src/cli.py 2026-09-27
```

Custom location:

```bash
python src/cli.py 2026-09-27 --city Jaipur --lat 26.9124 --lon 75.7873
```

## Generate festivals

```bash
python src/festival_cli.py 2026
```

Include recurring vrats/Sankrantis:

```bash
python src/festival_cli.py 2026 --all
```

## Tests

```bash
python -m pytest -q
```

Current checkpoint: **16 tests passing**.

Broader audit:

```bash
python tools/validate_matrix.py
```

Current report: **210 Panchang day calculations across 7 cities, zero invariant failures**.

## Prototype

Open `prototype/index.html` in a browser. The static prototype is backed by generated Checkpoint 02 data and includes the separate Day Details experience.

Regenerate it with:

```bash
python tools/generate_demo.py
```

## Important documents

- `docs/CHECKPOINT_02.md`
- `docs/BUILD_STATUS.md`
- `docs/CALENDAR_STANDARD.md`
- `docs/SOURCES_AND_VALIDATION.md`
- `docs/PRODUCT_ARCHITECTURE.md`

## Next checkpoint

Checkpoint 03 will port the stable domain engine to Dart, create the real Flutter Android application and configure an automated APK build workflow.
