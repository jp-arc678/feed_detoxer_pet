package com.example.feeddetoxer // ดูให้ตรงกับ package ของคุณนะครับ

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.feeddetoxer/grayscale"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setSystemGrayscale") {
                val enabled = call.argument<Boolean>("enabled") ?: false
                val success = toggleGrayscale(enabled)
                if (success) {
                    result.success(true)
                } else {
                    result.error("PERMISSION_DENIED", "ต้องขอสิทธิ์ Secure Settings ก่อน", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    // ฟังก์ชันสั่งการระดับระบบของ Android เพื่อเปลี่ยนจอเป็นขาวดำ
    private fun toggleGrayscale(enable: Boolean): Boolean {
        return try {
            val contentResolver = context.contentResolver
            if (enable) {
                // 1 = เปิดโหมดปรับแก้สี, 0 = ปิดโหมดแก้สี (Grayscale ของ Android คือเบอร์ 0)
                Settings.Secure.putInt(contentResolver, "accessibility_display_daltonizer_enabled", 1)
                Settings.Secure.putInt(contentResolver, "accessibility_display_daltonizer", 0)
            } else {
                Settings.Secure.putInt(contentResolver, "accessibility_display_daltonizer_enabled", 0)
            }
            true
        } catch (e: Exception) {
            false
        }
    }
}