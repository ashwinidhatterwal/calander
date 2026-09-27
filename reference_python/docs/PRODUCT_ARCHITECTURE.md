# Hindu Calendar App — Product & Architecture Plan

## 1. Product Vision

Build a **Hindi-first Hindu calendar app** that feels as simple and familiar as a regular mobile calendar, while providing reliable Hindu calendar information such as **Tithi, Paksha, Hindu month, festivals, sunrise/sunset, Nakshatra, Yoga, Karana, Muhurat, and other Panchang details**.

The app should not feel like a complex astrology tool.

Its primary promise is:

> **"रोज़ का हिन्दू कैलेंडर — सरल, साफ़ और उपयोगी।"**  
> A simple everyday Hindu calendar that anyone can understand.

The default language will be **Hindi**, with a clearly accessible option to switch the entire app to **English**.

---

# 2. Core Product Principles

## 2.1 Hindi First

Hindi is the default product language.

Examples:

- आज
- तिथि
- पक्ष
- मास
- त्योहार
- सूर्योदय
- सूर्यास्त
- नक्षत्र
- योग
- करण
- शुभ समय
- राहुकाल
- आज का पंचांग

English should be available from Settings or a quick language selector.

The app must not show mixed Hindi-English text unnecessarily.

---

## 2.2 Familiar Calendar First

The home screen should look like a **normal monthly calendar**.

Users should immediately understand how to use it without learning Panchang concepts first.

The large number should always be the Gregorian date.

Example:

```text
┌──────────────┐
│      27      │
│   द्वितीया   │
│   आश्विन     │
│      🪔       │
└──────────────┘
```

The Panchang information should enhance the calendar rather than dominate it.

---

## 2.3 High Utility, Low Complexity

The app should answer common questions immediately:

- आज कौन-सी तिथि है?
- कौन-सा हिन्दू महीना चल रहा है?
- आज कोई व्रत या त्योहार है?
- पूर्णिमा / अमावस्या कब है?
- एकादशी कब है?
- सूर्योदय कब है?
- आज का शुभ समय क्या है?
- राहुकाल कब है?
- किसी तारीख का पूरा पंचांग क्या है?

The user should not have to dig through multiple screens for basic information.

---

# 3. Main App Structure

The application should initially have five primary areas:

```text
Home Calendar
Day Details
Festivals
Search
Settings
```

Possible bottom navigation:

```text
कैलेंडर     त्योहार     खोज     सेटिंग्स
Calendar    Festivals    Search   Settings
```

The **Calendar** remains the primary/default tab.

---

# 4. Main Calendar Screen

## 4.1 Purpose

The main screen should answer the most important question instantly:

> "आज और इस महीने हिन्दू कैलेंडर के हिसाब से क्या चल रहा है?"

It should remain clean enough for everyday use.

---

## 4.2 Header

Example:

```text
☰         सितंबर 2026          🔍

        आश्विन मास
```

Possible header elements:

- Month + year
- Hindu month
- Today button
- Search
- Language shortcut
- Location indicator
- Previous / next month navigation

Swipe left/right should change months.

---

## 4.3 Week Header

Default Hindi:

```text
रवि  सोम  मंगल  बुध  गुरु  शुक्र  शनि
```

English mode:

```text
Sun  Mon  Tue  Wed  Thu  Fri  Sat
```

---

## 4.4 Calendar Cell Information

Each date cell should contain only essential information.

### Priority 1

Large Gregorian date:

```text
27
```

### Priority 2

Tithi:

```text
द्वितीया
```

### Priority 3

Festival/event indicator where applicable:

```text
🪔
```

or a short event label if space allows:

```text
एकादशी
```

### Optional

A tiny indicator for:

- पूर्णिमा
- अमावस्या
- संक्रांति
- प्रदोष
- विशेष पर्व

Avoid displaying too much information in the cell.

---

# 5. Today Summary Card

Above or below the monthly calendar, show a compact **Today card**.

