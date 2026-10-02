package `in`.hinducalendar.hindu_calendar

import android.Manifest
import android.app.ActivityManager
import android.os.Bundle
import android.content.Intent
import android.location.Geocoder
import android.os.Build
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
    private var permissionReply: MethodChannel.Result? = null
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, CalendarAlerts.CHANNEL).setMethodCallHandler { call, reply ->
            when (call.method) {
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
                                        val division = Regex("(^|[\\s,/-])(?:division|संभाग|मंडल)(?=$|[\\s,/-])", RegexOption.IGNORE_CASE)
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
                "configure" -> {
                    val prefs = CalendarAlerts.prefs(this)
                    prefs.edit().putBoolean("morning", call.argument<Boolean>("morning") ?: true)
                        .putBoolean("events", call.argument<Boolean>("events") ?: false)
                        .putBoolean("sound", call.argument<Boolean>("sound") ?: true).apply()
                    CalendarAlerts.schedule(this)
                    if (Build.VERSION.SDK_INT >= 33 && !CalendarAlerts.permitted(this) &&
                        (prefs.getBoolean("morning", true) || prefs.getBoolean("events", false))) {
                        permissionReply = reply
                        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 510)
                    } else reply.success(null)
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
                    CalendarAlerts.prefs(this).let { prefs -> prefs.edit().putString("cache", call.arguments as String).putLong("cacheRevision", prefs.getLong("cacheRevision", 0) + 1).apply() }
                    CalendarAlerts.schedule(this); reply.success(null)
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
        if (requestCode == 510) { permissionReply?.success(null); permissionReply = null }
    }
    override fun onResume() { super.onResume(); CalendarAlerts.schedule(this) }
}
