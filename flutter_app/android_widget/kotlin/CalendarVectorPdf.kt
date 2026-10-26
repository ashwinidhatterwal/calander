package `in`.hinducalendar.hindu_calendar

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import java.io.ByteArrayOutputStream
import kotlin.math.ceil

/** Native PDF canvas preserves Hindi shaping and embeds scalable glyphs.
 * Only the small app icon is a bitmap; calendar text and QR remain vectors. */
object CalendarVectorPdf {
    const val STORE_URL = "https://play.google.com/store/apps/details?id=in.hinducalendar.hindu_calendar"

    fun build(context: Context, pages: List<Map<String, Any?>>): ByteArray {
        require(pages.size == 1 || pages.size == 12) { "Expected one or twelve months" }
        // Static TrueType faces embed as reusable font subsets. Variable fonts and
        // synthetic bold can force Skia to emit expensive Type 3 glyph paths.
        val face = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/CalendarPdfRegular.ttf")
        val boldFace = Typeface.createFromAsset(context.assets, "flutter_assets/assets/fonts/CalendarPdfBold.ttf")
        val icon = context.assets.open("flutter_assets/assets/branding/app_icon.png").use {
            // The icon is only 37 PDF points wide: 128px remains sharp at print size.
            BitmapFactory.decodeStream(it, null, BitmapFactory.Options().apply { inSampleSize = 8 })
        }
        val qr = context.assets.open("flutter_assets/assets/branding/play_store_qr.png").use { BitmapFactory.decodeStream(it) }
        requireNotNull(icon); requireNotNull(qr)
        val document = PdfDocument()
        try {
            pages.forEachIndexed { index, data ->
                val page = document.startPage(PdfDocument.PageInfo.Builder(595, 842, index + 1).create())
                try {
                    val canvas = page.canvas
                    canvas.scale(.5f, .5f)
                    drawMonth(canvas, data, face, boldFace, icon, qr)
                } finally { document.finishPage(page) }
            }
            val output = ByteArrayOutputStream()
            document.writeTo(output)
            return CalendarPdfLinks.addFooterLinks(output.toByteArray(), STORE_URL)
        } finally {
            document.close()
            icon.recycle(); qr.recycle()
        }
    }

