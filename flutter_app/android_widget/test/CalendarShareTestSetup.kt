package `in`.hinducalendar.hindu_calendar

import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import org.robolectric.RuntimeEnvironment

/**
 * Robolectric creates a new cache directory for each test. AndroidX's static
 * FileProvider path cache can outlive that directory between sandboxes.
 * Reattach through the real provider lifecycle so its cached root is rebuilt
 * from this test's application and the actual manifest path configuration.
 */
object CalendarShareTestSetup {
    fun attachProviderForCurrentSandbox() {
        val app = RuntimeEnvironment.getApplication()
        val authority = "${app.packageName}.calendar_exports"
        val info = requireNotNull(app.packageManager.resolveContentProvider(
            authority, PackageManager.GET_META_DATA)) { "Export provider missing from manifest" }
        FileProvider().attachInfo(app, info)
    }
}
