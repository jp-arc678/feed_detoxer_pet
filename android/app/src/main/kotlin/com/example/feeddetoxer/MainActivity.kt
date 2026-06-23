package com.example.feeddetoxer

import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import com.example.feeddetoxer.service.BrainEventBus
import com.example.feeddetoxer.service.BrainService

class MainActivity : FlutterActivity() {

    private val GRAYSCALE_CHANNEL = "com.example.feeddetoxer/grayscale"
    private val BRAIN_CONTROL_CHANNEL = "com.example.feeddetoxer/brain_control"
    private val BRAIN_EVENTS_CHANNEL = "com.example.feeddetoxer/brain_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // --- Grayscale channel (keep existing feature) ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, GRAYSCALE_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "setSystemGrayscale") {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (toggleGrayscale(enabled)) result.success(true)
                    else result.error("PERMISSION_DENIED", "Secure Settings permission required", null)
                } else {
                    result.notImplemented()
                }
            }

        // --- Brain control channel: Flutter → Brain ---
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BRAIN_CONTROL_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "start" -> {
                        startBrain()
                        result.success(null)
                    }
                    "stop" -> {
                        stopService(Intent(this, BrainService::class.java))
                        result.success(null)
                    }
                    "setTargetApps" -> {
                        val packages = call.argument<List<String>>("packages") ?: emptyList()
                        saveTargetApps(packages)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // --- Brain event channel: Brain → Flutter ---
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, BRAIN_EVENTS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    BrainEventBus.setSink(events)
                }
                override fun onCancel(arguments: Any?) {
                    BrainEventBus.setSink(null)
                }
            })
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    private fun startBrain() {
        val intent = Intent(this, BrainService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun saveTargetApps(packages: List<String>) {
        getSharedPreferences(BrainService.PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putStringSet(BrainService.PREFS_TARGET_APPS, packages.toSet())
            .apply()
    }

    private fun toggleGrayscale(enable: Boolean): Boolean {
        return try {
            val cr = context.contentResolver
            if (enable) {
                Settings.Secure.putInt(cr, "accessibility_display_daltonizer_enabled", 1)
                Settings.Secure.putInt(cr, "accessibility_display_daltonizer", 0)
            } else {
                Settings.Secure.putInt(cr, "accessibility_display_daltonizer_enabled", 0)
            }
            true
        } catch (e: Exception) {
            false
        }
    }
}
