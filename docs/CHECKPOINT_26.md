# Build 26 - festival selection and tithi transition audit

## Confirmed causes

1. Sharad Purnima was absent from the annual rules; the sole generic Purnima
   label used sunrise. In 2026 Purnima starts during October 25 and persists
   into October 26. Sharad/Kojagari belongs to October 25 night, while the
   sunrise Purnima label on October 26 is appropriate.
2. Dussehra was already correctly October 20, 2026 for Hanumangarh. The tile
   showed only Navami at sunrise; Dashami begins around midday. North Indian
   Dussehra uses the afternoon window, while Bengal observance can differ.
3. Sampling five instants in a puja window can miss short tithi overlap.
4. Preferred-window-only selection had unresolved annual events: Karwa Chauth
   2025 after Chaturthi ends before moonrise; Govardhan 2028 when Pratipada is
   absent at sunrise; Dhanteras/Govardhan 2029 when the preferred window lacks
   the target tithi. An exception aborted the entire year's event list.

## Implementation

Annual Sharad/Kojagari uses the existing Nishita window and regular Ashwin
month. Window matching now visits each exact tithi interval, excluding adhik
copies of annual festivals. Dussehra retains its North Indian Aparahna rule
and adds a short explanation of sunrise/afternoon/regional distinctions.

Govardhan uses pratahkala, with daylight fallback only if no morning match
exists. Karwa Chauth retains moonrise selection, with sunrise fallback only
if neither candidate moonrise has Chaturthi. Dhanteras retains Pradosha, with
sunrise fallback when Pradosha has no match. A reviewed North India exception
sets Janmashtami 2025 to August 15; the existing simplified general profile and
sect-variation note remain for other years. These are targeted rules, not a
claim to implement every Dharmashastra exception or regional convention.

A shared tithisForDay() returns the sunrise-to-next-sunrise sequence, including
multiple transitions on kshaya days and no extra transition on vriddhi days.
Calendar cards show the following tithi below the bold sunrise tithi. Today
and PDF show the sequence; Day Details explicitly labels the sunrise tithi.
PDF headings fit their width using the same static font and Android shaping;
its note identifies the first-change time and the +1 convention. Existing
fast-opening vector fonts and QR optimisations remain.

## Validation actually performed

- 1,485 checks run against production synchronous Dart calculation code:
  39 published-date checks (13 fixtures in Hanumangarh, Delhi, Jaipur),
  12 Sharad/Dussehra integration checks, 336 annual-rule completeness checks
  for 2024-2030, and 1,098 daily-sequence checks across the three locations.
- All 34 existing 2026/2027 festival-date parity fixtures still pass.
- Dart analysis of the changed calculation engine and verification harness:
  no issues. Source validator: 84 checks pass. Permission audit: 6 tests pass.
- The local verifier supplies a minimal Flutter foundation import shim that
  throws if compute() is called. Tests use the actual unmodified synchronous
  production methods, not mocked astronomy. Flutter isolate/UI/plugin paths
  were NOT executed locally. New regression is also wired into flutter test.
- Existing native PDF layout fixture now includes long dual-tithi labels.

## Required remaining checks

Full Flutter analysis/tests, native PDF rendering and APK/AAB builds must run
on GitHub before release. Test transition-label readability on the phone and
newly generated PDFs. The few-minute astronomical differences noted against
Drik Panchang are not corrected by these observance-rule changes. This release
validates the stated North Indian cases; it does not certify every regional,
Smarta/Vaishnava or future-date edge case. The Python reference engine is an
archived baseline; the Flutter Dart engine is the production implementation.

## Published comparison sources (checked 2026-10-26)

- Sharad Purnima 2026: https://www.drikpanchang.com/purnima/sharad/sharad-purnima-date-time.html?year=2026
- Kojagara 2026: https://www.drikpanchang.com/festivals/kojagara/kojagara-puja-date-time.html?year=2026
- Dussehra 2026: https://www.drikpanchang.com/festivals/vijayadashami/vijayadashami-date-time.html?year=2026
- 2027 calendar: https://www.drikpanchang.com/calendars/hindu/hinducalendar.html?geoname-id=1273294&year=2027
- 2028 calendar: https://www.drikpanchang.com/calendars/indian/indiancalendar.html?lang=en&year=2028
- 2029 calendar: https://www.drikpanchang.com/calendars/hindu/hinducalendar.html?geoname-id=1253914&year=2029
- Karwa Chauth 2025: https://www.drikpanchang.com/festivals/karwa-chauth/karwa-chauth-date-time.html?year=2025
- Janmashtami 2025 Jaipur: https://www.drikpanchang.com/dashavatara/lord-krishna/krishna-janmashtami-date-time.html?geoname-id=1269515&year=2025
- Dussehra 2025/2027: https://www.drikpanchang.com/hindu-festivals/dussehra/dussehra.html
- Sharad 2025: https://www.drikpanchang.com/purnima/sharad/sharad-purnima-date-time.html?lang=en&year=2025
- Sharad 2028: https://www.drikpanchang.com/purnima/sharad/sharad-purnima-date-time.html?year=2028
