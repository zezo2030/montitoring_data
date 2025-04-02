package com.example.v2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.Timer
import java.util.TimerTask

class DataMonitorService : Service() {
    private val TAG = "DataMonitorService"
    private val CHANNEL_ID = "DataMonitorChannel"
    private val NOTIFICATION_ID = 1
    private var wakeLock: PowerManager.WakeLock? = null
    private var timer: Timer? = null
    private var isMonitoring = false
    private var lastUpdateTime = 0L

    companion object {
        var isServiceRunning = false
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Monitor service created")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Monitor service started")

        if (!isMonitoring) {
            acquireWakeLock()
            startMonitoring()
            isServiceRunning = true
        }

        // Restart service if killed
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Data Usage Monitor"
            val descriptionText = "Monitors data usage in background"
            val importance = NotificationManager.IMPORTANCE_LOW
            val channel =
                    NotificationChannel(CHANNEL_ID, name, importance).apply {
                        description = descriptionText
                        setShowBadge(false)
                    }
            val notificationManager: NotificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun startForeground() {
        try {
            // Create intent that opens main activity when clicked
            val pendingIntent: PendingIntent =
                    Intent(this, MainActivity::class.java).let { notificationIntent ->
                        notificationIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        val flags =
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                    PendingIntent.FLAG_IMMUTABLE or
                                            PendingIntent.FLAG_UPDATE_CURRENT
                                } else {
                                    PendingIntent.FLAG_UPDATE_CURRENT
                                }
                        PendingIntent.getActivity(this, 0, notificationIntent, flags)
                    }

            val notification =
                    NotificationCompat.Builder(this, CHANNEL_ID)
                            .setContentTitle("Data Usage Monitor")
                            .setContentText("Monitoring data usage...")
                            .setSmallIcon(android.R.drawable.ic_menu_info_details)
                            .setPriority(NotificationCompat.PRIORITY_LOW)
                            .setContentIntent(pendingIntent)
                            .setOngoing(true)
                            .build()

            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "Foreground service started successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Error starting foreground service: ${e.message}")
        }
    }

    private fun acquireWakeLock() {
        try {
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock =
                    powerManager.newWakeLock(
                                    PowerManager.PARTIAL_WAKE_LOCK,
                                    "DataMonitorService::WakeLock"
                            )
                            .apply {
                                acquire(60 * 60 * 1000L) // 1 hour
                            }
            Log.d(TAG, "WakeLock acquired")
        } catch (e: Exception) {
            Log.e(TAG, "Error acquiring WakeLock: ${e.message}")
        }
    }

    private fun startMonitoring() {
        if (isMonitoring) return

        isMonitoring = true
        startForeground()

        timer =
                Timer().apply {
                    scheduleAtFixedRate(
                            object : TimerTask() {
                                override fun run() {
                                    try {
                                        // Update data and notification every 15 seconds
                                        updateDataAndNotification()
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Error updating data: ${e.message}")
                                    }
                                }
                            },
                            0,
                            15 * 1000 // every 15 seconds
                    )
                }
        Log.d(TAG, "Monitoring started successfully")
    }

    private fun updateDataAndNotification() {
        try {
            // Avoid too frequent updates
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastUpdateTime < 5000) { // 5 seconds
                return
            }

            lastUpdateTime = currentTime

            // Update data
            updateData()

            // Update notification
            updateNotification()
        } catch (e: Exception) {
            Log.e(TAG, "Error updating data and notification: ${e.message}")
        }
    }

    private fun updateData() {
        try {
            // Update usage data through DataUsageCalculator
            DataUsageCalculator.getCurrentDataUsage(this)
            DataUsageCalculator.getTodayDataUsage(this)
        } catch (e: Exception) {
            Log.e(TAG, "Error updating data: ${e.message}")
        }
    }

    private fun updateNotification() {
        try {
            val currentUsage = DataUsageCalculator.lastCurrentDataUsage
            val todayUsage = DataUsageCalculator.lastTodayDataUsage

            // Get daily limit from DataLimitChannel
            val dataLimitChannel = DataLimitChannel(this)
            val dailyLimit = dataLimitChannel.getDailyLimit()

            // Calculate percentage
            val usagePercentage =
                    if (dailyLimit > 0) {
                        (todayUsage / dailyLimit * 100).toInt().coerceAtMost(100)
                    } else {
                        0
                    }

            // Format usage values with appropriate units (MB or GB)
            val todayUsageFormatted: String
            val todayUsageUnit: String
            if (todayUsage > 1024) {
                // Convert to GB if > 1024 MB
                todayUsageFormatted = String.format("%.2f", todayUsage / 1024)
                todayUsageUnit = "GB"
            } else {
                todayUsageFormatted = String.format("%.2f", todayUsage)
                todayUsageUnit = "MB"
            }

            val currentUsageFormatted: String
            val currentUsageUnit: String
            if (currentUsage > 1024) {
                currentUsageFormatted = String.format("%.2f", currentUsage / 1024)
                currentUsageUnit = "GB"
            } else {
                currentUsageFormatted = String.format("%.2f", currentUsage)
                currentUsageUnit = "MB"
            }

            val limitFormatted: String
            val limitUnit: String
            if (dailyLimit > 1024) {
                limitFormatted = String.format("%.2f", dailyLimit / 1024)
                limitUnit = "GB"
            } else {
                limitFormatted = String.format("%.2f", dailyLimit)
                limitUnit = "MB"
            }

            // Create notification content based on limit in English
            val contentText =
                    if (dailyLimit > 0) {
                        "Today: $todayUsageFormatted $todayUsageUnit | ${usagePercentage}% of limit ($limitFormatted $limitUnit)"
                    } else {
                        "Today: $todayUsageFormatted $todayUsageUnit | Last 3 hours: $currentUsageFormatted $currentUsageUnit"
                    }

            val pendingIntent: PendingIntent =
                    Intent(this, MainActivity::class.java).let { notificationIntent ->
                        notificationIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                        val flags =
                                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                    PendingIntent.FLAG_IMMUTABLE or
                                            PendingIntent.FLAG_UPDATE_CURRENT
                                } else {
                                    PendingIntent.FLAG_UPDATE_CURRENT
                                }
                        PendingIntent.getActivity(this, 0, notificationIntent, flags)
                    }

            // Create the notification builder
            val builder =
                    NotificationCompat.Builder(this, CHANNEL_ID)
                            .setContentTitle("Data Usage")
                            .setContentText(contentText)
                            .setSmallIcon(android.R.drawable.ic_menu_info_details)
                            .setPriority(NotificationCompat.PRIORITY_LOW)
                            .setContentIntent(pendingIntent)
                            .setOngoing(true)

            // Add progress bar if limit is set
            if (dailyLimit > 0) {
                builder.setProgress(100, usagePercentage, false)
            }

            // Send the notification
            val notificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, builder.build())
        } catch (e: Exception) {
            Log.e(TAG, "Error updating notification: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Monitor service stopped")
        stopMonitoring()
        releaseWakeLock()
        isServiceRunning = false

        // Restart service when killed
        val restartServiceIntent = Intent(applicationContext, DataMonitorService::class.java)
        applicationContext.startService(restartServiceIntent)
    }

    private fun stopMonitoring() {
        isMonitoring = false
        timer?.cancel()
        timer = null
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
                Log.d(TAG, "WakeLock released")
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "Error releasing WakeLock: ${e.message}")
        }
    }
}
