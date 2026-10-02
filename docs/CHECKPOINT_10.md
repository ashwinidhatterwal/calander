# Checkpoint 10 — Tester UX and reminders (1.0.0+10)

This builds on Checkpoint 09. The Play package and closed testing track are unchanged.

- Festival/Holidays controls occupy aligned, full-width columns, with category above date range. Major festivals and recurring observances have short Hindi and English explanations in both festival cards and Day Details.
- Current location uses Android's optional Geocoder to obtain a district and state once on explicit acquisition/refresh. Labels and coordinates are persisted; no lookup or GPS request on startup. If naming is unavailable, “Saved location” is shown and manual city selection remains available. Users with an old coordinate-only record can tap Use current location once to obtain a label.
- Annual festival calculations use a shared, coordinate-keyed background isolate cache. Widget payloads are also prepared in an isolate. Calendar month-cell and year caches are retained; astronomy and selection rules are unchanged.
- Native light/dark widget surfaces use alpha backgrounds, including Android 12+; text shares start alignment with consistent spacing, larger key text and two-line titles. Actual rendering depends on launcher size and wallpaper.
- Three-dot menu → Notifications: independent opt-in switches for morning Panchang, personal events and an original gentle chime. A daily 5 AM device-local alarm delivers the cached date/tithi/festival summary and personal events. Saving an event also provides a confirmation notification if enabled. Gregorian and Tithi event matching reuses the existing engine.
- Summaries cover 32 days and renew through a short-lived WorkManager Flutter engine after the daily alarm, boot, clock changes and upgrades. No background GPS, continuous service, Panchang network call or finite annual notification queue. Disabling both switches cancels the alarm. Settings/event/location changes refresh summaries asynchronously.
- Android notification permission is requested on opt-in. “5 AM timing permission” opens optional exact-alarm access; reminders may be delayed when access is denied. Device shutdown, force-stop and battery restrictions can prevent delivery until Android permits the app to run again.
- India’s three national holidays remain separate. Bundled state data currently covers Delhi’s published 2026 government-office holidays and selected Rajasthan 2026 holidays. Regional data is tied to the saved country/state and published year; unsupported regions/years show an availability message. No inferred dates are copied to future years. Moon-sighting changes and subsequent government orders may alter published dates.

Official data sources:
- Rajasthan eMitra: https://emitra.rajasthan.gov.in/emitra/holiday-list (selected verified entries)
- Delhi General Administration Department, 4 December 2025: https://dkvib.delhi.gov.in/sites/default/files/DKVIB/circulars-orders/govtholidays2026.pdf (government-office holidays, excluding restricted holidays)

Permission audit remains fail-closed. New intended permissions are POST_NOTIFICATIONS and SCHEDULE_EXACT_ALARM; foreground approximate/fine location is retained. Background location and optional foreground location service permissions are removed during manifest generation.

Production signing requires the repository's existing GitHub secrets. Local QA artifacts use the generated debug signing configuration and must not be uploaded to Play. Run the existing Production Play bundle workflow after applying the source package, then upload build +10 to the same closed testing track.