Example:

```text
आज — रविवार, 27 सितंबर

शुक्ल द्वितीया
आश्विन मास

सूर्योदय   06:22
सूर्यास्त   18:24

आज का पर्व: —
```

If there is a festival:

```text
आज का पर्व
करवा चौथ
```

Tapping this card should open the Day Details page.

---

# 6. Date Interaction

Tapping any date in the calendar should open a separate **Day Details Page**.

Do not overload the home screen with detailed Panchang information.

Interaction:

```text
Monthly Calendar
       ↓ tap date
Day Details Page
```

---

# 7. Day Details Page

## 7.1 Header

Example:

```text
रविवार
27 सितंबर 2026

आश्विन शुक्ल द्वितीया
```

Provide navigation:

```text
‹ पिछला दिन                अगला दिन ›
```

Swipe left/right may also move between days.

---

# 8. Day Page — Information Hierarchy

The information should be grouped into understandable cards rather than presented as one dense Panchang table.

---

## 8.1 Basic Day Information

This is the first card.

```text
तिथि
शुक्ल द्वितीया

मास
आश्विन

पक्ष
शुक्ल पक्ष

वार
रविवार
```

Also optionally:

- Vikram Samvat
- Shaka Samvat
- Ritu
- Ayana

---

## 8.2 Tithi Timing

Example:

```text
द्वितीया
आज सुबह 07:42 से
कल सुबह 09:18 तक
```

If a Tithi changes during the current day:

```text
द्वितीया 09:18 तक
उसके बाद तृतीया
```

This human-readable presentation is more important than technical formatting.

---

# 9. Festival / Vrat Section

If a festival or vrat occurs that day, it should have a prominent card.

Example:

```text
आज का पर्व

निर्जला एकादशी

एकादशी तिथि:
07:16 AM – 05:42 AM अगले दिन

पारण:
06:04 AM – 08:31 AM
```

Buttons:

```text
पर्व के बारे में जानें
रिमाइंडर लगाएँ
```

If there is no major festival:

```text
आज कोई प्रमुख पर्व नहीं है।
```

---

# 10. Panchang Details

A dedicated Panchang card:

```text
आज का पंचांग

नक्षत्र        रोहिणी
योग             शुभ
करण            बव
चंद्र राशि      वृषभ
सूर्य राशि      कन्या
```

Additional advanced fields can be placed under:

```text
पूरा पंचांग देखें
```

This keeps the default page beginner-friendly.

---

# 11. Sun & Moon Information

Card:

```text
सूर्य और चंद्र

सूर्योदय       06:22
सूर्यास्त       18:24

चंद्रोदय       08:14
चंद्रास्त       19:42
```

Optional:

- Moon phase
- Moon illumination
- Zodiac/Rashi

---

# 12. शुभ / अशुभ समय

Keep this highly readable.

Example:

```text
शुभ समय

अभिजीत मुहूर्त
11:56 – 12:44

ब्रह्म मुहूर्त
04:42 – 05:30
```

Separate card:

```text
सावधानी का समय

राहुकाल
16:42 – 18:12

यमगण्ड
12:12 – 13:42
```

Avoid alarming language.

Use "सावधानी का समय" rather than overly negative wording.

---

# 13. Choghadiya / Hora

These are useful but should not dominate the app.

Default state:

```text
चौघड़िया देखें >
```

Expanded state provides daytime/nighttime Choghadiya.

Likewise:

```text
होरा देखें >
```

This should be an optional advanced feature.

---

# 14. Explanation Layer

One major differentiator should be that the app explains what the Panchang information means.

Example:

```text
द्वितीया क्या है?

द्वितीया प्रत्येक पक्ष की दूसरी तिथि होती है।
आज शुक्ल पक्ष की द्वितीया है, अर्थात चंद्रमा
अमावस्या के बाद बढ़ती अवस्था में है।
```

This educational layer can make the app useful even to people who do not already understand Panchang terminology.

