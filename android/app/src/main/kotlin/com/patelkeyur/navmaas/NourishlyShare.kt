package com.patelkeyur.navmaas

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * Reads Nourishly's share file (M8b, ADR 061) from its read-only provider.
 * Only apps holding com.patelkeyur.permission.NOURISHLY_SHARE get in, a
 * signature permission: both apps are signed with the owner's key (ADR 060).
 * Nourishly not installed, sharing off, or no permission: null.
 */
object NourishlyShare {
    private val uri = Uri.parse("content://com.nourishly.app.nourishly.share/navmaas")
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun register(context: Context, messenger: BinaryMessenger) {
        MethodChannel(messenger, "navmaas/nourishly").setMethodCallHandler { call, result ->
            if (call.method != "readShare") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            io.execute {
                // FileNotFoundException (no provider, no file) and
                // SecurityException (no permission) both mean "not shared".
                val text = try {
                    context.contentResolver.openInputStream(uri)
                        ?.bufferedReader()
                        ?.use { it.readText() }
                } catch (e: Exception) {
                    null
                }
                main.post { result.success(text) }
            }
        }
    }
}
