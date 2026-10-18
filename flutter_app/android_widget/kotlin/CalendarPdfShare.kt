package `in`.hinducalendar.hindu_calendar

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import androidx.core.content.FileProvider
import java.io.File

object CalendarPdfShare {
    fun share(activity: Activity, bytes: ByteArray, filename: String) {
        require(bytes.size >= 8 && bytes.size <= 40 * 1024 * 1024) { "Invalid PDF size" }
        require(String(bytes, 0, 5, Charsets.US_ASCII) == "%PDF-") { "Invalid PDF" }
        require(Regex("Hindu-Calendar-[0-9-]+-(hi|en)\\.pdf").matches(filename)) { "Invalid filename" }
        val directory = File(activity.cacheDir, "calendar_exports").apply { mkdirs() }
        // Keep recent shares readable by receivers; remove only exports > 7 days old.
        directory.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 7L * 86400000 }
            ?.forEach { it.delete() }
        val file = File(directory, filename)
        file.outputStream().use { it.write(bytes) }
        val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.calendar_exports", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "application/pdf"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_SUBJECT, filename.removeSuffix(".pdf"))
            clipData = ClipData.newRawUri("Calendar PDF", uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(Intent.createChooser(send, null).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        })
    }
}
