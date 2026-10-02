package `in`.hinducalendar.hindu_calendar

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.CancellationSignal
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import androidx.core.content.ContextCompat
import androidx.core.location.LocationManagerCompat
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executor

/** Explicit GPS/network one-shot fallback; never silently selects fused. */
class DeviceLocation(private val context: Context) {
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executor { command -> handler.post(command) }
    private val signals = mutableListOf<CancellationSignal>()
    private var generation = 0
    private var pending: MethodChannel.Result? = null
    private var timeout: Runnable? = null

    fun status(): Map<String, Any> {
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return mapOf("enabled" to LocationManagerCompat.isLocationEnabled(manager),
            "gpsEnabled" to (manager.allProviders.contains(LocationManager.GPS_PROVIDER) && manager.isProviderEnabled(LocationManager.GPS_PROVIDER)),
            "networkEnabled" to (manager.allProviders.contains(LocationManager.NETWORK_PROVIDER) && manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)),
            "precisePermission" to (ContextCompat.checkSelfPermission(context,
                Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED))
    }

    fun request(reply: MethodChannel.Result) {
        if (pending != null) {
            reply.error("location_busy", "A location request is already running", null)
            return
        }
        val manager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val fine = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
        val coarse = ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED
        if (!fine && !coarse) {
            reply.error("location_permission", "Foreground location permission is required", null)
            return
        }
        if (!LocationManagerCompat.isLocationEnabled(manager)) {
            reply.error("location_disabled", "Device location is disabled", null)
            return
        }
        val providers = listOf(LocationManager.GPS_PROVIDER, LocationManager.NETWORK_PROVIDER).filter {
            (it != LocationManager.GPS_PROVIDER || fine) && manager.allProviders.contains(it) && manager.isProviderEnabled(it)
        }
        if (providers.isEmpty()) {
            reply.error("location_no_provider", "No usable GPS/network provider", mapOf("precisePermission" to fine))
            return
        }
        pending = reply
        val requestGeneration = ++generation
        var best: Location? = null
        var remaining = providers.size
        val failures = mutableListOf<String>()
        fun finishCandidate() {
            val candidate = best
            if (candidate != null) {
                succeed(candidate)
            } else {
                fail(if (failures.size == providers.size) "location_provider_error" else "location_timeout",
                    "GPS/network providers returned no recent fix",
                    mapOf("providers" to providers, "precisePermission" to fine, "failures" to failures))
            }
        }
        timeout = Runnable { finishCandidate() }.also { handler.postDelayed(it, 45000L) }
        for (provider in providers) {
            if (pending == null) break
            val signal = CancellationSignal()
            signals.add(signal)
            try {
                LocationManagerCompat.getCurrentLocation(manager, provider, signal, executor) { fix ->
                    if (pending != null && generation == requestGeneration) {
                        val age = fix?.let { SystemClock.elapsedRealtimeNanos() - it.elapsedRealtimeNanos }
                        if (fix != null && age != null && age >= 0 && age <= 120000000000L &&
                            fix.latitude.isFinite() && fix.longitude.isFinite() &&
                            fix.latitude in -90.0..90.0 && fix.longitude in -180.0..180.0 &&
                            fix.hasAccuracy() && fix.accuracy.isFinite() && fix.accuracy >= 0) {
                            val previous = best
                            if (previous == null || fix.accuracy < previous.accuracy) best = fix
                            if (fix.accuracy <= 2000) succeed(fix)
                        }
                        remaining--
                        if (pending != null && remaining == 0) finishCandidate()
                    }
                }
            } catch (error: Exception) {
                if (error is SecurityException) {
                    fail("location_permission", "Permission changed during acquisition", null)
                    break
                }
                failures.add("$provider: ${error.javaClass.simpleName}")
                remaining--
                if (remaining == 0 && pending != null) finishCandidate()
            }
        }
    }

    private fun succeed(fix: Location) {
        val reply = pending ?: return
        cleanup()
        reply.success(mapOf("latitude" to fix.latitude, "longitude" to fix.longitude,
            "accuracy" to fix.accuracy.toDouble(), "timestamp" to fix.time,
            "provider" to fix.provider))
    }

    private fun fail(code: String, message: String, details: Any?) {
        val reply = pending ?: return
        cleanup()
        reply.error(code, message, details)
    }

    private fun cleanup() {
        pending = null
        timeout?.let { handler.removeCallbacks(it) }
        timeout = null
        signals.forEach { it.cancel() }
        signals.clear()
    }

    fun close() { fail("location_cancelled", "Activity closed", null) }
}
