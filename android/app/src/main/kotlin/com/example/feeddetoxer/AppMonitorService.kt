package com.example.feeddetoxer

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent
import android.util.Log
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class AppMonitorService : AccessibilityService() {

    private val TAG = "AppMonitorService"
    // ต้องตั้งชื่อช่องทางให้ตรงกับฝั่ง Flutter
    private val CHANNEL_NAME = "com.example.feeddetoxer/accessibility"
    private var methodChannel: MethodChannel? = null

    // เมื่อ Service ถูกเปิดขึ้นมา
    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d(TAG, "Accessibility Service is Connected!")

        val info = AccessibilityServiceInfo()
        // สนใจเฉพาะ Event ที่บอกว่า "หน้าต่างแอปเปลี่ยน"
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
        // ดักจับทุกแอป
        info.packageNames = null
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.notificationTimeout = 100
        
        this.serviceInfo = info

        // พยายามดึง FlutterEngine ที่กำลังรันอยู่เพื่อส่งข้อมูลกลับไป
        val flutterEngine = FlutterEngineCache.getInstance().get("detox_engine")
        if (flutterEngine != null) {
            methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        }
    }

    // ฟังก์ชันนี้จะถูกเรียกอัตโนมัติ ทุกครั้งที่ผู้ใช้เปิดแอปใหม่ขึ้นมาบนหน้าจอ
    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString()
            val className = event.className?.toString()

            if (packageName != null) {
                Log.d(TAG, "App Opened: $packageName")
                
                // ส่ง Package Name ของแอปที่เปิดกลับไปให้ฝั่ง Flutter เช็ค
                methodChannel?.invokeMethod("onAppOpened", packageName)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Accessibility Service is Interrupted!")
    }
}