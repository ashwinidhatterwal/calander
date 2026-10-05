package `in`.hinducalendar.hindu_calendar

import android.app.AlarmManager
import android.content.Intent
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
import org.robolectric.shadows.ShadowAlarmManager
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
    @Test fun morningUsesTithiTitleAndEventsKeepTheirDateTitle() {
        val item = JSONObject().put("title", "Shukla Paksha Ashtami")
            .put("body", "Durga Ashtami\n19 October 2026")
            .put("date", "19 October 2026").put("events", "Birthday")
        CalendarAlerts.storeCache(context, JSONObject().put(iso(), item).toString(), true)
        CalendarAlerts.deliverDue(context)
        val manager = Shadows.shadowOf(context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
        val morning = manager.getNotification(500)
        val events = manager.getNotification(501)
        assertEquals("Shukla Paksha Ashtami", morning.extras.getCharSequence("android.title").toString())
        assertEquals("Durga Ashtami\n19 October 2026\nBirthday", morning.extras.getCharSequence("android.bigText").toString())
        assertEquals("19 October 2026", events.extras.getCharSequence("android.title").toString())
        assertEquals("Birthday", events.extras.getCharSequence("android.text").toString())
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
    @Test fun defaultsEnableBothRemindersAtSixButPreserveSavedChoices() {
        val p = CalendarAlerts.prefs(context)
        p.edit().clear().commit()
        var status = CalendarAlerts.status(context)
        assertEquals(true, status["morning"])
        assertEquals(true, status["events"])
        assertEquals(360, status["morningMinute"])
        assertEquals(360, status["eventsMinute"])
        p.edit().putBoolean("events", false).putInt("eventsMinute", 720).commit()
        status = CalendarAlerts.status(context)
        assertEquals(false, status["events"])
        assertEquals(720, status["eventsMinute"])
    }
    @Test @Config(sdk = [31]) fun delayedTestCannotSilentlyUseInexactAlarm() {
        ShadowAlarmManager.setCanScheduleExactAlarms(false)
        assertFalse(CalendarAlerts.test(context, "Test", "Body", true))
        assertEquals("precise_permission_required", CalendarAlerts.prefs(context).getString("lastTestResult", ""))
        assertEquals(0L, CalendarAlerts.prefs(context).getLong("testScheduled", 0))
        assertFalse(CalendarAlerts.prefs(context).contains("morningDelivered"))
    }
    @Test fun delayedTestPostsOnlyAfterDueAndOnlyOnce() {
        val p = CalendarAlerts.prefs(context)
        val now = System.currentTimeMillis()
        assertTrue(CalendarAlerts.test(context, "Test", "Background", true))
        val at = p.getLong("testScheduled", 0)
        assertEquals(now + 60000, at)
        val alarm = requireNotNull(Shadows.shadowOf(context.getSystemService(Context.ALARM_SERVICE) as AlarmManager).nextScheduledAlarm)
        assertEquals(at, alarm.triggerAtTime)
        assertEquals(CalendarAlerts.TEST, Shadows.shadowOf(alarm.operation).savedIntent.action)
        CalendarAlarmReceiver().onReceive(context, Intent(CalendarAlerts.TEST))
        assertEquals(at, p.getLong("testScheduled", 0))
        assertFalse(p.contains("lastTestPosted"))
        // Model a delayed callback without sleeping or starting a Flutter engine.
        val due = now - 1
        p.edit().putLong("testScheduled", due).commit()
        assertFalse(CalendarAlerts.deliverTestDue(context, at)) // Superseded backup must not post.
        CalendarAlarmReceiver().onReceive(context, Intent(CalendarAlerts.TEST))
        assertEquals("delayed_posted", p.getString("lastTestResult", ""))
        assertEquals(0L, p.getLong("testScheduled", -1))
        assertFalse(CalendarAlerts.deliverTestDue(context))
        assertFalse(p.contains("morningDelivered"))
        assertFalse(p.contains("eventsDelivered"))
    }
    @Test fun blockedDelayedPostCanRecoverAfterPermissionRestored() {
        val p = CalendarAlerts.prefs(context)
        assertTrue(CalendarAlerts.test(context, "Test", "Body", true))
        p.edit().putLong("testScheduled", System.currentTimeMillis() - 1).commit()
        val manager = Shadows.shadowOf(context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager)
        manager.setNotificationsEnabled(false)
        assertFalse(CalendarAlerts.deliverTestDue(context))
        assertEquals("permission_blocked", p.getString("lastTestResult", ""))
        assertTrue(p.getLong("testScheduled", 0) != 0L)
        manager.setNotificationsEnabled(true)
        assertTrue(CalendarAlerts.deliverTestDue(context))
        assertEquals("delayed_posted", p.getString("lastTestResult", ""))
    }

    @Test fun expiredTestDoesNotPostStaleNotification() {
        val p = CalendarAlerts.prefs(context)
        p.edit().putLong("testScheduled", System.currentTimeMillis() - 16 * 60000).commit()
        assertFalse(CalendarAlerts.deliverTestDue(context))
        assertEquals("expired", p.getString("lastTestResult", ""))
        assertEquals(0L, p.getLong("testScheduled", -1))
        assertFalse(p.contains("lastTestPosted"))
    }

}