---

# 15. Festival Detail Page

Every major festival can have its own page.

Example structure:

```text
दीपावली

तिथि
कार्तिक अमावस्या

कब है?
8 नवंबर 2027

लक्ष्मी पूजा मुहूर्त
...

महत्व
...

प्रमुख परंपराएँ
...

क्षेत्रीय भिन्नताएँ
...
```

Content should be written in our own words.

Avoid copying copyrighted festival descriptions from other sites.

---

# 16. Language Architecture

The app should be fully localized from the beginning.

Never hard-code Hindi text directly into UI components.

Use translation keys.

Example:

```json
{
  "today": "आज",
  "tithi": "तिथि",
  "paksha": "पक्ष",
  "month": "मास",
  "festival": "त्योहार"
}
```

English:

```json
{
  "today": "Today",
  "tithi": "Tithi",
  "paksha": "Paksha",
  "month": "Month",
  "festival": "Festival"
}
```

Recommended locale codes:

```text
hi-IN
en-IN
```

Hindi is selected by default for new users.

---

# 17. Hindi Typography

Use a Devanagari font that is:

- easy to read
- available legally/free
- supports different Android versions
- legible at small calendar-cell sizes

Potential choices include open-source Devanagari fonts from Google Fonts.

Font usage should support:

- titles
- numbers
- small Tithi labels
- long festival descriptions

Test Hindi carefully on small screens.

---

# 18. Location Architecture

Many Panchang values depend on location.

The app should ask for the user's **city**, rather than requiring GPS.

Example onboarding:

```text
अपना शहर चुनें

श्रीगंगानगर, राजस्थान

[ जारी रखें ]
```

GPS can be offered as an optional convenience:

```text
मेरी वर्तमान लोकेशन चुनें
```

The stored location should contain:

```text
City
State
Country
Latitude
Longitude
Timezone
```

Example:

```json
{
  "city": "Sri Ganganagar",
  "state": "Rajasthan",
  "country": "India",
  "latitude": 29.9,
  "longitude": 73.8,
  "timezone": "Asia/Kolkata"
}
```

---

# 19. Panchang Data Architecture

The Panchang engine should be separated from the UI.

```text
UI
 │
 ▼
Calendar Service
 │
 ├── Panchang Engine
 ├── Festival Engine
 ├── Location Service
 └── Content Database
```

This makes the calculation system independently testable.

---

# 20. Panchang Engine

Core calculations:

```text
Sun longitude
Moon longitude
       ↓
Tithi
Paksha
Nakshatra
Yoga
Karana
```

Additional calculations:

```text
Sunrise
Sunset
Moonrise
Moonset

Hindu month
Ritu
Ayana
Vikram Samvat
Shaka Samvat
```

---

# 21. Astronomy Layer

We do not want paid astronomical licenses.

Therefore:

**No paid Swiss Ephemeris dependency.**

Options:

1. implement required solar/lunar algorithms ourselves;
2. use freely usable astronomical algorithms/data;
3. use publicly available astronomical reference datasets for validation;
4. pre-calculate some data during app builds if useful.

The astronomy module should have a clean interface:

```text
AstronomyEngine
 ├── sunPosition()
 ├── moonPosition()
 ├── sunrise()
 ├── sunset()
 ├── moonrise()
 └── moonset()
```

The Panchang layer should not care how those positions are generated internally.

---

# 22. Tithi Calculation

Conceptually:

```text
moonLongitude - sunLongitude
              ↓
normalize 0–360°
              ↓
divide into 30 segments
              ↓
Tithi
```

Each Tithi spans approximately 12° of angular separation.

The engine must also calculate **Tithi transition times**.

Use numerical refinement to find the exact boundary time.

---

# 23. Nakshatra

The sidereal zodiac is divided into 27 Nakshatras.

Each covers:

```text
13° 20'
```

The calculation module determines:

- current Nakshatra
- start time
- end time

---

