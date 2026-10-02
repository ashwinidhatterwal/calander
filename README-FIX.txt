Hindu Calendar build 12 production audit fix

Root cause:
The production AAB built successfully as versionCode 12, but
tools/audit_android_permissions.py still hardcoded versionCode 11.
The permission audit therefore failed after the AAB was already built.

Fix:
1. Replace tools/audit_android_permissions.py with the included file.
2. Replace tools/test_permission_audit.py with the included file.
3. Commit/push to main.
4. Run "Production Play bundle" again.

The fixed audit now reads the expected Android build number directly from
flutter_app/pubspec.yaml, so the same mismatch will not happen on build 13+.
The audit still fails closed for package-id changes and unexpected permissions.
