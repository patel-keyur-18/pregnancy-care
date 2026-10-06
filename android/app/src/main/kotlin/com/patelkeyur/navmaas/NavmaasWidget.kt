package com.patelkeyur.navmaas

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * The home-screen widget (ARCHITECTURE §10). It never opens the database:
 * it shows the snapshot the app writes (`lib/features/home_widget`), picking
 * today's entry and the next reminder still ahead. Every word comes from the
 * snapshot. A tap opens Today through Flutter's deep link.
 */
class NavmaasWidget : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val snapshot = widgetData.getString("snapshot", null)?.let {
            runCatching { JSONObject(it) }.getOrNull()
        }
        val open = PendingIntent.getActivity(
            context,
            0,
            Intent(Intent.ACTION_VIEW, Uri.parse("navmaas://widget/today"), context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        for (id in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.navmaas_widget)
            render(views, snapshot)
            views.setOnClickPendingIntent(R.id.widget_root, open)
            appWidgetManager.updateAppWidget(id, views)
        }
    }

    private fun render(views: RemoteViews, s: JSONObject?) {
        if (s == null || s.optBoolean("stopped", true)) return // the mark alone
        val labels = s.getJSONObject("labels")
        val format = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        val calendar = Calendar.getInstance()
        val today = format.format(calendar.time)
        calendar.add(Calendar.DATE, 1)
        val tomorrow = format.format(calendar.time)
        val now = System.currentTimeMillis()

        val next = s.getJSONArray("next").let { list ->
            (0 until list.length()).map { list.getJSONObject(it) }.firstOrNull { it.getLong("at") > now }
        }
        val whenText = next?.let {
            val time = it.getString("time")
            when (it.getString("date")) {
                today -> time
                tomorrow -> "${labels.getString("tomorrow")} $time"
                else -> "${it.getString("weekday")} $time"
            }
        }
        val day = s.getJSONArray("days").let { list ->
            (0 until list.length()).map { list.getJSONObject(it) }.firstOrNull { it.getString("date") == today }
        }

        views.setViewVisibility(R.id.widget_mark_only, View.GONE)
        views.setViewVisibility(R.id.widget_body, View.VISIBLE)
        views.setTextViewText(R.id.widget_name, labels.getString("name"))
        val details = day != null && !s.optBoolean("hidden")
        for (v in listOf(R.id.widget_week, R.id.widget_size, R.id.widget_next)) {
            views.setViewVisibility(v, if (details) View.VISIBLE else View.GONE)
        }
        for (v in listOf(R.id.widget_hidden_label, R.id.widget_hidden_when)) {
            views.setViewVisibility(v, if (details) View.GONE else View.VISIBLE)
        }
        if (details) {
            views.setTextViewText(R.id.widget_week, day!!.getString("weekDay"))
            val size = day.getString("size")
            views.setTextViewText(R.id.widget_size, size)
            views.setViewVisibility(R.id.widget_size, if (size.isEmpty()) View.GONE else View.VISIBLE)
            views.setTextViewText(R.id.widget_next_label, labels.getString("next"))
            views.setTextViewText(R.id.widget_next_title, next?.optString("title") ?: labels.getString("none"))
            views.setTextViewText(R.id.widget_next_when, whenText ?: "")
            views.setViewVisibility(R.id.widget_next_when, if (whenText == null) View.GONE else View.VISIBLE)
        } else {
            views.setTextViewText(R.id.widget_hidden_label, labels.getString("nextReminder"))
            views.setTextViewText(R.id.widget_hidden_when, whenText ?: labels.getString("none"))
        }
    }
}
