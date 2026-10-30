package `in`.hinducalendar.hindu_calendar

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import android.graphics.BitmapFactory
import androidx.core.content.FileProvider
import java.io.File

/** Shares the reviewed PNG using the existing private export cache/provider. */
object DiscoveryImageShare {
    fun share(activity: Activity, bytes: ByteArray, filename: String, caption: String) {
        require(bytes.size in 24..(16 * 1024 * 1024)) { "Invalid image size" }
        val signature = byteArrayOf(0x89.toByte(), 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a)
        require(bytes.copyOfRange(0, 8).contentEquals(signature)) { "Invalid PNG" }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        require(bounds.outWidth in 1..2160 && bounds.outHeight in 1..8000) { "Invalid image dimensions" }
        require(Regex("Hindu-Calendar-Discovery-[0-9-]+-(hi|en)\\.png").matches(filename)) { "Invalid filename" }
        val directory = File(activity.cacheDir, "calendar_exports").apply { mkdirs() }
        directory.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 7L * 86400000 }
            ?.forEach { it.delete() }
        val file = File(directory, filename)
        file.outputStream().use { it.write(bytes) }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.calendar_exports", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, caption.take(4000))
            clipData = ClipData.newRawUri("Hindu Calendar", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(Intent.createChooser(send, null).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        })
    }
}
