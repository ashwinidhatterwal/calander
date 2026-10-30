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
import java.util.Base64

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28, 35])
class DiscoveryImageShareTest {
    private fun png(): ByteArray = Base64.getDecoder().decode("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4////fwAJ+wP9KobjigAAAABJRU5ErkJggg==")
    @Test fun sharesPngWithReadableContentUriAndStoreLink() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val bytes = png()
        val caption = "हिन्दू कैलेंडर\n${CalendarVectorPdf.STORE_URL}"
        DiscoveryImageShare.share(activity, bytes,
            "Hindu-Calendar-Discovery-2026-10-30-123-hi.png", caption)
        val chooser = shadowOf(activity).nextStartedActivity
        assertEquals(Intent.ACTION_CHOOSER, chooser.action)
        @Suppress("DEPRECATION")
        val send = chooser.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)!!
        assertEquals(Intent.ACTION_SEND, send.action)
        assertEquals("image/png", send.type)
        assertEquals(caption, send.getStringExtra(Intent.EXTRA_TEXT))
        assertTrue(send.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
        val uri = send.clipData!!.getItemAt(0).uri
        assertEquals("content", uri.scheme)
        activity.contentResolver.openInputStream(uri)!!.use {
            assertArrayEquals(bytes, it.readBytes())
        }
    }
    @Test(expected = IllegalArgumentException::class)
    fun rejectsTraversal() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        DiscoveryImageShare.share(activity, png(), "../private.png", "")
    }
    @Test(expected = IllegalArgumentException::class)
    fun rejectsInvalidImage() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        DiscoveryImageShare.share(activity, ByteArray(32),
            "Hindu-Calendar-Discovery-2026-10-30-123-hi.png", "")
    }
    @Test fun separateSharesKeepEarlierImageReadable() {
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        val bytes = png()
        DiscoveryImageShare.share(activity, bytes,
            "Hindu-Calendar-Discovery-2026-10-30-123-hi.png", "first")
        @Suppress("DEPRECATION")
        val first = shadowOf(activity).nextStartedActivity
            .getParcelableExtra<Intent>(Intent.EXTRA_INTENT)!!
        val uri = first.clipData!!.getItemAt(0).uri
        DiscoveryImageShare.share(activity, bytes,
            "Hindu-Calendar-Discovery-2026-10-30-124-hi.png", "second")
        activity.contentResolver.openInputStream(uri)!!.use {
            assertArrayEquals(bytes, it.readBytes())
        }
    }
}
