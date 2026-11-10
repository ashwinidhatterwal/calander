package `in`.hinducalendar.hindu_calendar

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class UpcomingWidgetProvider : HomeWidgetProvider() {
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        // Route through HomeWidgetProvider so resizing uses the current shared data.
        onReceive(context, Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, intArrayOf(appWidgetId))
        })
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date())
        val slots = (0..11).filter { i ->
            val iso = widgetData.getString("event_${i}_iso", "") ?: ""
            iso.isNotBlank() && iso >= today && !widgetData.getString("event_${i}_title", "").isNullOrBlank()
        }
        val first = slots.getOrNull(0)
        val second = slots.getOrNull(1)
        fun event(slot: Int?, field: String) =
            slot?.let { widgetData.getString("event_${it}_$field", "") }.orEmpty()
        val nextLabel = widgetData.getString("widget_next", "इसके बाद").orEmpty()
        val next = second?.let { "$nextLabel: ${event(it, "title")} • ${event(it, "date")}" }.orEmpty()
        val launch = launchIntent(context)
        appWidgetIds.forEach { widgetId ->
            val views = CalendarWidgetSize.views(appWidgetManager.getAppWidgetOptions(widgetId)) { expanded ->
                RemoteViews(context.packageName, R.layout.widget_upcoming).apply {
                    setTextViewText(R.id.widget_upcoming_kind, event(first, "kind")
                        .ifBlank { widgetData.getString("widget_app_name", "हिन्दू कैलेंडर").orEmpty() })
                    setTextViewText(R.id.widget_upcoming_title, event(first, "title")
                        .ifBlank { widgetData.getString("widget_empty_upcoming", "कोई आगामी कार्यक्रम नहीं").orEmpty() })
                    setTextViewText(R.id.widget_upcoming_date, event(first, "date")
                        .ifBlank { widgetData.getString("widget_open_app", "कैलेंडर खोलें").orEmpty() })
                    setTextViewText(R.id.widget_upcoming_next, next)
                    setViewVisibility(R.id.widget_upcoming_next, if (expanded && next.isNotBlank()) View.VISIBLE else View.GONE)
                    setOnClickPendingIntent(R.id.widget_root, launch)
                }
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
