package `in`.hinducalendar.hindu_calendar

import android.app.ActivityManager
import android.content.ComponentName
import android.content.Intent
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
class TaskCompatibilityTest {
    private val appPackage = "in.hinducalendar.hindu_calendar"

    @Suppress("DEPRECATION")
    private fun legacyTask(id: Int) = ActivityManager.RecentTaskInfo().apply {
        this.id = id
        baseIntent = Intent().setComponent(ComponentName(appPackage, "$appPackage.MainActivity"))
    }

    // Run against the actual pre-29 framework: accessing the new taskId field
    // here would fail instead of being hidden by a mock of the latest API.
    @Test @Config(sdk = [24, 28])
    fun legacyAndroidKeepsCurrentTaskAndRemovesOnlyOtherActiveAppTasks() {
        assertEquals(7, TaskCompatibility.taskId(legacyTask(7)))
        assertFalse(TaskCompatibility.isOtherAppTask(legacyTask(7), 7, appPackage))
        assertTrue(TaskCompatibility.isOtherAppTask(legacyTask(8), 7, appPackage))
        assertFalse(TaskCompatibility.isOtherAppTask(legacyTask(-1), 7, appPackage))
        val foreign = legacyTask(8).apply {
            baseIntent = Intent().setComponent(ComponentName("other.app", "other.app.MainActivity"))
        }
        assertFalse(TaskCompatibility.isOtherAppTask(foreign, 7, appPackage))
    }

    @Test @Config(sdk = [29, 31])
    fun modernAndroidUsesModernTaskIdentifier() {
        val info = ActivityManager.RecentTaskInfo().apply {
            taskId = 7
            baseIntent = Intent().setComponent(ComponentName(appPackage, "$appPackage.MainActivity"))
        }
        assertEquals(7, TaskCompatibility.taskId(info))
        assertFalse(TaskCompatibility.isOtherAppTask(info, 7, appPackage))
        info.taskId = 8
        assertTrue(TaskCompatibility.isOtherAppTask(info, 7, appPackage))
    }
}
