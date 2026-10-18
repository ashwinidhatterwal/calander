package `in`.hinducalendar.hindu_calendar

import android.app.Activity
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Rect
import android.os.Build
import android.os.Looper
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.RemoteViews
import android.widget.TextView
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import java.io.File

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28, 35])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class WidgetLayoutTest {
    @Test fun compactAndResizedWidgetsKeepAllThreeRowsVisible() {
        try {
            for (scale in listOf(1f, 1.3f, 1.6f)) {
                // Update the entire application, including contexts RemoteViews
                // creates for its package, rather than an isolated resource copy.
                RuntimeEnvironment.setFontScale(scale)
                for ((width, height) in listOf(180 to 80, 220 to 96, 300 to 150)) {
                    for (upcoming in listOf(false, true)) {
                        for (english in listOf(false, true)) {
                            val controller = Robolectric.buildActivity(Activity::class.java).setup()
                            try {
                                val activity = controller.get()
                                val context: Context = activity
                                val density = context.resources.displayMetrics.density
                                val layoutId = if (upcoming) R.layout.widget_upcoming else R.layout.widget_today
                                val ids = if (upcoming) listOf(R.id.widget_upcoming_kind, R.id.widget_upcoming_title, R.id.widget_upcoming_date)
                                    else listOf(R.id.widget_today_date, R.id.widget_today_tithi, R.id.widget_today_sun)
                                val texts = if (english && upcoming) listOf("Festival / Vrat", "Chaitra Durga Ashtami", "18 October 2026")
                                    else if (english) listOf("Sunday • 18 October", "Shukla Paksha Chaturdashi", "☀ 06:25   ◒ 18:25")
                                    else if (upcoming) listOf("पर्व / व्रत", "शारदीय नवरात्रि आरम्भ", "18 अक्टूबर 2026")
                                    else listOf("रवि • 18 अक्टूबर", "शुक्ल पक्ष चतुर्दशी", "☀ 06:25   ◒ 18:25")
                                val remote = RemoteViews(context.packageName, layoutId)
                                ids.zip(texts).forEach { (id, value) -> remote.setTextViewText(id, value) }
                                val host = FrameLayout(activity)
                                activity.setContentView(host)
                                val view = remote.apply(context, host)
                                val w = (width * density).toInt()
                                val h = (height * density).toInt()
                                host.addView(view, FrameLayout.LayoutParams(w, h))
                                // TextView auto-sizing may request another layout;
                                // a real attached host and looper must process it.
                                repeat(4) {
                                    shadowOf(Looper.getMainLooper()).idle()
                                    view.measure(View.MeasureSpec.makeMeasureSpec(w, View.MeasureSpec.EXACTLY),
                                        View.MeasureSpec.makeMeasureSpec(h, View.MeasureSpec.EXACTLY))
                                    view.layout(0, 0, w, h)
                                }
                                shadowOf(Looper.getMainLooper()).idle()
                                val scenario = "API ${Build.VERSION.SDK_INT} / ${if (upcoming) "upcoming" else "today"} / ${if (english) "en" else "hi"} / $width x $height / font $scale"
                                var previousBottom = 0
                                for (id in ids) {
                                    val text = view.findViewById<TextView>(id)
                                    val available = text.height - text.compoundPaddingTop - text.compoundPaddingBottom
                                    val label = "$scenario / ${context.resources.getResourceEntryName(id)} / text ${text.textSize}px / layout ${text.layout?.height}px / available ${available}px"
                                    assertTrue(label, text.height > 0)
                                    // Window coordinates are undefined for detached
                                    // views; compare descendant bounds in root space.
                                    val bounds = Rect(0, 0, text.width, text.height)
                                    (view as ViewGroup).offsetDescendantRectToMyCoords(text, bounds)
                                    assertTrue(label, bounds.top >= previousBottom)
                                    previousBottom = bounds.bottom
                                    assertTrue(label, bounds.left >= 0 && bounds.right <= view.width)
                                    assertNotNull(label, text.layout)
                                    assertTrue(label, text.layout.height <= available)
                                    for (line in 0 until text.layout.lineCount) {
                                        assertEquals(label, 0, text.layout.getEllipsisCount(line))
                                    }
                                }
                                assertTrue(scenario, previousBottom <= view.height)
                                val output = System.getProperty("calendar.widget.preview.dir")
                                if (output != null && width == 220 && scale == 1.3f) {
                                    val bitmap = Bitmap.createBitmap(view.width, view.height, Bitmap.Config.ARGB_8888)
                                    view.draw(Canvas(bitmap))
                                    val file = File(output, "api${Build.VERSION.SDK_INT}-${if (upcoming) "upcoming" else "today"}-${if (english) "en" else "hi"}.png")
                                    file.parentFile?.mkdirs()
                                    file.outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
                                    bitmap.recycle()
                                }
                            } finally {
                                controller.pause().stop().destroy()
                            }
                        }
                    }
                }
            }
        } finally {
            RuntimeEnvironment.setFontScale(1f)
        }
    }
}