    internal fun drawMonth(c: Canvas, data: Map<String, Any?>, face: Typeface, boldFace: Typeface,
                          icon: android.graphics.Bitmap, qr: android.graphics.Bitmap) {
        val ink = Color.rgb(68, 45, 35)
        val accent = Color.rgb(168, 70, 27)
        val muted = Color.rgb(128, 105, 94)
        fun value(key: String) = data[key] as? String ?: error("Missing $key")
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        fun rect(x: Float, y: Float, w: Float, h: Float, color: Int, radius: Float = 0f, stroke: Boolean = false) {
            paint.color = color; paint.style = if (stroke) Paint.Style.STROKE else Paint.Style.FILL
            paint.strokeWidth = 1f
            c.drawRoundRect(RectF(x, y, x+w, y+h), radius, radius, paint)
        }
        fun text(value: String, x: Float, y: Float, w: Float, size: Float,
                 color: Int = ink, bold: Boolean = false, lines: Int = 1,
                 align: Layout.Alignment = Layout.Alignment.ALIGN_NORMAL, fitWidth: Boolean = false) {
            if (value.isEmpty()) return
            val p = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color; textSize = size; typeface = if (bold) boldFace else face
            }
            if (fitWidth) {
                val measured = p.measureText(value)
                if (measured > w && measured > 0f) p.textSize = size * w / measured
            }
            val layout = StaticLayout.Builder.obtain(value, 0, value.length, p, w.toInt())
                .setAlignment(align).setIncludePad(false).setLineSpacing(0f, 1.18f)
                .setMaxLines(lines).setEllipsize(TextUtils.TruncateAt.END).build()
            c.save(); c.translate(x, y); layout.draw(c); c.restore()
        }
        c.drawColor(Color.rgb(255,250,245))
        rect(0f,0f,1190f,9f,accent)
        text(value("appName"),36f,26f,700f,23f,accent,true)
        text(value("location"),760f,27f,394f,18f,muted,align=Layout.Alignment.ALIGN_OPPOSITE)
        text(value("hinduMonths"),36f,65f,1118f,38f,bold=true)
        text(value("gregorianMonth"),36f,116f,1118f,30f,accent,true)
        text(value("samvat"),36f,165f,600f,17f,muted)
        text(value("caption"),590f,165f,564f,17f,muted,align=Layout.Alignment.ALIGN_OPPOSITE)
        val days = (data["days"] as? List<*>) ?: error("Missing days")
        require(days.size in 28..31)
        val offset = (data["offset"] as Number).toInt()
        require(offset in 0..6)
        val rows = ceil((offset + days.size) / 7.0).toInt()
        val cellW = (1118f-36f)/7f
        val cellH = (1128f-(rows-1)*6f)/rows
        val weekdays = data["weekdays"] as List<*>
        require(weekdays.size == 7)
        weekdays.forEachIndexed { col, day ->
            text(day as String,36f+col*(cellW+6),210f,cellW,19f,
                if(col==0) accent else muted,true,align=Layout.Alignment.ALIGN_CENTER)
        }
        days.forEachIndexed { i, entry ->
            val day = entry as Map<*, *>
            fun d(key: String) = day[key] as? String ?: error("Missing day $key")
            val slot = offset+i
            val x = 36f+(slot%7)*(cellW+6)
            val y = 248f+(slot/7)*(cellH+6)
            rect(x,y,cellW,cellH,Color.rgb(255,240,229),10f)
            rect(x,y,cellW,cellH,Color.rgb(232,213,199),10f,true)
            text(d("tithi"),x+8,y+8,cellW-16,21f,bold=true,fitWidth=true)
            // The month belongs to this date's sunrise, not the page header.
            text(d("hinduMonth"),x+8,y+36,cellW-16,12.5f,muted)
            text(d("events"),x+8,y+55,cellW-16,13f,accent,true,2)
            text("${value("nakshatraLabel")} ${d("nakshatra")}",x+8,y+cellH-96,cellW-16,12f,muted)
            text("${value("sunriseLabel")} ${d("sunrise")}",x+8,y+cellH-79,cellW-16,12f,muted)
            text("${value("sunsetLabel")} ${d("sunset")}",x+8,y+cellH-62,cellW-16,12f,muted)
            text("${value("tithiEndLabel")} ${d("tithiEnd")}",x+8,y+cellH-45,cellW-16,11.5f,muted)
            // Keep paksha separate from the month, beside the Gregorian date.
            text(d("paksha"),x+8,y+cellH-25,cellW-53,10.5f,muted)
            text(d("day"),x+8,y+cellH-29,cellW-16,23f,if(slot%7==0) accent else ink,true,
                align=Layout.Alignment.ALIGN_OPPOSITE)
        }
        text(value("note"),36f,1394f,1118f,13f,muted)
        rect(36f,1440f,1118f,220f,Color.rgb(255,232,213),20f)
        paint.style=Paint.Style.FILL; paint.color=Color.rgb(255,211,168)
        c.drawCircle(94f,1498f,44f,paint)
        c.save()
        val clip = android.graphics.Path().apply { addCircle(94f,1498f,37f,android.graphics.Path.Direction.CW) }
        c.clipPath(clip)
        c.drawBitmap(icon,null,RectF(57f,1461f,131f,1535f),Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG))
        c.restore()
        text("आपका रोज़ का पंचांग, अब मोबाइल पर",152f,1470f,766f,26f,bold=true)
        text("हिन्दू कैलेंडर ऐप डाउनलोड करें",152f,1520f,766f,29f,accent,true)
        text("तिथि, पर्व और व्रत एक जगह। डाउनलोड करने के लिए QR स्कैन करें।",152f,1570f,766f,18f,muted,lines=2)
        // Draw QR pixel runs as filled paths, preserving the original quiet zone.
        rect(946f,1452f,196f,196f,Color.WHITE)
        paint.color=Color.BLACK; paint.style=Paint.Style.FILL; paint.isAntiAlias=false
        val sx=196f/qr.width; val sy=196f/qr.height
        // Adjacent source rows repeat the same QR modules. Draw each band once,
        // instead of hundreds of near-identical one-pixel-high rectangles.
        val pixels = IntArray(qr.width * qr.height)
        qr.getPixels(pixels, 0, qr.width, 0, 0, qr.width, qr.height)
        fun black(row: Int, col: Int) = Color.red(pixels[row * qr.width + col]) < 128
        var row = 0
        while (row < qr.height) {
            var endRow = row + 1
            while (endRow < qr.height && (0 until qr.width).all { black(row, it) == black(endRow, it) }) endRow++
            var col = 0
            while (col < qr.width) {
                if (!black(row, col)) { col++; continue }
                val start = col
                while (col < qr.width && black(row, col)) col++
                c.drawRect(946f+start*sx,1452f+row*sy,946f+col*sx,1452f+endRow*sy,paint)
            }
            row = endRow
        }
    }
}