# 24. Yoga

Yoga is calculated from a combination of Sun and Moon sidereal longitude.

The engine should return:

```text
Yoga name
Start timestamp
End timestamp
```

---

# 25. Karana

Karana is based on half-Tithi divisions.

Return:

```text
Current Karana
Start time
End time
Next Karana
```

---

# 26. Paksha

Simple classification:

```text
Amavasya → Purnima
= Shukla Paksha

Purnima → Amavasya
= Krishna Paksha
```

Hindi:

```text
शुक्ल पक्ष
कृष्ण पक्ष
```

---

# 27. Hindu Month

The engine should support at least:

- Purnimanta system
- Amanta system

For the Hindi-first North Indian default, choose the appropriate North Indian convention.

Regional calendar mode can be added later.

Months:

```text
चैत्र
वैशाख
ज्येष्ठ
आषाढ़
श्रावण
भाद्रपद
आश्विन
कार्तिक
मार्गशीर्ष
पौष
माघ
फाल्गुन
```

---

# 28. Festival Engine

The festival engine should be separate from the Panchang calculation engine.

```text
FestivalEngine
      │
      ├── Fixed Gregorian rules
      ├── Tithi rules
      ├── Sunrise-based rules
      ├── Sunset-based rules
      ├── Moonrise-based rules
      ├── Nishita rules
      └── Regional exceptions
```

---

# 29. Festival Rule Example

Conceptual only:

```yaml
festival:
  id: janmashtami
  name_hi: जन्माष्टमी
  month: bhadrapada
  paksha: krishna
  tithi: ashtami
  evaluation_period: nishita
```

The real implementation may require more detailed conditions.

---

# 30. Hybrid Festival Strategy

Do not try to mathematically derive every obscure observance in Version 1.

Use three categories.

## A. Engine-calculated recurring events

Examples:

- पूर्णिमा
- अमावस्या
- एकादशी
- प्रदोष
- संकष्टी चतुर्थी
- संक्रांति

## B. Major festivals with verified rules

Examples:

- दीपावली
- होली
- जन्माष्टमी
- महाशिवरात्रि
- राम नवमी
- नवरात्रि
- दशहरा
- रक्षाबंधन
- करवा चौथ
- गणेश चतुर्थी

## C. Minor/regional festivals

Maintain a reviewed yearly dataset initially.

---

# 31. Data Sources and Verification

The app should not depend on one commercial API.

Recommended approach:

```text
Our Calculations
      ↓
Compare Against
      ↓
Government / public Panchang references
Established Panchang sources
Astronomical references
      ↓
Differences flagged for review
```

Sources should be used mainly for:

- validation
- cross-checking
- festival confirmation
- identifying edge cases

Do not copy copyrighted text wholesale.

---

# 32. Data Provenance

Each curated festival entry should optionally retain internal metadata:

```json
{
  "festival_id": "diwali",
  "year": 2027,
  "date": "2027-11-08",
  "region": "north_india",
  "source": "...",
  "verified": true,
  "verified_by": "editor",
  "verified_at": "..."
}
```

This information does not need to be shown to normal users, but it makes corrections manageable.

---

# 33. Offline-First Design

Most daily calendar information should work without internet.

Store/cache:

- Panchang calculation code
- festival rules
- basic festival data
- Hindi/English content
- user preferences

Internet should mainly be needed for:

- content updates
- correction updates
- optional backup/sync
- analytics
- future cloud features

This keeps the app fast and inexpensive.

---

# 34. Precomputation Strategy

For performance, some yearly calculations may be pre-generated during build or update.

Example:

```text
2026
2027
2028
...
2035
    ↓
Generate common calendar transitions
    ↓
Compress/cache
    ↓
Ship/update app data
```

Location-specific calculations can still happen locally.

Do not precompute unnecessary massive datasets until performance testing proves it is needed.

---

# 35. Recommended Technical Architecture

A clean layered architecture:

