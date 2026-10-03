# CI fix 13-02: native host-test asset dependency

GitHub QA run 37095876407, commit e639e15d123e5d78d474d5ff76c449ada2e35fb0,
passed Flutter analysis, Flutter tests, source validation and release APK build.
It failed before executing native tests, while Gradle 9.3.1 validated
`:app:packageDebugUnitTestForUnitTest`.

The native host-test packager reads the merged Android assets directory. Flutter's
`copyFlutterAssetsDebug` task writes into that directory, but no dependency linked
the consumer to the producer. Gradle correctly rejects this task graph because
execution order can otherwise change the packaged assets.

The Android scaffold now declares `dependsOn(copyFlutterAssets<Variant>)` for
each `package<Variant>UnitTestForUnitTest` task. This covers QA debug tests,
production release tests and future flavored variants. Dependencies resolve
lazily by name, so Flutter may register its tasks later during configuration.
Native tests and resource packaging remain enabled. No toolchain downgrade,
signing-secret change or app version increment is needed.

Reference: https://docs.gradle.org/current/userguide/validation_problems.html#implicit_dependency

Validation results are recorded in BUILD_STATUS.md. A new GitHub QA run is still
required to verify the complete Flutter/Android plugin graph.
