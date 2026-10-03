package `in`.hinducalendar.hindu_calendar

import android.app.NotificationManager
import android.app.NotificationChannel
import android.content.Context
import androidx.work.Configuration
import androidx.work.testing.WorkManagerTestInitHelper
import org.json.JSONObject
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows
import org.robolectric.annotation.Config
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.Executor

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class CalendarAlertsTest {
    private lateinit var context: Context
    private fun iso() = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
    @Before fun setup() {
        context = RuntimeEnvironment.getApplication()
        CalendarAlerts.prefs(context).edit().clear().commit()
        WorkManagerTestInitHelper.initializeTestWorkManager(context,
            Configuration.Builder().setExecutor(Executor { /* Queue refresh without running Flutter. */ }).build())
        CalendarAlerts.prefs(context).edit().putBoolean("morning", true).putBoolean("events", true)
            .putInt("morningMinute", 0).putInt("eventsMinute", 0).commit()
        seed()
    }
    private fun seed() {
        val item = JSONObject().put("title", "Today").put("body", "Panchang").put("events", "Birthday")
        CalendarAlerts.storeCache(context, JSONObject().put(iso(), item).toString(), true)
    }
    @Test fun blockedPermissionDoesNotConsumeEitherReminder() {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        Shadows.shadowOf(manager).setNotificationsEnabled(false)
        CalendarAlerts.deliverDue(context)
        val p = CalendarAlerts.prefs(context)
        assertFalse(p.contains("morningDelivered"))
        assertFalse(p.contains("eventsDelivered"))
        assertEquals("permission_blocked", p.getString("lastResult", ""))
        Shadows.shadowOf(manager).setNotificationsEnabled(true)
        CalendarAlerts.deliverDue(context)
        assertEquals(iso(), p.getString("morningDelivered", ""))
        assertEquals(iso(), p.getString("eventsDelivered", ""))
    }
    @Test fun missingCacheRetriesAfterNewSummaryArrives() {
        CalendarAlerts.prefs(context).edit().remove("cache").commit()
        CalendarAlerts.deliverDue(context)
        assertFalse(CalendarAlerts.prefs(context).contains("morningDelivered"))
        assertEquals("cache_missing", CalendarAlerts.prefs(context).getString("lastResult", ""))
        seed()
        CalendarAlerts.deliverDue(context)
        assertEquals(iso(), CalendarAlerts.prefs(context).getString("morningDelivered", ""))
    }
    @Test fun blockedChannelDoesNotConsumeReminderOrReportTestSuccess() {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(NotificationChannel("calendar_morning_chime_v1", "Blocked", NotificationManager.IMPORTANCE_NONE))
        CalendarAlerts.deliverDue(context)
        assertFalse(CalendarAlerts.prefs(context).contains("morningDelivered"))
        assertEquals("channel_blocked", CalendarAlerts.prefs(context).getString("lastResult", ""))
        assertFalse(CalendarAlerts.test(context, "Test", "Body", false))
    }
    @Test fun morningDeliveryCannotConsumeLaterEventReminder() {
        val now = Calendar.getInstance()
        val future = (now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE) + 1).coerceAtMost(1439)
        CalendarAlerts.prefs(context).edit().putInt("eventsMinute", future).commit()
        CalendarAlerts.deliverDue(context)
        assertEquals(iso(), CalendarAlerts.prefs(context).getString("morningDelivered", ""))
        if (future > now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE))
            assertFalse(CalendarAlerts.prefs(context).contains("eventsDelivered"))
        CalendarAlerts.prefs(context).edit().putInt("eventsMinute", 0).commit()
        CalendarAlerts.deliverDue(context)
        assertEquals(iso(), CalendarAlerts.prefs(context).getString("eventsDelivered", ""))
    }
    @Test fun immediateTestDoesNotConsumeDailyReminders() {
        assertTrue(CalendarAlerts.test(context, "Test", "Body", false))
        assertFalse(CalendarAlerts.prefs(context).contains("morningDelivered"))
        assertFalse(CalendarAlerts.prefs(context).contains("eventsDelivered"))
    }
    @Test fun schedulingKeepsSelectedTimesAndSeparateNextAlarms() {
        CalendarAlerts.prefs(context).edit().putInt("morningMinute", 375).putInt("eventsMinute", 1145).commit()
        CalendarAlerts.schedule(context)
        val status = CalendarAlerts.status(context)
        assertEquals(375, status["morningMinute"])
        assertEquals(1145, status["eventsMinute"])
        assertTrue((status["nextMorning"] as Long) > System.currentTimeMillis())
        assertTrue((status["nextEvents"] as Long) > System.currentTimeMillis())
    }
    @Test fun postingTwiceDoesNotDuplicateDailyDelivery() {
        CalendarAlerts.deliverDue(context)
        val timestamp = CalendarAlerts.prefs(context).getLong("lastPosted", 0)
        CalendarAlerts.deliverDue(context)
        assertEquals(timestamp, CalendarAlerts.prefs(context).getLong("lastPosted", 0))
    }
}
