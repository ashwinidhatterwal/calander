package `in`.hinducalendar.hindu_calendar

import android.Manifest
import android.app.*
import android.content.*
import android.content.pm.PackageManager
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.*
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

object CalendarAlerts {
    const val CHANNEL = "in.hinducalendar/device"
    const val MORNING = "in.hinducalendar.MORNING"
    const val EVENTS = "in.hinducalendar.EVENTS"
    const val FESTIVALS = "in.hinducalendar.FESTIVALS"
    const val DEFAULT_MINUTE = 360
    const val DEFAULT_FESTIVAL_MINUTE = 420
    const val TEST = "in.hinducalendar.TEST"
    private data class Reminder(val key: String, val id: Int, val action: String, val defaultMinute: Int)
    private val reminders = listOf(
        Reminder("morning", 500, MORNING, DEFAULT_MINUTE),
        Reminder("events", 501, EVENTS, DEFAULT_MINUTE),
        Reminder("festivals", 504, FESTIVALS, DEFAULT_FESTIVAL_MINUTE),
    )
    fun prefs(context: Context) = context.getSharedPreferences("calendar_alerts", Context.MODE_PRIVATE)
    fun anyEnabled(prefs: SharedPreferences) = reminders.any { prefs.getBoolean(it.key, true) }
    private fun manager(context: Context) = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    fun permitted(context: Context) = NotificationManagerCompat.from(context).areNotificationsEnabled() && (Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
    fun precise(context: Context) = Build.VERSION.SDK_INT < 31 || manager(context).canScheduleExactAlarms()
    fun launchIntent(context: Context) = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_MAIN
        addCategory(Intent.CATEGORY_LAUNCHER)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
    }
    private fun channelId(context: Context) = if (prefs(context).getBoolean("sound", true)) "calendar_morning_chime_v1" else "calendar_silent_v1"
    private fun ensureChannel(context: Context): NotificationManager {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val sound = prefs(context).getBoolean("sound", true)
        if (Build.VERSION.SDK_INT >= 26 && manager.getNotificationChannel(channelId(context)) == null) {
            val channel = NotificationChannel(channelId(context), if (sound) "Calendar gentle reminders" else "Calendar silent reminders", NotificationManager.IMPORTANCE_DEFAULT)
            channel.enableVibration(false)
            channel.setSound(if (sound) Uri.parse("android.resource://${context.packageName}/${R.raw.morning_chime}") else null, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build())
            manager.createNotificationChannel(channel)
        }
        return manager
    }
    fun channelEnabled(context: Context): Boolean {
        val manager = ensureChannel(context)
        if (Build.VERSION.SDK_INT < 26) return true
        val channel = manager.getNotificationChannel(channelId(context)) ?: return false
        if (channel.importance == NotificationManager.IMPORTANCE_NONE) return false
        return Build.VERSION.SDK_INT < 28 || channel.group == null || manager.getNotificationChannelGroup(channel.group)?.isBlocked != true
    }
    fun status(context: Context): Map<String, Any> {
        val p = prefs(context)
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return mapOf("morning" to p.getBoolean("morning", true), "events" to p.getBoolean("events", true),
            "festivals" to p.getBoolean("festivals", true),
            "sound" to p.getBoolean("sound", true), "permitted" to permitted(context), "channelEnabled" to channelEnabled(context),
            "morningMinute" to ReminderPolicy.minute(p.getInt("morningMinute", DEFAULT_MINUTE)),
            "eventsMinute" to ReminderPolicy.minute(p.getInt("eventsMinute", DEFAULT_MINUTE)),
            "festivalsMinute" to ReminderPolicy.minute(p.getInt("festivalsMinute", DEFAULT_FESTIVAL_MINUTE)),
            "precise" to precise(context), "batteryRestricted" to (Build.VERSION.SDK_INT >= 28 && (context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager).isBackgroundRestricted),
            "batteryOptimized" to !power.isIgnoringBatteryOptimizations(context.packageName),
            "cacheReady" to (cachedToday(context) != null), "cacheUpdated" to p.getLong("cacheUpdated", 0),
            "nextMorning" to p.getLong("nextMorning", 0), "nextEvents" to p.getLong("nextEvents", 0),
            "nextFestivals" to p.getLong("nextFestivals", 0),
            "lastAlarm" to p.getLong("lastAlarm", 0), "lastPosted" to p.getLong("lastPosted", 0),
            "lastResult" to p.getString("lastResult", "not_run").orEmpty(),
            "lastRefreshError" to p.getString("lastRefreshError", "").orEmpty(),
            "testScheduled" to p.getLong("testScheduled", 0),
            "lastTestResult" to p.getString("lastTestResult", "not_run").orEmpty(),
            "lastTestPosted" to p.getLong("lastTestPosted", 0),
            "testBackupError" to p.getString("testBackupError", "").orEmpty())
    }
    private fun pending(context: Context, id: Int, action: String?) = PendingIntent.getBroadcast(context, id,
        Intent(context, CalendarAlarmReceiver::class.java).apply { this.action = action },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun alarm(context: Context, at: Long, pending: PendingIntent) {
        val m = manager(context)
        try {
            if (precise(context)) m.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
            else m.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending)
        } catch (_: SecurityException) { m.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending) }
    }
    fun schedule(context: Context) {
        val p = prefs(context)
        // Remove the legacy action-less 5 AM alarm during upgrade.
        manager(context).cancel(pending(context, 500, null))
        val now = System.currentTimeMillis()
        val cache = readCache(p)
        val edit = p.edit()
        for ((key, id, action, defaultMinute) in reminders) {
            val pi = pending(context, id, action)
            val minute = p.getInt(key + "Minute", defaultMinute)
            val next = when {
                !p.getBoolean(key, true) -> 0L
                key == "festivals" -> nextFestivalCheck(now, minute, cache)
                else -> ReminderPolicy.next(now, minute)
            }
            if (next == 0L) manager(context).cancel(pi) else alarm(context, next, pi)
            edit.putLong("next" + key.replaceFirstChar { it.uppercaseChar() }, next)
        }
        edit.apply()
        if (anyEnabled(p)) {
            WorkManager.getInstance(context).enqueueUniquePeriodicWork("calendar-delivery-recovery", ExistingPeriodicWorkPolicy.KEEP,
                PeriodicWorkRequestBuilder<CalendarRecoveryWorker>(15, TimeUnit.MINUTES).build())
        } else WorkManager.getInstance(context).cancelUniqueWork("calendar-delivery-recovery")
    }
    fun refresh(context: Context) {
        WorkManager.getInstance(context).enqueueUniqueWork("calendar-summary-refresh", ExistingWorkPolicy.KEEP,
            OneTimeWorkRequestBuilder<CalendarSummaryWorker>().build())
    }
    private fun isoDate(time: Long) = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(time))
    private fun readCache(prefs: SharedPreferences): JSONObject = try {
        JSONObject(prefs.getString("cache", "{}").orEmpty())
    } catch (_: Exception) { JSONObject() }
    private fun cachedToday(context: Context): JSONObject? =
        readCache(prefs(context)).optJSONObject(isoDate(System.currentTimeMillis()))

    private fun nextFestivalCheck(now: Long, minute: Int, cache: JSONObject): Long {
        val next = Calendar.getInstance().apply { timeInMillis = ReminderPolicy.next(now, minute) }
        // Skip known ordinary days. Wake on the first unknown day if the cache expires.
        repeat(32) {
            val day = cache.optJSONObject(isoDate(next.timeInMillis))
            if (day == null || !day.has("festivalTitle") || day.optString("festivalTitle").isNotBlank())
                return next.timeInMillis
            next.add(Calendar.DAY_OF_YEAR, 1)
        }
        return next.timeInMillis
    }
    fun storeCache(context: Context, payload: String, foreground: Boolean) {
        val p = prefs(context)
        val edit = p.edit().putString("cache", payload).putLong("cacheUpdated", System.currentTimeMillis()).putString("lastRefreshError", "")
        if (foreground) edit.putLong("cacheRevision", p.getLong("cacheRevision", 0) + 1)
        if (!edit.commit()) throw IllegalStateException("Reminder cache write failed")
    }
    @Synchronized fun deliverDue(context: Context) {
        val p = prefs(context)
        val now = System.currentTimeMillis()
        val iso = isoDate(now)
        val item = readCache(p).optJSONObject(iso)
        for ((key, id, _, defaultMinute) in reminders) {
            if (!p.getBoolean(key, true) || !ReminderPolicy.due(now, p.getInt(key + "Minute", defaultMinute), p.getString(key + "Delivered", "") == iso)) continue
            if (item == null || (key == "morning" && !item.has("summary")) ||
                (key == "festivals" && !item.has("festivalTitle"))) {
                p.edit().putString("lastResult", "cache_missing").apply()
                refresh(context)
                continue
            }
            val body = when (key) {
                "events" -> item.optString("events")
                "festivals" -> item.optString("festivalBody")
                else -> listOf(item.optString("body"), item.optString("events"))
                    .filter { it.isNotBlank() }.joinToString("\n")
            }
            if (key == "events" && body.isBlank()) continue
            // Never consume the day's delivery when permission/channel/posting fails.
            val title = when (key) {
                "events" -> item.optString("date", item.optString("title"))
                "festivals" -> item.optString("festivalTitle")
                else -> item.optString("title")
            }
            if (key == "festivals" && title.isBlank()) continue
            val compact = when (key) {
                "morning" -> item.optString("summary")
                "festivals" -> body.lineSequence().firstOrNull().orEmpty()
                else -> body
            }
            if (show(context, id, title, body, compact)) p.edit().putString(key + "Delivered", iso).commit()
        }
    }
    fun show(context: Context, id: Int, title: String, body: String, compact: String = body): Boolean {
        val p = prefs(context)
        if (!permitted(context)) { p.edit().putString("lastResult", "permission_blocked").apply(); return false }
        if (!channelEnabled(context)) { p.edit().putString("lastResult", "channel_blocked").apply(); return false }
        return try {
            val launch = PendingIntent.getActivity(context, id, launchIntent(context), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val notification = NotificationCompat.Builder(context, channelId(context)).setSmallIcon(R.drawable.ic_notification)
                .setContentTitle(title).setContentText(compact).setStyle(NotificationCompat.BigTextStyle().bigText(body))
                .setSound(if (p.getBoolean("sound", true)) Uri.parse("android.resource://${context.packageName}/${R.raw.morning_chime}") else null)
                .setContentIntent(launch).setAutoCancel(true).setOnlyAlertOnce(false).build()
            ensureChannel(context).notify(id, notification)
            p.edit().putString("lastResult", "posted").putLong("lastPosted", System.currentTimeMillis()).apply()
            true
        } catch (e: Exception) { p.edit().putString("lastResult", "post_failed:" + e.javaClass.simpleName).apply(); false }
    }
    @Synchronized fun test(context: Context, title: String, body: String, delayed: Boolean): Boolean {
        val p = prefs(context)
        if (!permitted(context) || !channelEnabled(context)) {
            show(context, 503, title, body)
            p.edit().putString("lastTestResult", p.getString("lastResult", "blocked")).apply()
            return false
        }
        if (!delayed) {
            val posted = show(context, 503, title, body)
            p.edit().putString("lastTestResult", if (posted) "immediate_posted" else p.getString("lastResult", "post_failed"))
                .putLong("lastTestPosted", if (posted) System.currentTimeMillis() else p.getLong("lastTestPosted", 0)).apply()
            return posted
        }
        // A one-minute test must never silently become an inexact alarm.
        if (!precise(context)) {
            p.edit().putString("lastTestResult", "precise_permission_required").apply()
            return false
        }
        val at = System.currentTimeMillis() + 60000
        if (!p.edit().putString("testTitle", title).putString("testBody", body)
                .putLong("testScheduled", at).putString("lastTestResult", "scheduled")
                .putString("testBackupError", "").commit()) return false
        try {
            manager(context).setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pending(context, 503, TEST))
        } catch (e: Exception) {
            p.edit().putLong("testScheduled", 0)
                .putString("lastTestResult", if (e is SecurityException) "precise_permission_required" else "schedule_failed:" + e.javaClass.simpleName).commit()
            return false
        }
        // Persistent backup survives process death/reboot; delivery is de-duplicated.
        // WorkManager is recovery only, not a promise of exact-minute execution.
        try {
            WorkManager.getInstance(context).enqueueUniqueWork("calendar-test-notification", ExistingWorkPolicy.REPLACE,
                OneTimeWorkRequestBuilder<CalendarTestWorker>().setInitialDelay(60, TimeUnit.SECONDS)
                    .setInputData(workDataOf("scheduledAt" to at)).build())
        } catch (e: Exception) {
            p.edit().putString("testBackupError", e.javaClass.simpleName).apply()
        }
        return true
    }
    @Synchronized fun deliverTestDue(context: Context, expectedAt: Long? = null): Boolean {
        val p = prefs(context)
        val at = p.getLong("testScheduled", 0)
        if (at == 0L || (expectedAt != null && at != expectedAt) || System.currentTimeMillis() < at) return false
        if (System.currentTimeMillis() - at > TimeUnit.MINUTES.toMillis(15)) {
            p.edit().putLong("testScheduled", 0).putString("lastTestResult", "expired").commit()
            return false
        }
        val posted = show(context, 503, p.getString("testTitle", "Test notification").orEmpty(), p.getString("testBody", "").orEmpty())
        val edit = p.edit().putString("lastTestResult", if (posted) "delayed_posted" else p.getString("lastResult", "post_failed"))
        if (posted) edit.putLong("testScheduled", 0).putLong("lastTestPosted", System.currentTimeMillis())
        edit.commit()
        return posted
    }

}

class CalendarAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        CalendarAlerts.prefs(context).edit().putLong("lastAlarm", System.currentTimeMillis()).apply()
        if (intent.action == CalendarAlerts.TEST) {
            CalendarAlerts.deliverTestDue(context)
            return
        }
        CalendarAlerts.deliverTestDue(context)
        CalendarAlerts.deliverDue(context)
        CalendarAlerts.schedule(context)
        if (CalendarAlerts.anyEnabled(CalendarAlerts.prefs(context))) CalendarAlerts.refresh(context)
    }
}

class CalendarTestWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        val at = inputData.getLong("scheduledAt", 0)
        if (at == 0L || CalendarAlerts.prefs(applicationContext).getLong("testScheduled", 0) != at) return Result.success()
        val posted = CalendarAlerts.deliverTestDue(applicationContext, at)
        return if (posted || CalendarAlerts.prefs(applicationContext).getLong("testScheduled", 0) != at)
            Result.success() else Result.retry()
    }
}

class CalendarRecoveryWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    override fun doWork(): Result {
        CalendarAlerts.deliverTestDue(applicationContext)
        CalendarAlerts.deliverDue(applicationContext)
        CalendarAlerts.schedule(applicationContext)
        // Rebuild only when cache is absent/older than a day, avoiding repeated Flutter engines.
        if (System.currentTimeMillis() - CalendarAlerts.prefs(applicationContext).getLong("cacheUpdated", 0) > TimeUnit.HOURS.toMillis(24))
            CalendarAlerts.refresh(applicationContext)
        return Result.success()
    }
}

