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
        Log.d(TAG, "تم إنشاء خدمة المراقبة")
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "تم بدء خدمة المراقبة")

        if (!isMonitoring) {
            acquireWakeLock()
            startMonitoring()
            isServiceRunning = true
        }

        // إعادة بدء الخدمة إذا تم إيقافها
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "مراقبة استخدام البيانات"
            val descriptionText = "مراقبة استخدام البيانات في الخلفية"
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
            // إنشاء قصد يفتح النشاط الرئيسي عند النقر على الإشعار
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
                            .setContentTitle("مراقبة استخدام البيانات")
                            .setContentText("جاري مراقبة استخدام البيانات...")
                            .setSmallIcon(android.R.drawable.ic_menu_info_details)
                            .setPriority(NotificationCompat.PRIORITY_LOW)
                            .setContentIntent(pendingIntent)
                            .setOngoing(true)
                            .build()

            startForeground(NOTIFICATION_ID, notification)
            Log.d(TAG, "تم بدء الخدمة الأمامية بنجاح")
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في بدء الخدمة الأمامية: ${e.message}")
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
                                acquire(60 * 60 * 1000L) // ساعة كاملة
                            }
            Log.d(TAG, "تم الحصول على قفل الاستيقاظ")
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في الحصول على قفل الاستيقاظ: ${e.message}")
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
                                        // تحديث البيانات والإشعار كل 15 ثانية
                                        updateDataAndNotification()
                                    } catch (e: Exception) {
                                        Log.e(TAG, "خطأ في تحديث البيانات: ${e.message}")
                                    }
                                }
                            },
                            0,
                            15 * 1000 // كل 15 ثانية
                    )
                }
        Log.d(TAG, "بدأت المراقبة بنجاح")
    }

    private fun updateDataAndNotification() {
        try {
            // تجنب التحديثات المتكررة جداً
            val currentTime = System.currentTimeMillis()
            if (currentTime - lastUpdateTime < 5000) { // 5 ثواني
                return
            }

            lastUpdateTime = currentTime

            // تحديث البيانات
            updateData()

            // تحديث الإشعار
            updateNotification()
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في تحديث البيانات والإشعار: ${e.message}")
        }
    }

    private fun updateData() {
        try {
            // تحديث بيانات الاستخدام من خلال DataUsageCalculator
            DataUsageCalculator.getCurrentDataUsage(this)
            DataUsageCalculator.getTodayDataUsage(this)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في تحديث البيانات: ${e.message}")
        }
    }

    private fun updateNotification() {
        try {
            val currentUsage = DataUsageCalculator.lastCurrentDataUsage
            val todayUsage = DataUsageCalculator.lastTodayDataUsage

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
                            .setContentTitle("استخدام البيانات")
                            .setContentText(
                                    "اليوم: ${String.format("%.2f", todayUsage)} ميجابايت | آخر 5 دقائق: ${String.format("%.2f", currentUsage)} ميجابايت"
                            )
                            .setSmallIcon(android.R.drawable.ic_menu_info_details)
                            .setPriority(NotificationCompat.PRIORITY_LOW)
                            .setContentIntent(pendingIntent)
                            .setOngoing(true)
                            .build()

            val notificationManager =
                    getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في تحديث الإشعار: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "تم إيقاف خدمة المراقبة")
        stopMonitoring()
        releaseWakeLock()
        isServiceRunning = false

        // إعادة تشغيل الخدمة عند إغلاقها
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
                Log.d(TAG, "تم إطلاق قفل الاستيقاظ")
            }
            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في إطلاق قفل الاستيقاظ: ${e.message}")
        }
    }
}
