package `in`.hinducalendar.hindu_calendar

import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28,35])
@GraphicsMode(GraphicsMode.Mode.NATIVE)
class CalendarVectorPdfTest {
    private fun month(hindi: Boolean, index: Int): Map<String, Any?> = mapOf(
        "appName" to if (hindi) "हिन्दू कैलेंडर" else "Hindu Calendar",
        "location" to if(hindi) "हनुमानगढ़" else "Hanumangarh",
        "hinduMonths" to if(hindi) "फाल्गुन • चैत्र मास" else "Phalguna • Chaitra Month",
        "gregorianMonth" to if(hindi) "मार्च 2024" else "March 2024",
        "samvat" to if(hindi) "विक्रम संवत 2080" else "Vikram Samvat 2080",
        "caption" to if(hindi) "सूर्योदय की तिथि • भारतीय समय" else "Tithi at sunrise • IST",
        "note" to if(hindi) "तिथि सूर्योदय के समय की है। +1 का अर्थ अगला दिन है।" else "Tithi is shown at sunrise. +1 means the following day.",
        "nakshatraLabel" to if(hindi) "नक्षत्र" else "Nak.",
        "sunriseLabel" to if(hindi) "सूर्योदय" else "Sunrise",
        "sunsetLabel" to if(hindi) "सूर्यास्त" else "Sunset",
        "tithiEndLabel" to if(hindi) "तिथि अंत" else "Ends",
        "weekdays" to if(hindi) listOf("रवि","सोम","मंगल","बुध","गुरु","शुक्र","शनि") else listOf("Sun","Mon","Tue","Wed","Thu","Fri","Sat"),
        "offset" to 5,
        "days" to (1..(if(index==1) 29 else 31)).map { day -> mapOf(
            "day" to "$day", "tithi" to if(hindi) "द्वादशी" else "Dwadashi",
            "paksha" to if(hindi) "शुक्ल पक्ष" else "Shukla Paksha",
            "events" to if(day==25) (if(hindi) "होली • पूर्णिमा व्रत" else "Holi • Purnima Vrat") else "",
            "nakshatra" to if(hindi) "उत्तराभाद्रपद" else "Uttara Bhadrapada",
            "sunrise" to if(hindi) "6:25 पु." else "6:25 AM",
            "sunset" to if(hindi) "6:25 अप." else "6:25 PM",
            "tithiEnd" to if(hindi) "8:01 पु. +1" else "8:01 AM +1") }
    )

    @Test fun hindiAndEnglishPageDesignDrawsOnNativeCanvas() {
        val context = RuntimeEnvironment.getApplication()
        val face = android.graphics.Typeface.createFromAsset(context.assets,
            "flutter_assets/assets/fonts/NotoSansDevanagari.ttf")
        val icon = context.assets.open("flutter_assets/assets/branding/app_icon.png").use {
            android.graphics.BitmapFactory.decodeStream(it) }
        val qr = context.assets.open("flutter_assets/assets/branding/play_store_qr.png").use {
            android.graphics.BitmapFactory.decodeStream(it) }
        try {
            for (hindi in listOf(true, false)) {
                val bitmap = android.graphics.Bitmap.createBitmap(1190,1684,android.graphics.Bitmap.Config.ARGB_8888)
                try {
                    CalendarVectorPdf.drawMonth(android.graphics.Canvas(bitmap),month(hindi,0),face,icon,qr)
                    assertEquals(android.graphics.Color.rgb(255,250,245),bitmap.getPixel(0,20))
                    assertEquals(android.graphics.Color.rgb(168,70,27),bitmap.getPixel(0,0))
                    assertEquals(android.graphics.Color.WHITE,bitmap.getPixel(946,1452))
                } finally { bitmap.recycle() }
            }
        } finally { icon.recycle();qr.recycle() }
    }
}
