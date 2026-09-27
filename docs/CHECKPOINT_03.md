# Checkpoint 03 — Flutter Android Foundation

## Objective

Convert the trustworthy Checkpoint-02 Panchang/festival foundation into the first Android-product codebase without changing the core product philosophy.

## Completed

### Production Dart domain layer

A pure-Dart port now exists for:

- Julian day utilities
- solar longitude
- lunar longitude
- Lahiri ayanamsha
- Tithi / Paksha
- Nakshatra
- Yoga
- Karana
- Tithi transition search
- new-moon search
- Amanta / North-Indian Purnimanta month
- Adhik Maas
- Kshaya Maas detection
- Kshaya/Vriddhi Tithi detection
- Sun/Moon Rashi
- Vikram Samvat
- Shaka Samvat
- sunrise/sunset
- moonrise/moonset
- Rahu Kalam
- Yamaganda
- Gulika
- Abhijit Muhurta
- Brahma Muhurta

The Dart port remains independent of Flutter UI classes so the engine can be tested separately.

### Festival layer

The major North-Indian festival rules from Checkpoint 02 were ported to Dart, including the reviewed Holika Dahan override layer. Major-festival results are cached per year/location.

The main calendar additionally marks common sunrise Tithi observances such as Ekadashi, Purnima, and Amavasya.

### Hindi-first Flutter UI

Implemented:

- monthly calendar grid;
- large Gregorian date;
- Tithi under each date;
- subtle festival/vrat marker;
- Hindu month on the main page;
- Today summary card;
- separate Day Details screen;
- previous/next month navigation;
- previous/next day navigation;
- city selector;
- Hindi default language;
- English switch;
- Festival browser by year.

### Day Details page

Displays:

- Tithi and end time
- next Tithi
- Paksha
- Hindu month
- Nakshatra and transition
- Yoga and transition
- Karana and transition
- major festival / common observance
- sunrise/sunset
- moonrise/moonset
- Sun/Moon Rashi
- Abhijit Muhurta
- Brahma Muhurta
- Rahu Kalam
- Yamaganda
- Gulika
- Vikram / Shaka Samvat
- Kshaya/Vriddhi Tithi notices
- Kshaya Maas notice where detected

## Cross-language parity strategy

The Python engine remains the reference implementation for this checkpoint.

`tools/regenerate_parity_fixtures.py` creates deterministic JSON fixtures from that engine. Flutter tests then calculate the same dates using Dart and compare:

- names/classifications;
- month states;
- era years;
- Rashi;
- sunrise/sunset;
- Moon rise/set;
- Tithi/Nakshatra/Yoga/Karana transition times.

The fixture set deliberately includes:

- 27 Sep 2026 Sri Ganganagar baseline;
- Janmashtami 2026;
- Karwa Chauth 2026;
- Diwali 2026;
- Holi 2026;
- 2027 Kshaya Tithi dates;
- Adhik Shravan 2023;
- the 1983 Kshaya Maas sequence.

## Android packaging

The GitHub Actions workflow at `.github/workflows/android.yml` creates the platform-specific Android scaffold only during CI. This keeps generated Gradle boilerplate out of the checkpoint while still producing a normal APK.

CI stages:

```text
Flutter stable
   ↓
Android scaffold
   ↓
flutter pub get
   ↓
flutter analyze
   ↓
flutter test
   ↓
flutter build apk --release
   ↓
APK artifact
```

## Important limitation

The current execution container does not include Flutter/Dart/Android SDK. Therefore this checkpoint has been structurally checked here, but its Dart compiler/Flutter analyzer run is delegated to GitHub Actions.

Do not label this checkpoint "APK verified" until that workflow completes successfully.

## Next checkpoint

Checkpoint 04 should focus on **running the Android CI build, fixing any compiler/runtime discrepancies, testing the APK on a real Android device, performance-profiling month/day navigation, and then adding persistence/notifications only after the base interaction is proven smooth.**
