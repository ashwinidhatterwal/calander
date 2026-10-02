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

class UpcomingWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        var slot = -1
        for (i in 0..11) {
            val iso = widgetData.getString("event_${i}_iso", "") ?: ""
            if (iso.isNotBlank() && iso >= today) {
                slot = i
                break
            }
        }
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_upcoming).apply {
                if (slot >= 0) {
                    setTextViewText(R.id.widget_upcoming_kind, widgetData.getString("event_${slot}_kind", "") ?: "")
                    setTextViewText(R.id.widget_upcoming_title, widgetData.getString("event_${slot}_title", "") ?: "")
                    setTextViewText(R.id.widget_upcoming_date, widgetData.getString("event_${slot}_date", "") ?: "")
                } else {
                    setTextViewText(R.id.widget_upcoming_kind, "")
                    setTextViewText(
                        R.id.widget_upcoming_title,
                        widgetData.getString("widget_empty_upcoming", "Open Hindu Calendar") ?: "Open Hindu Calendar",
                    )
                    setTextViewText(
                        R.id.widget_upcoming_date,
                        widgetData.getString("widget_open_app", "Open calendar") ?: "Open calendar",
                    )
                }
                setOnClickPendingIntent(R.id.widget_root, launchIntent(context))
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun launchIntent(context: Context): PendingIntent {
        val intent = CalendarAlerts.launchIntent(context)
        return PendingIntent.getActivity(
            context,
            102,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