```text
Presentation Layer
│
├── Calendar Screen
├── Day Screen
├── Festival Screen
├── Search
└── Settings
        │
        ▼
Application Layer
│
├── CalendarService
├── DayService
├── FestivalService
├── ReminderService
└── SearchService
        │
        ▼
Domain Layer
│
├── PanchangEngine
├── FestivalRuleEngine
├── CalendarModels
└── LocalizationModels
        │
        ▼
Infrastructure
│
├── AstronomyEngine
├── Local Database
├── Preferences
├── Update Service
└── Notification Service
```

The calculation engine should have **no dependency on UI code**.

---

# 36. Suggested Mobile Technology

Recommended starting stack:

```text
Flutter
Dart
SQLite / Drift or Isar
Local notifications
Riverpod / Bloc
```

Why Flutter:

- one Android/iOS codebase
- strong animation support
- excellent custom calendar UI
- good Devanagari rendering
- smooth interface
- suitable for offline-first apps

Android can be the first release.

iOS can be added later using the same codebase.

Alternative:

```text
Kotlin + Jetpack Compose
```

This is also excellent if the product will remain Android-only.

---

# 37. Main Domain Models

## PanchangDay

```text
date
timezone
latitude
longitude

weekday

tithi
tithiStart
tithiEnd
nextTithi

paksha

hinduMonth
samvat

nakshatra
nakshatraStart
nakshatraEnd

yoga
karana

sunrise
sunset
moonrise
moonset

festivals[]

muhurta[]
inauspiciousPeriods[]
```

---

# 38. Festival Model

```text
Festival

id
nameHindi
nameEnglish
shortNameHindi
shortNameEnglish

date
type
importance

descriptionHindi
descriptionEnglish

rules
region

fastingInformation
paranaInformation

relatedTithi
```

---

# 39. User Preferences

Store locally:

```text
language
city
latitude
longitude
timezone

calendarTradition

showFestivals
showEkadashi
showPurnima
showAmavasya
showMuhurat

notificationsEnabled

theme
fontSize
```

---

# 40. Search

Search should understand both Hindi and English.

Examples:

```text
दीपावली
Diwali

पूर्णिमा
Purnima

एकादशी
Ekadashi

15 अक्टूबर
15 October
```

Results may include:

- festivals
- dates
- Tithi names
- Hindu months

---

# 41. Quick Navigation

Useful shortcuts:

```text
आज
कल
अगली एकादशी
अगली पूर्णिमा
अगली अमावस्या
अगला प्रमुख त्योहार
```

These provide immediate utility.

---

# 42. Notifications

Useful notifications should be opt-in.

Examples:

```text
कल एकादशी है।
```

```text
पूर्णिमा कल है।
```

```text
दीपावली 3 दिन बाद है।
```

Future enhancement:

```text
पारण का समय शुरू हो गया है।
```

Avoid excessive daily notifications.

---

# 43. User-Created Events

Long-term feature:

Users can add their own events.

Two recurrence systems:

## Gregorian

```text
Every year on 12 March
```

## Hindu Calendar

```text
हर पूर्णिमा
हर एकादशी
हर कार्तिक अमावस्या
हर श्रावण सोमवार
```

This could eventually become one of the app's strongest differentiators.

---

# 44. Home Screen UX Rules

The home screen must remain simple.

Never show all of these simultaneously inside every calendar cell:

- Tithi
- Nakshatra
- Yoga
- Karana
- sunrise
- festival
- Moon sign
- Muhurat

That would make the calendar unreadable.

Home screen hierarchy:

```text
Gregorian date
Tithi
Festival indicator
```

Everything else belongs on the Day Page.

---

# 45. Visual Direction

The visual identity should feel:

- Indian
- calm
- modern
- spiritual without becoming overly decorative
- readable
- premium but simple

Avoid:

- excessive saffron everywhere
- temple clip-art
- crowded Panchang tables
- too many gradients
- unnecessary religious imagery in every component

