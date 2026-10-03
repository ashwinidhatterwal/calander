Hindu Calendar build 15 — full source package, production CI fix 15-01

Upload the complete contents to ashwinidhatterwal/calander.
Keep flutter_app/, tools/ and .github/ at the repository root.
After uploading this fix, start a NEW Production Play bundle run on main.
Do not rerun the old failed commit. The supported debug host-test task now runs
native regressions before the signed build15 AAB is audited and uploaded.

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
