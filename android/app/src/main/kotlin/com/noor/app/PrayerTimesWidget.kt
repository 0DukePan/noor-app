package com.noor.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * 📱 Prayer Times Home Screen Widget
 */
class PrayerTimesWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            
            // Get prayer data
            val nextPrayer = widgetData.getString("next_prayer", "الفجر")
            val nextTime = widgetData.getString("next_time", "--:--")
            val remaining = widgetData.getString("remaining", "")
            val location = widgetData.getString("location", "الموقع غير محدد")
            
            val fajr = widgetData.getString("fajr", "--:--")
            val dhuhr = widgetData.getString("dhuhr", "--:--")
            val asr = widgetData.getString("asr", "--:--")
            val maghrib = widgetData.getString("maghrib", "--:--")
            val isha = widgetData.getString("isha", "--:--")

            // Create RemoteViews
            val views = RemoteViews(context.packageName, R.layout.prayer_times_widget).apply {
                // Next prayer
                setTextViewText(R.id.next_prayer_name, nextPrayer)
                setTextViewText(R.id.next_prayer_time, nextTime)
                setTextViewText(R.id.remaining_time, remaining)
                setTextViewText(R.id.location_name, location)
                
                // All times
                setTextViewText(R.id.fajr_time, fajr)
                setTextViewText(R.id.dhuhr_time, dhuhr)
                setTextViewText(R.id.asr_time, asr)
                setTextViewText(R.id.maghrib_time, maghrib)
                setTextViewText(R.id.isha_time, isha)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
