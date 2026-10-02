package `in`.hinducalendar.hindu_calendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TodayPanchangWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        var slot = 0
        for (i in 0..13) {
            if (widgetData.getString("day_${i}_iso", "") == today) {
                slot = i
                break
            }
        }
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_today).apply {
                val weekday = widgetData.getString("day_${slot}_weekday", "") ?: ""
                val date = widgetData.getString("day_${slot}_date", "") ?: ""
                val tithi = widgetData.getString("day_${slot}_tithi", "हिन्दू कैलेंडर") ?: "हिन्दू कैलेंडर"
                val month = widgetData.getString("day_${slot}_month", "") ?: ""
                val sunrise = widgetData.getString("day_${slot}_sunrise", "—") ?: "—"
                val sunset = widgetData.getString("day_${slot}_sunset", "—") ?: "—"
                setTextViewText(R.id.widget_today_date, listOf(weekday, date).filter { it.isNotBlank() }.joinToString(" • "))
                setTextViewText(R.id.widget_today_tithi, tithi)
                setTextViewText(R.id.widget_today_month, month)
                setTextViewText(R.id.widget_today_sun, "☀ $sunrise   ◒ $sunset")
                setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun launchIntent(context: Context): PendingIntent {
        val intent = CalendarAlerts.launchIntent(context)
        return PendingIntent.getActivity(
            context,
            101,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
