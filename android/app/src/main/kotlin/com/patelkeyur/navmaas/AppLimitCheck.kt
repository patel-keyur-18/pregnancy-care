package com.patelkeyur.navmaas

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

/**
 * The app-limit check (Plan decision 53, ADR 050). Every 15 minutes, only
 * while a limit is set: an app past its limit gets one notice a day, only
 * inside a window the rules leave open (outside quiet hours and meal
 * times) and only while the day has room under the daily limit. The rules
 * and every word come from the app (`limitRules` in Dart); nothing is
 * decided here beyond following them.
 */
class AppLimitCheck(context: Context, params: WorkerParameters) : Worker(context, params) {
    companion object {
        private const val PREFS = "navmaas_app_limits"
        private const val WORK = "app-limits"
        private const val CHANNEL = "reminders"

        fun setRules(context: Context, rules: String, limits: Int) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString("rules", rules).apply()
            val work = WorkManager.getInstance(context)
            if (limits > 0) {
                work.enqueueUniquePeriodicWork(
                    WORK,
                    ExistingPeriodicWorkPolicy.KEEP,
                    PeriodicWorkRequestBuilder<AppLimitCheck>(15, TimeUnit.MINUTES).build(),
                )
            } else {
                work.cancelUniqueWork(WORK)
            }
        }
    }

    override fun doWork(): Result {
        val context = applicationContext
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val rules = prefs.getString("rules", null)?.let { runCatching { JSONObject(it) }.getOrNull() }
            ?: return Result.success()
        if (!AppUsage.hasAccess(context) || !NotificationManagerCompat.from(context).areNotificationsEnabled()) {
            return Result.success()
        }
        val now = System.currentTimeMillis()
        val today = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(Date(now))
        val day = rules.getJSONArray("days").objects().firstOrNull { it.getString("date") == today }
            ?: return Result.success()
        val open = day.getJSONArray("open").let { w ->
            (0 until w.length()).any { w.getJSONArray(it).getLong(0) <= now && now < w.getJSONArray(it).getLong(1) }
        }
        if (!open) return Result.success() // It waits for the window to end.

        val sent = prefs.getString("sent", null)?.let { JSONObject(it) }
            ?.takeIf { it.getString("date") == today }
            ?.getJSONArray("packages")?.let { a -> (0 until a.length()).map { a.getString(it) } }
            ?.toMutableSet() ?: mutableSetOf()
        var room = day.getInt("room") - sent.size
        if (room <= 0) return Result.success()

        val limits = rules.getJSONArray("limits").objects().filter { it.getString("package") !in sent }
        val minutes = AppUsage.minutesToday(context, limits.map { it.getString("package") })
        for (limit in limits) {
            val pkg = limit.getString("package")
            if (room <= 0 || (minutes[pkg] ?: 0) < limit.getInt("minutes")) continue
            notify(context, rules, limit)
            sent += pkg
            room--
        }
        prefs.edit().putString("sent", JSONObject().put("date", today).put("packages", JSONArray(sent.toList())).toString()).apply()
        return Result.success()
    }

    private fun notify(context: Context, rules: JSONObject, limit: JSONObject) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = context.getSystemService(NotificationManager::class.java)
            if (manager.getNotificationChannel(CHANNEL) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(CHANNEL, rules.getString("channel"), NotificationManager.IMPORTANCE_DEFAULT)
                        .apply { description = rules.getString("channelDescription") },
                )
            }
        }
        val open = PendingIntent.getActivity(
            context,
            1,
            Intent(Intent.ACTION_VIEW, Uri.parse("navmaas://open/screen-rest"), context, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val notice = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(limit.getString("title"))
            .setContentText(limit.getString("body"))
            .setStyle(NotificationCompat.BigTextStyle().bigText(limit.getString("body")))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        try {
            NotificationManagerCompat.from(context).notify("app-limit:${limit.getString("package")}", 0, notice)
        } catch (_: SecurityException) {
            // Notifications not allowed: nothing to show.
        }
    }

    private fun JSONArray.objects() = (0 until length()).map { getJSONObject(it) }
}
