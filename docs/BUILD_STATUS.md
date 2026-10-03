# Build status — checkpoint 15

Version 1.0.0+15 based on GitHub main 85cbcc613f923d5f3ac236499fb9a71c539cb620.
The user confirmed build14 notification delivery works. Native notification code
and native regression tests are unchanged in this update; no repeated native
compilation/testing was needed for removing Flutter UI controls.

Passed locally: 57 source checks, six permission-audit tests, standalone Dart
parser/format checks, workflow YAML and whitespace checks. The actual Dart
Panchang engine was executed independently for 2026-10-03/Hanumangarh to verify
the sunrise-tithi and daytime transition explanation (see CHECKPOINT_15.md).

Flutter settings tests were updated to retain switch/time/default coverage and
phone-notification settings access, removing tests of deleted user controls.
They require GitHub Flutter analysis/tests before publishing APK/AAB artifacts.
Full local Flutter dependency setup was previously blocked by automatic approval
review for an attempted instance-metadata connection; no bypass was attempted.
Only standalone Dart code/formatting and independent permission checks were run.

Release: upload complete source, wait for Android QA success, then run Production
Play bundle to obtain the signed build15 AAB. Existing signing secrets are retained.
