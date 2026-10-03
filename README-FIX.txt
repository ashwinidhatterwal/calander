Hindu Calendar build 15 — full source package

Upload the complete contents to ashwinidhatterwal/calander.
Keep flutter_app/, tools/ and .github/ at the repository root.
After Android QA succeeds, run Production Play bundle for the signed build15 AAB.

User notification settings now contain only:
- Daily Panchang toggle and reminder time
- Personal events toggle and reminder time
- Gentle chime toggle
- Phone notification permission settings
- Alarms & reminders / precise timing settings
- Battery/background settings when applicable

Immediate and one-minute test buttons and the technical status/report row are removed.
The notification delivery/recovery implementation is retained unchanged from the
working build14. Saved preferences, default 6 AM times and default-on events remain.
The calendar's tithi display/calculation is unchanged by this update.
