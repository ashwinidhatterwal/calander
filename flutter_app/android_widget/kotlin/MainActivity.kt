package `in`.hinducalendar.hindu_calendar

import android.Manifest
import android.app.ActivityManager
import android.os.Bundle
import android.content.Intent
import android.location.Geocoder
import android.os.Build
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Locale
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Remove legacy duplicate tasks left by old widget/notification launch flags.
        (getSystemService(ACTIVITY_SERVICE) as ActivityManager).appTasks.forEach { task ->
            val info = task.taskInfo
            if (info.taskId != taskId && info.baseIntent.component?.packageName == packageName) task.finishAndRemoveTask()
        }
    }
    private val deviceLocation by lazy { DeviceLocation(this) }
    override fun onDestroy() { deviceLocation.close(); super.onDestroy() }
    private var permissionReply: MethodChannel.Result? = null
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, CalendarAlerts.CHANNEL).setMethodCallHandler { call, reply ->
            when (call.method) {
                "currentPosition" -> deviceLocation.request(reply)
                "locationStatus" -> reply.success(deviceLocation.status())
                "district" -> {
                    val lat = call.argument<Double>("latitude")!!
                    val lon = call.argument<Double>("longitude")!!
                    Executors.newSingleThreadExecutor().also { pool -> pool.execute {
                        val names = mutableMapOf<String, String>()
                        try {
                            if (Geocoder.isPresent()) {
                                for ((language, suffix) in listOf("en" to "En", "hi" to "Hi")) {
                                    @Suppress("DEPRECATION")
                                    val address = Geocoder(this, Locale(language, "IN")).getFromLocation(lat, lon, 1)?.firstOrNull()
                                    address?.let {
                                        // Providers sometimes put an administrative division here.
                                        val division = Regex("(^|[\\s,/-])(?:division|संभाग|मंडल|ड[िी]व[िी](?:ज़|ज)न)(?=$|[\\s,/-])", RegexOption.IGNORE_CASE)
                                        it.subAdminArea?.takeIf { name -> name.isNotBlank() && !division.containsMatchIn(name) }?.let { name -> names["district$suffix"] = name }
                                        it.adminArea?.let { state -> names["state$suffix"] = state }
                                        it.countryCode?.let { code -> names["countryCode"] = code }
                                    }
                                }
                            }
                        } catch (_: Exception) { }
                        runOnUiThread { reply.success(names) }; pool.shutdown()
                    } }
                }
                "status" -> reply.success(CalendarAlerts.status(this))
                "notificationSettings" -> {
                    startActivity(Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, packageName))
                    reply.success(null)
                }
                "alarmSettings" -> {
                    if (Build.VERSION.SDK_INT >= 31) startActivity(Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM, Uri.parse("package:$packageName")))
                    reply.success(null)
                }
                "batterySettings" -> {
                    startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$packageName")))
                    reply.success(null)
                }
                "testNotification" -> reply.success(CalendarAlerts.test(this,
                    call.argument<String>("title") ?: "Test notification",
                    call.argument<String>("body") ?: "",
                    call.argument<Boolean>("delayed") ?: false))
                "configure" -> {
                    val prefs = CalendarAlerts.prefs(this)
                    val saved = prefs.edit().putBoolean("morning", call.argument<Boolean>("morning") ?: true)
                        .putBoolean("events", call.argument<Boolean>("events") ?: false)
                        .putBoolean("sound", call.argument<Boolean>("sound") ?: true)
                        .putInt("morningMinute", ReminderPolicy.minute(call.argument<Int>("morningMinute") ?: prefs.getInt("morningMinute", 300)))
                        .putInt("eventsMinute", ReminderPolicy.minute(call.argument<Int>("eventsMinute") ?: prefs.getInt("eventsMinute", 300))).commit()
                    if (!saved) {
                        reply.error("settings_write_failed", "Could not save reminder settings", null)
                        return@setMethodCallHandler
                    }
                    CalendarAlerts.schedule(this)
                    if (Build.VERSION.SDK_INT >= 33 && !CalendarAlerts.permitted(this) &&
                        (prefs.getBoolean("morning", true) || prefs.getBoolean("events", false))) {
                        permissionReply = reply
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 510)
                    } else { CalendarAlerts.deliverDue(this); reply.success(null) }
                }
                "initializeNotifications" -> {
                    val prefs = CalendarAlerts.prefs(this)
                    // No key means the user never chose a preference. Preserve explicit opt-outs.
                    if (!prefs.contains("morning")) prefs.edit().putBoolean("morning", true).apply()
                    if (!prefs.getBoolean("notificationPrompted", false) && prefs.getBoolean("morning", true)) {
                        prefs.edit().putBoolean("notificationPrompted", true).apply()
                        if (Build.VERSION.SDK_INT >= 33 && !CalendarAlerts.permitted(this)) {
                            permissionReply = reply
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 510)
                        } else reply.success(null)
                    } else reply.success(null)
                    CalendarAlerts.schedule(this)
                }
                "cache" -> {
                    CalendarAlerts.storeCache(this, call.arguments as String, true)
                    CalendarAlerts.deliverDue(this); CalendarAlerts.schedule(this); reply.success(null)
                }
                "created" -> {
                    if (CalendarAlerts.prefs(this).getBoolean("events", false))
                        CalendarAlerts.show(this, 502, call.argument<String>("title") ?: "Event saved", call.argument<String>("body") ?: "")
                    reply.success(null)
                }
                else -> reply.notImplemented()
            }
        }
    }
    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 510) {
            CalendarAlerts.deliverDue(this); CalendarAlerts.schedule(this)
            permissionReply?.success(null); permissionReply = null
        }
    }
    override fun onResume() {
        super.onResume()
        CalendarAlerts.deliverDue(this)
        CalendarAlerts.schedule(this)
    }
}
