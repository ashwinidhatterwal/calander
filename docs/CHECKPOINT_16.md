# Build 16: legacy Android startup

Based on GitHub commit 7bd5af38fcfca9b69b2e7f753c1e0665ef95cf6e.

The duplicate-task cleanup in MainActivity.onCreate used RecentTaskInfo.taskId
unconditionally. Android introduced that field in API 29; API 28 exposes id.
TaskCompatibility guards the new field, preserves the active task, excludes
inactive and foreign tasks, and checks package identity. RuntimeException from
optional cleanup is logged instead of aborting startup.

TaskCompatibilityTest uses real Robolectric SDKs 24/28 and 29/31, rather than
mocking a current framework. Both existing native workflow test steps copy and
run these tests automatically. Physical realme 1 verification remains required.

References:
https://developer.android.com/reference/android/app/ActivityManager.RecentTaskInfo
https://developer.android.com/reference/android/app/TaskInfo

Local validation: checkpoint16 source checks, permission audit unit tests and
ZIP integrity. No local Flutter/native execution was performed for this fix.
Build 15 UI, notification, GPS and calendar calculations remain unchanged.
