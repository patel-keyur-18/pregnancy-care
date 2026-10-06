package com.patelkeyur.navmaas

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.Calendar

/**
 * App limits (ARCHITECTURE §10, ADR 050): Usage access, the apps she can
 * choose, today's minutes, and handing the check its rules. The Dart side
 * is `lib/core/platform/app_usage.dart`.
 */
object AppUsage {
    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "navmaas/usage").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasAccess" -> result.success(hasAccess(context))
                "openAccessSettings" -> {
                    context.startActivity(
                        Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
                            .setData(Uri.parse("package:${context.packageName}"))
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(null)
                }
                "apps" -> Thread { // Icons take a moment; keep the UI thread free.
                    val apps = apps(context)
                    android.os.Handler(context.mainLooper).post { result.success(apps) }
                }.start()
                "minutesToday" -> result.success(
                    if (hasAccess(context)) minutesToday(context, call.argument<List<String>>("packages")!!)
                    else emptyMap<String, Int>(),
                )
                "setRules" -> {
                    AppLimitCheck.setRules(context, call.argument<String>("rules")!!, call.argument<Int>("limits")!!)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    fun hasAccess(context: Context): Boolean {
        val ops = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ops.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        } else {
            @Suppress("DEPRECATION")
            ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /** Launcher apps other than Navmaas: package, name and a 96 px icon. */
    private fun apps(context: Context): List<Map<String, Any>> {
        val pm = context.packageManager
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        return pm.queryIntentActivities(launcher, 0)
            .map { it.activityInfo.applicationInfo }
            .distinctBy { it.packageName }
            .filter { it.packageName != context.packageName }
            .map { info ->
                val icon = runCatching {
                    val drawable = pm.getApplicationIcon(info)
                    val bitmap = Bitmap.createBitmap(96, 96, Bitmap.Config.ARGB_8888)
                    drawable.setBounds(0, 0, 96, 96)
                    drawable.draw(Canvas(bitmap))
                    ByteArrayOutputStream().also { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }.toByteArray()
                }.getOrNull()
                buildMap {
                    put("package", info.packageName)
                    put("label", pm.getApplicationLabel(info).toString())
                    if (icon != null) put("icon", icon)
                }
            }
            .sortedBy { (it["label"] as String).lowercase() }
    }

    /** Minutes each package has been in the foreground since midnight. */
    fun minutesToday(context: Context, packages: List<String>): Map<String, Int> {
        val usage = context.getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val midnight = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0); set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        val now = System.currentTimeMillis()
        val wanted = packages.toSet()
        val started = mutableMapOf<String, Long>()
        val total = mutableMapOf<String, Long>()
        val events = usage.queryEvents(midnight, now)
        val e = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(e)
            if (e.packageName !in wanted) continue
            @Suppress("DEPRECATION")
            when (e.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> started.putIfAbsent(e.packageName, e.timeStamp)
                UsageEvents.Event.MOVE_TO_BACKGROUND -> {
                    // On screen at midnight: counted from midnight.
                    val from = started.remove(e.packageName) ?: midnight
                    total[e.packageName] = (total[e.packageName] ?: 0L) + (e.timeStamp - from)
                }
            }
        }
        for ((pkg, from) in started) total[pkg] = (total[pkg] ?: 0L) + (now - from)
        return packages.associateWith { ((total[it] ?: 0L) / 60_000L).toInt() }
    }
}
