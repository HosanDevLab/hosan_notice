package com.hosandevlab.hosan_notice

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Typeface
import android.text.SpannableString
import android.text.style.StyleSpan
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class TimetableWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                // Open App on Widget Click
                val pendingIntent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java
                )
                setOnClickPendingIntent(R.id.widget_container, pendingIntent)

                val currentPeriod = widgetData.getInt("currentPeriod", 0)

                val currentPeriodResId =
                    context.resources.getIdentifier("p${currentPeriod}", "id", context.packageName)

                val visibility = widgetData.getBoolean("visibility", false)

                if (visibility) {
                    setViewVisibility(R.id.center_message, View.GONE)
                } else {
                    setViewVisibility(R.id.center_message, View.VISIBLE)
                }

                // Swap Title Text by calling Dart Code in the Background
                List(7) { it + 1 }.forEach {
                    val vid = context.resources.getIdentifier("p${it}", "id", context.packageName)
                    val dataStr = widgetData.getString("p${it}", "")
                    val s = SpannableString(dataStr)

                    if (visibility) {
                        setViewVisibility(vid, View.VISIBLE)
                    } else {
                        setViewVisibility(vid, View.GONE)
                    }

                    if (currentPeriodResId == vid) {
                        s.setSpan(StyleSpan(Typeface.BOLD), 0, 2, 0)
                        setTextColor(vid, 0xFF673AB7.toInt())
                        setTextViewTextSize(currentPeriodResId, TypedValue.COMPLEX_UNIT_DIP, 20F)
                    } else {
                        s.setSpan(StyleSpan(Typeface.NORMAL), 0, 2, 0)
                        setTextColor(vid, 0xFF000000.toInt())
                        setTextViewTextSize(currentPeriodResId, TypedValue.COMPLEX_UNIT_DIP, 17F)
                    }

                    setTextViewText(vid, s)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}