Use subtle Indian visual cues instead.

---

# 46. Calendar Color Semantics

Potential visual system:

```text
Today
→ highlighted outline/card

Festival
→ small festival marker

Ekadashi
→ unique subtle marker

Purnima
→ moon icon

Amavasya
→ dark moon icon
```

The actual colors should be designed for accessibility and dark/light themes.

---

# 47. Dark Mode

Support:

```text
Light
Dark
System default
```

Ensure Hindi text remains clearly readable.

---

# 48. Accessibility

Must support:

- larger fonts
- TalkBack / screen readers
- high contrast
- large tap areas
- readable Devanagari
- no information encoded only through color

---

# 49. Settings

Suggested Settings sections:

```text
भाषा
स्थान
कैलेंडर पद्धति
त्योहार
सूचनाएँ
दिखावट
डेटा स्रोत / जानकारी
ऐप के बारे में
```

English:

```text
Language
Location
Calendar Tradition
Festivals
Notifications
Appearance
Data Information
About
```

---

# 50. Accuracy and Trust

Users will lose trust quickly if festival dates are wrong.

Therefore accuracy should have dedicated automated tests.

Test categories:

```text
Tithi
Tithi transitions
Paksha
Purnima
Amavasya
Nakshatra
Sunrise
Sunset
Hindu month
Major festivals
Ekadashi
Regional rules
```

---

# 51. Golden Test Dataset

Maintain a manually verified test dataset for selected cities and dates.

Initial cities:

```text
Delhi
Jaipur
Sri Ganganagar
Varanasi
Mumbai
Kolkata
Chennai
Bengaluru
Ahmedabad
Bhopal
```

Test:

```text
365 days/year
multiple years
```

Focus particularly on dates where:

- Tithi ends near sunrise
- Tithi is skipped
- Tithi spans multiple sunrise points
- month changes
- Adhik Maas occurs
- festival rules produce edge cases

---

# 52. Development Phases

## Phase 0 — Research and Standards

Before UI development:

- decide default Hindu month convention
- decide Ayanamsha
- document Tithi rules
- document festival calculation rules
- define supported geographic scope
- define accuracy tolerance
- build reference dataset

Deliverable:

```text
calendar_rules.md
```

---

# 53. Phase 1 — Core Astronomy Engine

Build:

- Julian day/time utilities
- Sun longitude
- Moon longitude
- sunrise
- sunset
- coordinate/timezone utilities

Tests must exist before moving forward.

---

# 54. Phase 2 — Panchang Engine

Implement:

- Tithi
- Paksha
- Nakshatra
- Yoga
- Karana
- Hindu month
- basic Samvat information

Output:

```text
Date + location
      ↓
PanchangDay
```

---

# 55. Phase 3 — Calendar UI Prototype

Build only:

- monthly grid
- today indicator
- Tithi below dates
- Hindu month
- date selection
- previous/next month
- Hindi-first UI

No festival complexity yet.

Goal:

**The calendar must already feel fast and pleasant.**

---

# 56. Phase 4 — Day Details Page

Add:

- basic day info
- Tithi transition
- Panchang
- Sun/Moon
- Muhurat
- explanations

This creates the complete core experience.

---

# 57. Phase 5 — Festival Engine

Implement:

- Purnima
- Amavasya
- Ekadashi
- Sankranti
- major festival rules

Then add curated festival descriptions.

---

# 58. Phase 6 — English Localization

Once Hindi flows are stable:

- translate every UI key
- translate festival names
- translate descriptions
- test layout expansion
- verify no hard-coded Hindi remains

English must use the same architecture, not a separate interface.

---

# 59. Phase 7 — Search + Festival Browser

Build:

```text
Upcoming festivals
Festival calendar
Search
Festival pages
```

---

# 60. Phase 8 — Notifications

Add:

- festival reminders
- Ekadashi reminders
- Purnima reminders
- Amavasya reminders

Keep them configurable.

