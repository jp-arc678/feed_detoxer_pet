package com.example.feeddetoxer.service

import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel

// Singleton bridge: BrainService writes here; MainActivity wires the Flutter sink.
object BrainEventBus {
    @Volatile
    private var sink: EventChannel.EventSink? = null

    fun setSink(s: EventChannel.EventSink?) {
        sink = s
    }

    fun emit(event: Map<String, Any>) {
        Handler(Looper.getMainLooper()).post {
            sink?.success(event)
        }
    }
}
