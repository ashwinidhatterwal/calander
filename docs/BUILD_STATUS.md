# Build Status — Checkpoint 06

## Verified in this environment

- Python Panchang/festival reference tests: **16/16 passing**.
- Checkpoint structural validator: **PASS**.
- Panchang astronomy, Hindu month handling and festival rules unchanged from the verified engine.
- No paid/commercial astronomy runtime introduced.
- No web/API dependency introduced for calendar operation.
- Personal event data remains local-only.
- Checkpoint includes launcher/loading branding, month swipe/picker UX, single-task Android behavior, and native Android widget templates.

## Requires GitHub Actions after push

This environment does not contain Flutter/Android SDK, so these must run on the repository workflow:

```text
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

The workflow should produce:

```text
hindu-calendar-checkpoint-06-apk
```

## Device QA focus

1. Launcher and Recents show the new Hindu Calendar icon.
2. Warm branded loading screen appears without a black frame.
3. Swipe left/right across the calendar: slight resisted movement, then one-month change only after a deliberate swipe.
4. Tap the month/year title and jump directly to another month/year.
5. Event editor example reads `घर की वार्षिक पूजा` rather than the previous remembrance example.
6. Dismiss any old duplicate Recents card once, then confirm subsequent launches keep a single Hindu Calendar task.
7. Add **Today Panchang** and **Upcoming** widgets from the Android widget picker.
8. Verify widgets update after opening the app and after changing language/location or personal events.
9. Switch the phone between light/dark theme; widgets should follow it. On Android 12+ they should also use the phone's dynamic Material You palette.
10. Confirm all prior personal event persistence, festival labels and Day Details behavior still work.
