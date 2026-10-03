package `in`.hinducalendar.hindu_calendar

import java.util.Calendar

/** Shared by alarms, cache completion and background recovery. */
object ReminderPolicy {
    fun minute(value: Int) = value.coerceIn(0, 1439)
    fun dueAt(now: Long, requestedMinute: Int): Long = Calendar.getInstance().apply {
        timeInMillis = now
        set(Calendar.HOUR_OF_DAY, minute(requestedMinute) / 60)
        set(Calendar.MINUTE, minute(requestedMinute) % 60)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis
    fun next(now: Long, minute: Int): Long = Calendar.getInstance().apply {
        timeInMillis = dueAt(now, minute)
        if (timeInMillis <= now) add(Calendar.DAY_OF_YEAR, 1)
    }.timeInMillis
    fun due(now: Long, minute: Int, delivered: Boolean) = !delivered && now >= dueAt(now, minute)
}
