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
    fun prefs(context: Context) = context.getSharedPreferences("calendar_alerts", Context.MODE_PRIVATE)
    fun permitted(context: Context) = NotificationManagerCompat.from(context).areNotificationsEnabled() && (Build.VERSION.SDK_INT < 33 || context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
    fun launchIntent(context: Context) = Intent(context, MainActivity::class.java).apply {
        action = Intent.ACTION_MAIN
        addCategory(Intent.CATEGORY_LAUNCHER)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
    }
    fun status(context: Context): Map<String, Boolean> = mapOf("morning" to prefs(context).getBoolean("morning", true), "events" to prefs(context).getBoolean("events", false), "sound" to prefs(context).getBoolean("sound", true), "permitted" to permitted(context))
    fun schedule(context: Context) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val pending = PendingIntent.getBroadcast(context, 500, Intent(context, CalendarAlarmReceiver::class.java), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        if (!prefs(context).getBoolean("morning", true) && !prefs(context).getBoolean("events", false)) { manager.cancel(pending); return }
        val next = Calendar.getInstance().apply { set(Calendar.HOUR_OF_DAY, 5); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0); if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1) }
        // Ordinary notification permission only. Android may defer this inexact alarm.
        manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, next.timeInMillis, pending)
    }
    fun refresh(context: Context) {
        val request = OneTimeWorkRequestBuilder<CalendarSummaryWorker>().build()
        WorkManager.getInstance(context).enqueueUniqueWork("calendar-summary-refresh", ExistingWorkPolicy.KEEP, request)
    }
    fun show(context: Context, id: Int, title: String, body: String) {
        if (!permitted(context)) return
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val sound = prefs(context).getBoolean("sound", true)
        val channelId = if (sound) "calendar_morning_chime_v1" else "calendar_silent_v1"
        if (Build.VERSION.SDK_INT >= 26) {
            val channel = NotificationChannel(channelId, if (sound) "Calendar gentle reminders" else "Calendar silent reminders", NotificationManager.IMPORTANCE_DEFAULT)
            channel.enableVibration(false)
            channel.setSound(if (sound) Uri.parse("android.resource://${context.packageName}/${R.raw.morning_chime}") else null, AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_NOTIFICATION).build())
            manager.createNotificationChannel(channel)
        }
        val launch = PendingIntent.getActivity(context, id, launchIntent(context), PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        val notification = NotificationCompat.Builder(context, channelId).setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title).setContentText(body).setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setSound(if (sound) Uri.parse("android.resource://${context.packageName}/${R.raw.morning_chime}") else null)
            .setContentIntent(launch).setAutoCancel(true).setOnlyAlertOnce(true).build()
        manager.notify(id, notification)
    }
}

class CalendarAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val prefs = CalendarAlerts.prefs(context)
        if (intent.action == "in.hinducalendar.MORNING" || intent.action == null) {
            val iso = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
            // Dedupe clock adjustments/repeated broadcasts, but permit retry if no cached summary.
            if (prefs.getString("delivered", "") != iso) {
                val item = try { JSONObject(prefs.getString("cache", "{}")!!).optJSONObject(iso) } catch (_: Exception) { null }
                if (item != null) {
                    if (prefs.getBoolean("morning", true)) CalendarAlerts.show(context, 500, item.optString("title"), item.optString("body"))
                    val events = item.optString("events")
                    if (prefs.getBoolean("events", false) && events.isNotBlank()) CalendarAlerts.show(context, 501, item.optString("title"), events)
                    prefs.edit().putString("delivered", iso).apply()
                }
            }
        }
        CalendarAlerts.schedule(context)
        if (prefs.getBoolean("morning", true) || prefs.getBoolean("events", false)) CalendarAlerts.refresh(context)
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
            if (!CalendarAlerts.prefs(applicationContext).getBoolean("morning", true) && !CalendarAlerts.prefs(applicationContext).getBoolean("events", false)) {
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
                        "cache" -> { if (CalendarAlerts.prefs(applicationContext).getLong("cacheRevision", 0) == revision) CalendarAlerts.prefs(applicationContext).edit().putString("cache", call.arguments as String).apply(); reply.success(null); handler.post { finish(Result.success()) } }
                        "failed" -> { reply.success(null); handler.post { finish(Result.retry()) } }
                        else -> reply.notImplemented()
                    }
                }
                workerEngine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "notificationBackground"))
                handler.postDelayed({ finish(Result.retry()) }, 120000)
            } catch (_: Exception) { finish(Result.retry()) }
        }
        if (!completed.await(125, TimeUnit.SECONDS)) {
            handler.post { engine?.destroy(); engine = null }
            return Result.retry()
        }
        return outcome.get()
    }
    override fun onStopped() { handler.post { engine?.destroy(); engine = null } }
}
