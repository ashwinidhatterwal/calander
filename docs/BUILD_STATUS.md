# Build Status — Checkpoint 05

## Verified in this environment

- Python Panchang/festival reference tests: **16/16 passing**.
- Checkpoint structural validator: **PASS**.
- No paid/commercial astronomy runtime introduced.
- No web/API dependency introduced for calendar operation.
- Personal event data model/persistence source included.
- GitHub Android build workflow updated for Checkpoint 05.

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
hindu-calendar-checkpoint-05-apk
```

## Device QA focus

1. No black launch screen; warm loading screen should appear.
2. Add a normal yearly birthday and confirm it reappears on the calendar tile.
3. Add a Hindu-Tithi event and confirm it appears on the matching Tithi.
4. Close/reopen the app and confirm personal events persist.
5. Edit/delete an event from My Days.
6. Confirm personal events appear in Day Details.
7. Verify large calendar tiles/festival labels still behave correctly on the target phone.
