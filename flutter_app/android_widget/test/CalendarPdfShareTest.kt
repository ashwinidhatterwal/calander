package `in`.hinducalendar.hindu_calendar

import android.app.Activity
import android.content.Intent
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class CalendarPdfShareTest {
    @Test fun android9SharesPdfWithTemporaryReadAccess() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val bytes = "%PDF-1.4\ncalendar\n%%EOF".toByteArray()
        CalendarPdfShare.share(activity, bytes, "Hindu-Calendar-2026-10-hi.pdf")
        val chooser = shadowOf(activity).nextStartedActivity
        assertEquals(Intent.ACTION_CHOOSER, chooser.action)
        @Suppress("DEPRECATION")
        val send = chooser.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)!!
        assertEquals("application/pdf", send.type)
        assertEquals(Intent.ACTION_SEND, send.action)
        assertTrue(send.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
        val uri = send.clipData!!.getItemAt(0).uri
        assertEquals("content", uri.scheme)
        activity.contentResolver.openInputStream(uri)!!.use {
            assertArrayEquals(bytes, it.readBytes())
        }
    }
    @Test(expected = IllegalArgumentException::class)
    fun rejectsPathTraversal() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        CalendarPdfShare.share(activity, "%PDF-1.4\n".toByteArray(), "../private.pdf")
    }
    @Test(expected = IllegalArgumentException::class)
    fun rejectsNonPdfData() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        CalendarPdfShare.share(activity, "not a PDF document".toByteArray(), "Hindu-Calendar-2026-en.pdf")
    }
}
