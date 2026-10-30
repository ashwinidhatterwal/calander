# Build 34 — Fix Android sharing tests across Robolectric sandboxes

Version 1.0.0+34. Includes all build 33 functionality, natural Hindi, Sanatan readings, and shareable Panchang posters.

## Confirmed failure

GitHub QA run 41007405381 failed at the native test step on commit eafc054645f8b2c1f22813c5113ddbeedb35b1bf. Flutter analysis, all 89 Flutter tests and source checks passed. Of 34 native tests, three image-sharing cases failed on Android API 28/35 with `Failed to find configured root that contains .../cache/calendar_exports/...png` from AndroidX FileProvider.

The uploaded JUnit XML confirms that PNG signature/dimension validation succeeded; the exception was in FileProvider's path lookup. FileProvider cached an export root belonging to a different Robolectric test's temporary app directory. Real installations have a stable application cache path; Robolectric gives each test a different path.

## Fix

Before each PDF/image sharing test, reattach the real FileProvider using the current Robolectric application's ProviderInfo and the existing manifest metadata. AndroidX's attachInfo lifecycle clears the stale authority cache. No reflection, fake provider, weakened validation or skipped assertion is introduced. Both sharing suites use this setup, so test ordering no longer controls which one retains the export root.

Existing checks still verify image/PDF MIME types, the actual readable content URI, temporary read permission, promotional caption, traversal/invalid-data rejection and preserving earlier images across repeated shares. Production sharing code and manifest paths are unchanged.

## Validation

- The GitHub failure reports were retrieved and inspected, including the complete JUnit failure messages and stack traces.
- All 257 uploaded build-33 files were compared by Git blob SHA with the local source before editing; every file matched.
- Source validation and all six permission-audit tests passed after the fix. Workflow YAML and shell syntax checks passed. Version and artifact names consistently identify build 34.
- All 89 Flutter tests and analysis passed in the failed GitHub run; Flutter application code is unchanged by this fix.
- The provider lifecycle fix was checked against AndroidX FileProvider's attachInfo implementation, which removes the cached path strategy for its authority. The same provider and manifest paths remain under test.

The GitHub connection rejected the attempted tree write with HTTP 403 (Resource not accessible by integration). No remote commit or branch was changed. Native tests and APK compilation for the fix must therefore run after uploading this package; they have not yet been rerun. This environment has no local Android SDK/Gradle runner. No physical-phone sharing test has been performed.
