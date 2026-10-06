package com.patelkeyur.navmaas

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

// Background audio (audio_service) needs its activity; the fragment variant
// is what Health Connect (M4b) and app lock (M10b) need too.
class MainActivity : AudioServiceFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // App limits (M11a).
        AppUsage.register(applicationContext, flutterEngine.dartExecutor.binaryMessenger)
    }
}
