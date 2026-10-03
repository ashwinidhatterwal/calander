package `in`.hinducalendar.hindu_calendar

import org.junit.Assert.*
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

class ReminderPolicyTest {
    @Test fun selectedTimeUsesPhoneTimezoneAndAdvancesByCalendarDay() {
        val previous = TimeZone.getDefault()
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("Asia/Kolkata"))
            val now = Calendar.getInstance().apply { set(2026, 9, 3, 6, 10, 0); set(Calendar.MILLISECOND, 0) }.timeInMillis
            assertTrue(ReminderPolicy.due(now, 300, false))
            assertFalse(ReminderPolicy.due(now, 420, false))
            assertFalse(ReminderPolicy.due(now, 300, true))
            val next = Calendar.getInstance().apply { timeInMillis = ReminderPolicy.next(now, 300) }
            assertEquals(4, next.get(Calendar.DAY_OF_MONTH))
            assertEquals(5, next.get(Calendar.HOUR_OF_DAY))
            assertEquals(0, next.get(Calendar.MINUTE))
        } finally { TimeZone.setDefault(previous) }
    }
    @Test fun midnightNoonAndInvalidPreferencesAreBounded() {
        assertEquals(0, ReminderPolicy.minute(-9))
        assertEquals(1439, ReminderPolicy.minute(9999))
        val now = Calendar.getInstance().apply { set(2026, 9, 3, 12, 0, 0); set(Calendar.MILLISECOND, 0) }.timeInMillis
        assertTrue(ReminderPolicy.due(now, 720, false))
        assertTrue(ReminderPolicy.next(now, 720) > now)
    }
}
