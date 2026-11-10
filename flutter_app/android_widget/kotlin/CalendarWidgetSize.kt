package `in`.hinducalendar.hindu_calendar

import android.appwidget.AppWidgetManager
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.widget.RemoteViews

internal object CalendarWidgetSize {
    private const val DETAIL_WIDTH = 220
    private const val DETAIL_HEIGHT = 128

    fun views(options: Bundle, render: (showDetails: Boolean) -> RemoteViews): RemoteViews {
        // Modern launchers can choose the right layout for each orientation.
        if (Build.VERSION.SDK_INT >= 31 && options.containsKey(AppWidgetManager.OPTION_APPWIDGET_SIZES)) {
            return RemoteViews(mapOf(
                SizeF(160f, 76f) to render(false),
                SizeF(DETAIL_WIDTH.toFloat(), DETAIL_HEIGHT.toFloat()) to render(true),
            ))
        }
        val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
        val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)
        return render(width >= DETAIL_WIDTH && height >= DETAIL_HEIGHT)
    }
}