/** Short-lived headless Flutter engine renews summaries using the same offline
 * Panchang engine and saved settings; no service, GPS, or network requirement. */
class CalendarSummaryWorker(context: Context, params: WorkerParameters) : Worker(context, params) {
    private val handler = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    override fun doWork(): Result {
        val completed = CountDownLatch(1)
        val outcome = AtomicReference(Result.retry())
        fun complete(value: Result) { outcome.set(value); completed.countDown() }
        handler.post {
            if (!CalendarAlerts.anyEnabled(CalendarAlerts.prefs(applicationContext))) {
                complete(Result.success()); return@post
            }
            val revision = CalendarAlerts.prefs(applicationContext).getLong("cacheRevision", 0)
            var finished = false
            fun finish(result: Result) { if (!finished) { finished = true; complete(result); engine?.destroy(); engine = null } }
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(applicationContext); loader.ensureInitializationComplete(applicationContext, null)
                val workerEngine = FlutterEngine(applicationContext)
                engine = workerEngine
                MethodChannel(workerEngine.dartExecutor.binaryMessenger, CalendarAlerts.CHANNEL).setMethodCallHandler { call, reply ->
                    when (call.method) {
                        "cache" -> { if (CalendarAlerts.prefs(applicationContext).getLong("cacheRevision", 0) == revision) CalendarAlerts.storeCache(applicationContext, call.arguments as String, false); reply.success(null); CalendarAlerts.deliverDue(applicationContext); CalendarAlerts.schedule(applicationContext); handler.post { finish(Result.success()) } }
                        "failed" -> {
                            CalendarAlerts.prefs(applicationContext).edit().putString("lastRefreshError", call.arguments?.toString() ?: "summary_failed").apply()
                            reply.success(null); handler.post { finish(Result.retry()) }
                        }
                        else -> reply.notImplemented()
                    }
                }
                workerEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "notificationBackground"))
                handler.postDelayed({
                    if (!finished) CalendarAlerts.prefs(applicationContext).edit().putString("lastRefreshError", "summary_timeout").apply()
                    finish(Result.retry())
                }, 120000)
            } catch (e: Exception) {
                CalendarAlerts.prefs(applicationContext).edit().putString("lastRefreshError", e.javaClass.simpleName).apply()
                finish(Result.retry())
            }
        }
        if (!completed.await(125, TimeUnit.SECONDS)) {
            handler.post { engine?.destroy(); engine = null }
            return Result.retry()
        }
        return outcome.get()
    }
    override fun onStopped() { handler.post { engine?.destroy(); engine = null } }
}
