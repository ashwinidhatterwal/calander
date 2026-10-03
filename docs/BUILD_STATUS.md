# Build status — checkpoint 13

Source version 1.0.0+13 based on the released build12 GitHub commit acff0f554106ab5684a02983fc19e2e4341cea8e.

Passed locally:
- Expanded checkpoint13 source/geometry validator (57 checks).
- Six permission-audit tests, including version-code and merged-manifest behavior.
- Shell syntax and embedded Python syntax of Android scaffold.
- Workflow YAML parsing and git diff whitespace checks.
- Dart formatting/parser check of new notification code and tests.

Native notification compilation and all nine native regression tests passed in an independent Android library harness using Android SDK 36, Flutter 3.47.5 embedding, Kotlin 2.1.0, AGP 8.11.1, Gradle 8.14.3, Java 17 and Robolectric 4.17 (API 28 framework simulation). The harness compiles CalendarAlerts, MainActivity, DeviceLocation and ReminderPolicy against real Android/Flutter classes; unchanged HomeWidget provider classes are excluded because the full Flutter plugin graph is not installed locally. It includes the actual notification/widget resources and launcher icons. This is not a full Flutter APK/AAB or Android 16 device test.

Results: CalendarAlertsTest 7 tests, ReminderPolicyTest 2 tests; zero failures/errors.

Flutter analysis/widget tests and APK/AAB build were not completed locally. Automatic approval review blocked Flutter dependency setup because it attempted to contact the cloud instance-metadata endpoint; no bypass was attempted. The updated GitHub QA and Production workflows perform Flutter analysis/tests and native regressions before publishing artifacts.

Physical-device reminder delivery, sound, reboot and overnight behavior require the included test controls and acceptance checklist. No claim of phone delivery verification is made.

## GitHub QA follow-up

Run 37095124305 installed dependencies successfully and analyzed all build13 sources. It reported exactly one missing-braces lint in NotificationsScreen._message; that diagnostic is corrected by CI fix 13-01. Subsequent test/build stages were skipped. A new GitHub run is required after uploading this corrected package. Native code and its nine passing regression tests are unchanged.

Run 37095876407 then passed Analyze, Flutter calculation/UI/personal-calendar tests,
source validation and the QA release APK build. It failed at native test packaging:
`packageDebugUnitTestForUnitTest` consumed Flutter assets without depending on
`copyFlutterAssetsDebug`. Native test execution had not started.

CI fix 13-02 adds the missing producer dependency in the generated Android host
for all variants. A focused, offline Gradle 8.14.3 regression reproduced the same
implicit-dependency validation failure before the fix. After applying the exact
Kotlin block emitted by the scaffold and deleting generated assets, Debug,
Release and DemoDebug packaging all passed, with the Flutter-assets producer
automatically executed before each consumer (nine tasks successful). This checks
task wiring; it does not run the complete GitHub Gradle 9.3.1/Flutter plugin graph.
All 57 source checks, six permission-audit tests, scaffold shell/Python syntax,
workflow YAML and whitespace checks passed again. Native app code is unchanged.
Upload CI fix 13-02 and require a successful new QA run before production release.