---

# 61. Phase 9 — Offline Hardening

Test:

- airplane mode
- old cached data
- timezone changes
- location changes
- app upgrade
- date/time changes

The essential calendar must continue working offline.

---

# 62. Phase 10 — Public Beta

Before broad launch:

Test with people who actually use Hindu Panchangs.

Useful groups:

- regular household users
- priests/Pandits
- older users
- younger Hindi-speaking users
- users from different regions

Collect discrepancies rather than only UI feedback.

---

# 63. Version 1 Scope

Version 1 should contain:

### Calendar

- Hindi-first monthly calendar
- Gregorian date
- Tithi
- Hindu month
- festival markers
- Today card

### Day Page

- Tithi
- Paksha
- month
- Nakshatra
- Yoga
- Karana
- sunrise/sunset
- moonrise/moonset
- basic Muhurat
- Rahu Kaal
- festival details

### Festival Features

- major festivals
- Ekadashi
- Purnima
- Amavasya
- upcoming festivals

### Utility

- search
- city selection
- English language switch
- offline operation
- notifications

---

# 64. Features NOT Required for Version 1

Avoid scope creep.

Do not initially build:

- horoscope
- Kundli
- matchmaking
- numerology
- AI astrologer
- live priest consultation
- shopping
- temple booking
- social network
- chat
- large account system

These can distract from the core calendar product.

---

# 65. Long-Term Expansion

Possible future features:

## Hindu recurring reminders

```text
हर एकादशी
हर पूर्णिमा
हर अमावस्या
हर श्रावण सोमवार
```

## Family calendar

Track:

- पूजा
- व्रत
- जन्मदिन
- वर्षगाँठ
- धार्मिक अनुष्ठान

## Widgets

Android home-screen widgets:

```text
आज की तिथि
आज का पंचांग
अगला त्योहार
```

## Wearables

Simple smartwatch display:

```text
आज
शुक्ल पंचमी
```

## Regional calendars

Later add:

- Gujarati
- Marathi
- Bengali
- Tamil
- Telugu
- Kannada
- Malayalam
- Nepali traditions

---

# 66. Possible App Home Layout

Conceptual mobile screen:

```text
┌───────────────────────────┐
│ सितंबर 2026          🔍   │
│ आश्विन मास                │
├───────────────────────────┤
│ आज                        │
│ रविवार, 27 सितंबर         │
│ शुक्ल द्वितीया            │
│ सूर्योदय 06:22            │
├───────────────────────────┤
│ रवि सोम मंगल बुध गुरु... │
│                           │
│      MONTH CALENDAR       │
│                           │
│ 27                        │
│ द्वितीया                  │
│                           │
├───────────────────────────┤
│ अगला प्रमुख पर्व          │
│ नवरात्रि — 4 दिन बाद     │
└───────────────────────────┘
```

---

# 67. Possible Day Page Layout

```text
┌────────────────────────────┐
│ ‹  रविवार, 27 सितंबर   ›   │
│    आश्विन शुक्ल द्वितीया   │
├────────────────────────────┤
│ तिथि                       │
│ द्वितीया                   │
│ 09:18 तक                  │
├────────────────────────────┤
│ आज का पर्व                 │
│ —                          │
├────────────────────────────┤
│ आज का पंचांग               │
│ नक्षत्र  रोहिणी            │
│ योग     शुभ                │
│ करण    बव                  │
├────────────────────────────┤
│ सूर्य और चंद्र             │
│ सूर्योदय 06:22             │
│ सूर्यास्त 18:24            │
├────────────────────────────┤
│ शुभ समय                    │
│ अभिजीत 11:56–12:44        │
├────────────────────────────┤
│ राहुकाल                    │
│ 16:42–18:12                │
├────────────────────────────┤
│ द्वितीया के बारे में जानें │
└────────────────────────────┘
```

---

# 68. Repository Structure

Possible Flutter project:

