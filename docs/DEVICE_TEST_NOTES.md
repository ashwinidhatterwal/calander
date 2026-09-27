# Checkpoint 05 device test

## Startup

- Launch from fully closed state.
- Confirm native launch background is warm, not black.
- Confirm `हिन्दू कैलेंडर / तिथि • पर्व • आपके दिन` loading screen appears if initialization takes noticeable time.

## Gregorian personal event

1. Open `मेरे दिन`.
2. Add a birthday or anniversary.
3. Choose `सामान्य तारीख`.
4. Keep yearly repeat enabled.
5. Save.
6. Navigate to that month and confirm the title appears in the tile if no major festival takes priority.

## Hindu-Tithi personal event

1. Add a new event.
2. Choose `हिन्दू तिथि`.
3. Select Hindu month + Paksha + Tithi.
4. Save.
5. Confirm My Days resolves the next Gregorian occurrence.
6. Open that date and confirm the event appears on Day Details.

## Persistence

- Force close the app.
- Reopen it.
- Verify all personal events remain.

## Language

- Switch Hindi ↔ English.
- Open My Days and event editor.
- Confirm the date picker and field labels follow the app language.
