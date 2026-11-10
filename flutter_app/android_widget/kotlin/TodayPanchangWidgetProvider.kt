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

class TodayPanchangWidgetProvider : HomeWidgetProvider() {
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
        val slot = (0..13).firstOrNull { widgetData.getString("day_${it}_iso", "") == today }
        fun day(field: String) = slot?.let { widgetData.getString("day_${it}_$field", "") }.orEmpty()
        val weekday = day("weekday")
        val date = day("date")
        val tithi = day("tithi")
        val sunrise = day("sunrise")
        val sunset = day("sunset")
        val details = listOf(day("month"), day("samvat")).filter { it.isNotBlank() }.joinToString(" • ")
        val openApp = widgetData.getString("widget_open_app", "कैलेंडर खोलें").orEmpty()
        val appName = widgetData.getString("widget_app_name", "हिन्दू कैलेंडर").orEmpty()
        val sunriseLabel = widgetData.getString("widget_sunrise", "सूर्योदय").orEmpty()
        val sunsetLabel = widgetData.getString("widget_sunset", "सूर्यास्त").orEmpty()
        val launch = launchIntent(context)
        appWidgetIds.forEach { widgetId ->
            val views = CalendarWidgetSize.views(appWidgetManager.getAppWidgetOptions(widgetId)) { expanded ->
                RemoteViews(context.packageName, R.layout.widget_today).apply {
                    setTextViewText(R.id.widget_today_date, listOf(weekday, date)
                        .filter { it.isNotBlank() }.joinToString(" • ").ifBlank { appName })
                    setTextViewText(R.id.widget_today_tithi, tithi.ifBlank { openApp })
                    setTextViewText(R.id.widget_today_details, details)
                    setViewVisibility(R.id.widget_today_details, if (expanded && details.isNotBlank()) View.VISIBLE else View.GONE)
                    val hasSunTimes = sunrise.isNotBlank() && sunset.isNotBlank()
                    setTextViewText(R.id.widget_today_sun, "↑ $sunrise    ↓ $sunset")
                    setContentDescription(R.id.widget_today_sun, "$sunriseLabel $sunrise, $sunsetLabel $sunset")
                    setViewVisibility(R.id.widget_today_sun, if (hasSunTimes) View.VISIBLE else View.GONE)
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
            101,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
