Hindu Calendar 1.0.0+16 — Android 9 startup compatibility

Replace the repository contents with this full package. Run QA and Production
Play bundle workflows on the same commit. Wait for both to pass. Test the QA
APK on the affected realme 1, then publish the signed build16 AAB.

Root cause found in startup duplicate-task cleanup: RecentTaskInfo.taskId was
read without an API guard. That field is available from API 29 (Android 10),
while Android 9 uses RecentTaskInfo.id. Build 16 selects the correct field and
keeps optional task cleanup from blocking launch on RuntimeException.

Native regression tests cover API 24/28 and API 29/31. These tests are included
in both workflows. Local source and permission-audit checks passed; native
regressions and full Flutter tests must run in GitHub. No physical-device crash
trace was supplied, so the identified startup defect is not yet confirmed as
this phone's only failure. Preserve app data during the update.
