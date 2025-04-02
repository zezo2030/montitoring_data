package com.example.v2

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DataLimitChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val PREFS_NAME = "DataLimitPrefs"
        private const val KEY_DAILY_LIMIT = "daily_limit"
        private const val KEY_ALERT_ENABLED = "alert_enabled"
        private const val CHANNEL_ID = "DATA_LIMIT_ALERTS"
        private const val DEFAULT_DAILY_LIMIT = 0.0 // بدون حد افتراضي
    }

    private val prefs: SharedPreferences =
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    init {
        createNotificationChannel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setDailyLimit" -> {
                val limitMB = call.argument<Double>("limitMB") ?: DEFAULT_DAILY_LIMIT
                setDailyLimit(limitMB)
                result.success(true)
            }
            "getDailyLimit" -> {
                result.success(getDailyLimit())
            }
            "setLimitAlertEnabled" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                setLimitAlertEnabled(enabled)
                result.success(true)
            }
            "isLimitAlertEnabled" -> {
                result.success(isLimitAlertEnabled())
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // تعيين الحد اليومي لاستهلاك البيانات بالميجابايت
    private fun setDailyLimit(limitMB: Double) {
        prefs.edit().putFloat(KEY_DAILY_LIMIT, limitMB.toFloat()).apply()
    }

    // الحصول على الحد اليومي الحالي بالميجابايت
    fun getDailyLimit(): Double {
        return prefs.getFloat(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT.toFloat()).toDouble()
    }

    // تفعيل/إلغاء تفعيل التنبيهات عند الوصول للحد
    private fun setLimitAlertEnabled(enabled: Boolean) {
        prefs.edit().putBoolean(KEY_ALERT_ENABLED, enabled).apply()
    }

    // التحقق مما إذا كانت التنبيهات مفعلة
    private fun isLimitAlertEnabled(): Boolean {
        return prefs.getBoolean(KEY_ALERT_ENABLED, true) // مفعلة افتراضيًا
    }

    // التحقق من تجاوز الحد اليومي
    fun checkIfLimitExceeded(currentUsageMB: Double): Boolean {
        val limit = getDailyLimit()
        if (limit <= 0) {
            return false // لا يوجد حد محدد
        }

        return currentUsageMB >= limit
    }

    // إرسال إشعار عند تجاوز الحد
    fun sendLimitExceededNotification() {
        if (!isLimitAlertEnabled()) {
            return
        }

        val notificationId = 2
        val title = "Data Usage Limit Exceeded"
        val text = "You have exceeded your daily data usage limit"

        val intent =
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
                }

        val pendingIntent =
                PendingIntent.getActivity(
                        context,
                        0,
                        intent,
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
                                PendingIntent.FLAG_IMMUTABLE
                        else 0
                )

        val builder =
                NotificationCompat.Builder(context, CHANNEL_ID)
                        .setSmallIcon(android.R.drawable.ic_dialog_alert)
                        .setContentTitle(title)
                        .setContentText(text)
                        .setPriority(NotificationCompat.PRIORITY_HIGH)
                        .setContentIntent(pendingIntent)
                        .setAutoCancel(true)

        val notificationManager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())
    }

    // إنشاء قناة الإشعارات
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Data Usage Limit Alerts"
            val descriptionText = "Notifications when exceeding daily data usage limit"
            val importance = NotificationManager.IMPORTANCE_HIGH

            val channel =
                    NotificationChannel(CHANNEL_ID, name, importance).apply {
                        description = descriptionText
                    }

            val notificationManager =
                    context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
