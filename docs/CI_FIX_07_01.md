# Checkpoint 07 CI Fix 01

Two independent GitHub Actions failures were found after the production-candidate push.

## Android QA workflow

Failure:
`../tools/prepare_android_scaffold.sh: Permission denied`

Cause:
The executable bit on the shell script can be lost when the project ZIP is extracted
and uploaded from some desktop environments.

Fix:
Both QA and Production workflows now invoke the script explicitly with:

`bash ../tools/prepare_android_scaffold.sh`

This makes the workflow independent of filesystem execute permissions.

## Privacy policy site

Failure:
`actions/configure-pages@v5` could not find an enabled Pages site.

Fix:
The workflow now uses `enablement: true`, allowing GitHub Actions to enable Pages
for the repository when the token/repository settings permit it.

No Flutter application, Panchang, festival, personal-event, widget, support-flow,
or calculation logic was changed by this CI-only fix.
