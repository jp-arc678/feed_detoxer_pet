package com.example.feeddetoxer.worker

import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.work.Worker
import androidx.work.WorkerParameters
import com.example.feeddetoxer.service.BrainService

class BrainWatchdogWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {

    override fun doWork(): Result {
        if (!BrainService.isRunning) {
            Log.w("BrainWatchdog", "Brain not running — restarting.")
            val intent = Intent(applicationContext, BrainService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                applicationContext.startForegroundService(intent)
            } else {
                applicationContext.startService(intent)
            }
        }
        return Result.success()
    }
}
