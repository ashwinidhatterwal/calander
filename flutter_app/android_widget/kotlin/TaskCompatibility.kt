package `in`.hinducalendar.hindu_calendar

import android.app.ActivityManager
import android.os.Build

internal object TaskCompatibility {
    @Suppress("DEPRECATION")
    fun taskId(info: ActivityManager.RecentTaskInfo): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) info.taskId else info.id

    fun isOtherAppTask(info: ActivityManager.RecentTaskInfo, currentTaskId: Int, appPackage: String): Boolean {
        val id = taskId(info)
        return id >= 0 && id != currentTaskId && info.baseIntent?.component?.packageName == appPackage
    }
}
