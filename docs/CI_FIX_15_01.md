# Production CI fix 15-01

Run 37118946645 at b47004b5d5ccc3f4e5f99a3e7db5cc21fa3921a6 passed release
secret checks, Flutter analysis/tests, source validation, signing configuration,
and creation of the signed 54.3MB AAB. The subsequent Gradle invocation failed:
`testReleaseUnitTest` does not exist in the generated `:app` project. Native test
execution never began, and audit, signature verification and uploads were skipped.

QA run 37118923163 passed on the identical commit, including all native regression
tests using the available `app:testDebugUnitTest` task. Production now uses that
same supported host-test task. Its signed release bundle build, release manifest
permission audit and signature verification remain in place. The source validator
is updated to match the supported commands. No failing test is suppressed or
skipped; no app code, tests, signing secret, permission or version code changes.

This is a pipeline correction for build15, which has not successfully produced a
publishable workflow artifact yet. Upload the corrected source and start a new
Production Play bundle run on the new commit; retrying the old commit preserves
the invalid command. Debug host tests verify the same native notification logic;
they do not execute the optimized signed bundle on a physical device.

Local verification: workflow YAML/commands and source validator passed; six
permission audit tests passed. Complete corrected production execution remains
required on GitHub before publishing. Prior QA success verifies the selected
native task against this exact app/test source, which is unchanged.
