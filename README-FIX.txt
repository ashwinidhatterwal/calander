Hindu Calendar build 13 — full source package

Upload this complete package to the existing ashwinidhatterwal/calander repository.
Keep flutter_app/, tools/ and .github/ at the repository root.
Android QA build produces the APK and runs Flutter plus native notification tests.
Run Production Play bundle on main for the signed build13 Play Store AAB.
Existing signing and support secrets are retained; no new secret is required.

On the updated app: three-dot menu > Notifications.
Enable Daily Panchang and Personal events as desired.
Select each reminder time independently.
Allow notifications and, for precise timing, Alarms & reminders.
Use Send test notification now; then Test in one minute and close the app normally.
Without precise alarm access, Android can delay the scheduled test.
If either test fails, tap notification status and copy the local report.
