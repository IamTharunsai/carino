package com.example.carino

import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FragmentActivity is required by local_auth (biometric prompt).
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Vanish chats + view-once media: block screenshots/recording while
        // shown (lib/widgets/secure_screen.dart). Cleared when they close.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carino/secure")
            .setMethodCallHandler { call, result ->
                if (call.method == "setSecure") {
                    val on = call.arguments as? Boolean ?: false
                    if (on) {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    } else {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
        // Phone-Down Mode: is the screen on? Leaving the app with the screen
        // on = another app opened (check-in); screen off = phone down.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "carino/presence")
            .setMethodCallHandler { call, result ->
                if (call.method == "isInteractive") {
                    val pm = getSystemService(POWER_SERVICE) as PowerManager
                    result.success(pm.isInteractive)
                } else {
                    result.notImplemented()
                }
            }
    }
}
