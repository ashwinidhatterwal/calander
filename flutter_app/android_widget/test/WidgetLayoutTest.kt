package `in`.hinducalendar.hindu_calendar

import android.content.Context
import android.content.res.Configuration
import android.view.View
import android.widget.FrameLayout
import android.widget.RemoteViews
import android.widget.TextView
import org.robolectric.RuntimeEnvironment
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28, 35])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetLayoutTest {
    @Test fun compactAndResizedWidgetsKeepAllThreeRowsVisible() {
        val base: Context = RuntimeEnvironment.getApplication()
        for (scale in listOf(1f, 1.3f, 1.6f)) {
            val config = Configuration(base.resources.configuration).apply { fontScale = scale }
            val context = base.createConfigurationContext(config)
            val density = context.resources.displayMetrics.density
            for ((width, height) in listOf(180 to 80, 220 to 96, 300 to 150)) {
                for (upcoming in listOf(false, true)) {
                  for (english in listOf(false, true)) {
                    val layoutId = if (upcoming) R.layout.widget_upcoming else R.layout.widget_today
                    val ids = if (upcoming) listOf(R.id.widget_upcoming_kind, R.id.widget_upcoming_title, R.id.widget_upcoming_date)
                        else listOf(R.id.widget_today_date, R.id.widget_today_tithi, R.id.widget_today_sun)
                    val texts = if (english && upcoming) listOf("Festival / Vrat", "Chaitra Durga Ashtami", "18 October 2026")
                        else if (english) listOf("Sunday • 18 October", "Shukla Paksha Chaturdashi", "☀ 06:25   ◒ 18:25")
                        else if (upcoming) listOf("पर्व / व्रत", "शारदीय नवरात्रि आरम्भ", "18 अक्टूबर 2026")
                        else listOf("रवि • 18 अक्टूबर", "शुक्ल पक्ष चतुर्दशी", "☀ 06:25   ◒ 18:25")
                    val remote = RemoteViews(context.packageName, layoutId)
                    ids.zip(texts).forEach { (id, text) -> remote.setTextViewText(id, text) }
                    val view = remote.apply(context, FrameLayout(context))
                    val w = (width * density).toInt()
                    val h = (height * density).toInt()
                    repeat(3) {
                        view.measure(View.MeasureSpec.makeMeasureSpec(w, View.MeasureSpec.EXACTLY),
                            View.MeasureSpec.makeMeasureSpec(h, View.MeasureSpec.EXACTLY))
                        view.layout(0, 0, w, h)
                    }
                    var previousBottom = 0f
                    for (id in ids) {
                        val text = view.findViewById<TextView>(id)
                        val label = "$width x $height / font $scale / view $id"
                        assertTrue(label, text.height > 0)
                        val coordinates = IntArray(2); text.getLocationInWindow(coordinates)
                        assertTrue(label, coordinates[1].toFloat() >= previousBottom)
                        previousBottom = coordinates[1] + text.height.toFloat()
                        assertNotNull(label, text.layout)
                        assertTrue(label, text.layout.height <= text.height - text.compoundPaddingTop - text.compoundPaddingBottom)
                        for (line in 0 until text.layout.lineCount) {
                            assertEquals(label, 0, text.layout.getEllipsisCount(line))
                        }
                    }
                    assertTrue(previousBottom <= h)
                  }
                }
            }
        }
    }
}
