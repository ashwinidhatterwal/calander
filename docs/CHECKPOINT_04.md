# Checkpoint 04 — Real-device UX + Utility Pass

## Goal

Turn the successfully compiled and installed Checkpoint 03 Android app into a more useful everyday calendar without expanding product scope or destabilizing the Panchang engine.

## Requested change implemented

Date tiles are larger and now include a short festival/vrat label directly inside the tile.

Tile hierarchy:

```text
27
प्रतिपदा

एकादशी / दीपावली / पूर्णिमा / ...
```

Only one short event label is shown so the month view remains readable. Major festivals take priority over recurring observances.

## Calendar UX changes

- larger tile height and touch area;
- visible card boundaries for in-month dates;
- stronger date number hierarchy;
- larger Tithi text;
- inline event capsule;
- no unexplained dot-only status system;
- lightweight cached cell calculations for smoother rebuilds.

## Day Details changes

- Tithi/Nakshatra/Yoga/Karana transition times use day-aware language;
- Hindi dayparts: सुबह / दोपहर / शाम / रात;
- next-day transitions explicitly use `कल`;
- English uses Today/Tomorrow + AM/PM;
- festival/vrat card is visually emphasized and uses compact chips.

## Festival browser changes

- compact rows;
- Upcoming filter defaults on;
- Full-year filter available;
- year navigation retained.

## Engine boundary

No astronomical formulas, Panchang calculations, month rules, or major-festival selection rules were changed in this checkpoint.

## Version

`0.4.0+4`
