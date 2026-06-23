package com.example.feeddetoxer.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.work.*
import com.example.feeddetoxer.worker.BrainWatchdogWorker
import java.util.concurrent.TimeUnit

class BrainService : Service() {

    companion object {
        private const val TAG = "BrainService"
        private const val POLL_INTERVAL_MS = 1_000L
        private const val DEBOUNCE_MS = 3_000L
        private const val NOTIF_CHANNEL_ID = "brain_service_channel"
        private const val NOTIF_ID = 101
        const val PREFS_NAME = "feeddetoxer_prefs"
        const val PREFS_TARGET_APPS = "target_apps"

        @Volatile
        var isRunning = false
    }

    // --- Session state machine ---
    private enum class State { IDLE, DEBOUNCE, ACTIVE }

    private var state = State.IDLE
    private var activePackage: String? = null
    private var debounceStartMs = 0L
    private var sessionStartMs = 0L
    private var lastThresholdMinute = 0

    // --- UsageStats foreground tracking ---
    private lateinit var usageStatsManager: UsageStatsManager
    private var currentForeground: String? = null
    private var initialized = false

    // --- Target apps (written by Flutter via SharedPreferences) ---
    private var targetApps: Set<String> = emptySet()

    private val handler = Handler(Looper.getMainLooper())
    private val pollRunnable = object : Runnable {
        override fun run() {
            tick()
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    // -------------------------------------------------------------------
    // Lifecycle
    // -------------------------------------------------------------------

    override fun onCreate() {
        super.onCreate()
        usageStatsManager = getSystemService(USAGE_STATS_SERVICE) as UsageStatsManager
        createNotificationChannel()
        loadTargetApps()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIF_ID, buildNotification())
        if (!isRunning) {
            isRunning = true
            handler.post(pollRunnable)
            scheduleWatchdog()
            Log.i(TAG, "Brain started. Watching: $targetApps")
        }
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        handler.removeCallbacks(pollRunnable)
        Log.i(TAG, "Brain destroyed.")
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // -------------------------------------------------------------------
    // Target apps
    // -------------------------------------------------------------------

    fun reloadTargetApps() {
        loadTargetApps()
        Log.i(TAG, "Target apps reloaded: $targetApps")
    }

    private fun loadTargetApps() {
        val prefs = getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        targetApps = prefs.getStringSet(PREFS_TARGET_APPS, emptySet()) ?: emptySet()
    }

    // -------------------------------------------------------------------
    // Polling loop
    // -------------------------------------------------------------------

    private fun tick() {
        val foreground = getForegroundPackage()
        val isTarget = foreground != null && foreground in targetApps
        val now = System.currentTimeMillis()

        when (state) {
            State.IDLE -> {
                if (isTarget) {
                    state = State.DEBOUNCE
                    debounceStartMs = now
                    activePackage = foreground
                    Log.d(TAG, "DEBOUNCE started: $foreground")
                }
            }

            State.DEBOUNCE -> {
                if (foreground != activePackage) {
                    // Sub-3s flicker — ignore
                    Log.d(TAG, "DEBOUNCE cancelled (flicker): $foreground")
                    state = State.IDLE
                    activePackage = null
                } else if (now - debounceStartMs >= DEBOUNCE_MS) {
                    // Confirmed real session
                    state = State.ACTIVE
                    sessionStartMs = debounceStartMs
                    lastThresholdMinute = 0
                    emit("sessionStarted", mapOf("packageName" to foreground!!))
                    Log.i(TAG, "SESSION STARTED: $foreground")
                }
            }

            State.ACTIVE -> {
                if (foreground != activePackage) {
                    // Session ended
                    val durationSec = ((now - sessionStartMs) / 1_000).toInt()
                    emit(
                        "sessionEnded", mapOf(
                            "packageName" to (activePackage ?: ""),
                            "durationSec" to durationSec,
                            "outcome" to "completed"
                        )
                    )
                    Log.i(TAG, "SESSION ENDED: ${activePackage} — ${durationSec}s")
                    state = State.IDLE
                    activePackage = null
                } else {
                    // Still in session — emit per-minute threshold events
                    val elapsedMin = ((now - sessionStartMs) / 60_000).toInt()
                    if (elapsedMin > lastThresholdMinute) {
                        lastThresholdMinute = elapsedMin
                        emit(
                            "thresholdCrossed", mapOf(
                                "packageName" to foreground!!,
                                "elapsedMinutes" to elapsedMin
                            )
                        )
                        Log.i(TAG, "THRESHOLD CROSSED: $foreground at ${elapsedMin}min")
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------
    // Foreground package detection via UsageEvents
    // -------------------------------------------------------------------

    private fun getForegroundPackage(): String? {
        val now = System.currentTimeMillis()
        // On first call use a wider window to establish state; then keep tight.
        val lookbackMs = if (!initialized) { initialized = true; 5 * 60_000L } else 3_000L
        val events = usageStatsManager.queryEvents(now - lookbackMs, now)
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            @Suppress("DEPRECATION")
            when (event.eventType) {
                UsageEvents.Event.MOVE_TO_FOREGROUND -> currentForeground = event.packageName
                UsageEvents.Event.MOVE_TO_BACKGROUND ->
                    if (event.packageName == currentForeground) currentForeground = null
            }
        }
        return currentForeground
    }

    // -------------------------------------------------------------------
    // Event emission
    // -------------------------------------------------------------------

    private fun emit(type: String, data: Map<String, Any>) {
        val event = data.toMutableMap()
        event["type"] = type
        BrainEventBus.emit(event)
    }

    // -------------------------------------------------------------------
    // Notification (required for foreground service)
    // -------------------------------------------------------------------

    private fun createNotificationChannel() {
        val channel = NotificationChannel(
            NOTIF_CHANNEL_ID,
            "Screen Time Monitor",
            NotificationManager.IMPORTANCE_LOW
        ).apply { description = "Feed Detoxer is watching your screen time" }
        (getSystemService(NotificationManager::class.java))
            .createNotificationChannel(channel)
    }

    private fun buildNotification(): Notification =
        NotificationCompat.Builder(this, NOTIF_CHANNEL_ID)
            .setContentTitle("Feed Detoxer")
            .setContentText("Watching your screen time…")
            .setSmallIcon(android.R.drawable.ic_menu_recent_history)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()

    // -------------------------------------------------------------------
    // WorkManager watchdog schedule
    // -------------------------------------------------------------------

    private fun scheduleWatchdog() {
        val request = PeriodicWorkRequestBuilder<BrainWatchdogWorker>(15, TimeUnit.MINUTES)
            .setConstraints(Constraints.Builder().build())
            .build()
        WorkManager.getInstance(this).enqueueUniquePeriodicWork(
            "brain_watchdog",
            ExistingPeriodicWorkPolicy.KEEP,
            request
        )
    }
}
