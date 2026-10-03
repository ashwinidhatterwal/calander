# Build 13 CI fix 01

Failed GitHub QA run: https://github.com/ashwinidhatterwal/calander/actions/runs/37095124305
Commit inspected: 0f1eb22f047849de32f0a1dd301eae5bc484cd2a.

The Analyze step failed on exactly one issue: curly_braces_in_flow_control_structures in lib/screens/notifications_screen.dart, line 39. _message() had a multiline if (mounted) body without braces. The project's Flutter lint configuration makes that analyzer diagnostic fatal in CI.

Wrapped the existing Snackbar statement in braces. No behavior, notification schedule, permissions, signing identity or build number changes. The source validator and permission tests remain passing; the notification native code is unchanged from its nine passing regression tests.

GitHub successfully installed dependencies and analyzed the other sources; tests and APK/native-build stages were skipped because analysis failed. Upload the corrected full package to main and let the QA workflow run again. Keep version 1.0.0+13; this build has not yet produced a release artifact. Then run Production Play bundle for the signed AAB.
