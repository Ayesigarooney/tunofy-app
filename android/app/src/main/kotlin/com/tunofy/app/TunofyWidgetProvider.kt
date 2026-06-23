package com.tunofy.app

import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class TunofyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: android.content.Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        super.onUpdate(context, appWidgetManager, appWidgetIds)
    }

    override fun onUpdate(
        context: android.content.Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
    }
}
