package com.cleantracker.clean_tracker

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

private const val DAY_MS = 86_400_000L

/**
 * Shared helpers for the four Unbound home-screen widgets.
 *
 * The day count is recomputed here from the stored streak-start timestamp, so a
 * "time" or "dashboard" widget stays accurate across day boundaries even while
 * the app is closed (the launcher refreshes it on the widget's update period).
 * Everything else is a plain, pre-localised string written by the Flutter app.
 */
private object WidgetData {
    fun bool(data: SharedPreferences, key: String): Boolean =
        data.getString(key, null) == "true"

    fun text(data: SharedPreferences, key: String, fallback: String): String =
        data.getString(key, null) ?: fallback

    fun days(data: SharedPreferences): Int {
        val start = data.getString("time_start_millis", null)?.toLongOrNull()
        val d = if (start != null) {
            ((System.currentTimeMillis() - start) / DAY_MS).toInt()
        } else {
            data.getString("time_days", null)?.toIntOrNull() ?: 0
        }
        return if (d < 0) 0 else d
    }

    fun open(context: Context, host: String): PendingIntent =
        HomeWidgetLaunchIntent.getActivity(
            context,
            MainActivity::class.java,
            Uri.parse("unbound://$host"),
        )
}

/** Just the clean streak — a blue hero square. */
class TimeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_time)
            val active = WidgetData.bool(widgetData, "has_habit") &&
                WidgetData.bool(widgetData, "time_active")
            if (active) {
                views.setTextViewText(R.id.time_number, WidgetData.days(widgetData).toString())
                views.setTextViewText(
                    R.id.time_label,
                    WidgetData.text(widgetData, "time_label", "days"),
                )
                views.setTextViewText(
                    R.id.time_since,
                    WidgetData.text(widgetData, "time_since", ""),
                )
                views.setViewVisibility(R.id.time_since, View.VISIBLE)
            } else {
                views.setTextViewText(R.id.time_number, "–")
                views.setTextViewText(
                    R.id.time_label,
                    WidgetData.text(widgetData, "empty_hint", "Tap to set up"),
                )
                views.setViewVisibility(R.id.time_since, View.GONE)
            }
            views.setOnClickPendingIntent(R.id.widget_root, WidgetData.open(context, "dashboard"))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** Just the money saved — a gold square. */
class MoneyWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_money)
            if (WidgetData.bool(widgetData, "money_has")) {
                views.setTextViewText(
                    R.id.money_value,
                    WidgetData.text(widgetData, "money_value", "–"),
                )
                views.setTextViewText(
                    R.id.money_label,
                    WidgetData.text(widgetData, "money_label", "Saved"),
                )
            } else {
                views.setTextViewText(R.id.money_value, "–")
                views.setTextViewText(
                    R.id.money_label,
                    WidgetData.text(widgetData, "empty_hint", "Tap to set up"),
                )
            }
            views.setOnClickPendingIntent(R.id.widget_root, WidgetData.open(context, "dashboard"))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** Just the urge button — a berry pill that deep-links into the urge flow. */
class UrgeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_urge)
            views.setTextViewText(
                R.id.urge_title,
                WidgetData.text(widgetData, "urge_title", "Urge?"),
            )
            views.setTextViewText(
                R.id.urge_sub,
                WidgetData.text(widgetData, "urge_sub", "Tap for support"),
            )
            views.setOnClickPendingIntent(R.id.widget_root, WidgetData.open(context, "urge"))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}

/** All four combined — a small cream dashboard card. */
class DashboardWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.widget_dashboard)

            views.setTextViewText(
                R.id.dash_title,
                WidgetData.text(
                    widgetData,
                    "habit_name",
                    WidgetData.text(widgetData, "app_name", "Unbound"),
                ),
            )

            val active = WidgetData.bool(widgetData, "has_habit") &&
                WidgetData.bool(widgetData, "time_active")
            views.setTextViewText(
                R.id.dash_time_value,
                if (active) WidgetData.days(widgetData).toString() else "–",
            )
            views.setTextViewText(
                R.id.dash_time_label,
                WidgetData.text(widgetData, "time_label", "days"),
            )

            views.setTextViewText(
                R.id.dash_money_value,
                if (WidgetData.bool(widgetData, "money_has")) {
                    WidgetData.text(widgetData, "money_value", "–")
                } else {
                    "–"
                },
            )
            views.setTextViewText(
                R.id.dash_money_label,
                WidgetData.text(widgetData, "money_label", "Saved"),
            )

            views.setTextViewText(
                R.id.dash_urge,
                WidgetData.text(widgetData, "urge_title", "Urge?"),
            )

            views.setOnClickPendingIntent(R.id.widget_root, WidgetData.open(context, "dashboard"))
            views.setOnClickPendingIntent(R.id.dash_urge_btn, WidgetData.open(context, "urge"))
            appWidgetManager.updateAppWidget(id, views)
        }
    }
}
