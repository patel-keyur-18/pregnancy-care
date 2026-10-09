package com.patelkeyur.navmaas

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import android.view.WindowManager
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// Background audio (audio_service) needs its activity; the fragment variant
// is what Health Connect (M4b) and app lock (M10b) need too.
class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // App limits (M11a).
        AppUsage.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
        // Keeps the screen on while she records a voice letter (E3).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "navmaas/screen")
            .setMethodCallHandler { call, result ->
                val on = call.arguments as? Boolean
                if (call.method != "keepOn" || on == null) {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (on) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                }
                result.success(null)
            }
    }
}