```text
lib/
│
├── app/
│   ├── app.dart
│   ├── routes.dart
│   └── theme/
│
├── core/
│   ├── localization/
│   ├── time/
│   ├── location/
│   └── utils/
│
├── astronomy/
│   ├── sun/
│   ├── moon/
│   ├── rise_set/
│   └── astronomy_engine.dart
│
├── panchang/
│   ├── models/
│   ├── calculators/
│   ├── panchang_engine.dart
│   └── tests/
│
├── festivals/
│   ├── models/
│   ├── rules/
│   ├── content/
│   └── festival_engine.dart
│
├── features/
│   ├── calendar/
│   ├── day_details/
│   ├── festivals/
│   ├── search/
│   └── settings/
│
├── data/
│   ├── local_database/
│   ├── repositories/
│   └── updates/
│
└── notifications/
```

---

# 69. Testing Structure

```text
test/
│
├── astronomy/
├── tithi/
├── nakshatra/
├── month/
├── festivals/
├── sunrise/
├── localization/
└── golden_reference/
```

Calendar logic should have significantly more automated tests than normal UI code.

---

# 70. Important Product Rule

The app should always distinguish between:

## Calculated data

Examples:

- Tithi
- Nakshatra
- sunrise
- sunset

and

## Editorial / traditional information

Examples:

- why a festival is celebrated
- common rituals
- regional traditions

This allows astronomical errors and content errors to be fixed independently.

---

# 71. Content Management

Initially the festival content can be stored as local structured files.

Example:

```text
assets/content/hi/festivals.json
assets/content/en/festivals.json
```

Later this can move to a remote content system if needed.

Do not introduce a backend until there is a clear reason.

---

# 72. Corrections and Updates

Create a simple versioned data package.

Example:

```text
calendar_data_version = 1.4.2
```

When online:

```text
App checks latest metadata
        ↓
New verified festival/calendar data?
        ↓
Download small update
        ↓
Store locally
```

No full app release should be needed just to correct a festival record.

---

# 73. Privacy

The application should require very little personal information.

Initial version should not require an account.

Store locally:

- selected city
- language
- notification preferences
- UI settings

GPS should remain optional.

This improves privacy and reduces backend complexity.

---

# 74. Monetization — Later Decision

Do not design Version 1 around monetization.

Possible future models:

- non-intrusive ads
- premium widgets
- advanced regional calendars
- cloud sync
- family calendars
- one-time premium purchase

Core Tithi/calendar functionality should remain useful without payment.

---

# 75. Success Criteria for Version 1

The first release is successful if a user can:

1. Open the app.
2. Immediately understand today's Tithi and Hindu month.
3. See important festivals directly on the calendar.
4. Tap a date.
5. Read a clear full Panchang for that date.
6. Find upcoming Ekadashi/Purnima/Amavasya/festivals.
7. Switch from Hindi to English.
8. Use the essential calendar without internet.

That is enough for a strong first product.

---

# 76. Recommended Build Order

The development order should be:

```text
1. Calendar standards/rules document
2. Astronomy calculations
3. Panchang engine
4. Automated verification
5. Hindi calendar UI
6. Day Details UI
7. Festival engine
8. Festival content
9. English localization
10. Search
11. Notifications
12. Offline hardening
13. Beta testing
14. Public release
```

Do **not** start by building dozens of screens.

The engine and main calendar experience are the product foundation.

---

# 77. North Star

Every design and engineering decision should be judged against this question:

> **क्या एक सामान्य हिन्दी-भाषी उपयोगकर्ता बिना पंचांग विशेषज्ञ हुए इस ऐप से आज की हिन्दू तिथि, मास, त्योहार और दिन की महत्वपूर्ण जानकारी तुरंत समझ सकता है?**

If the answer is yes, the app is moving in the right direction.

The final experience should feel like:

> **Google Calendar की सरलता + हिन्दू पंचांग की उपयोगिता**,  
> without turning the app into a cluttered astrology product.
