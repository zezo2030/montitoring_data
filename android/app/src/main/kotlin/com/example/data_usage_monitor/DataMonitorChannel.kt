package com.example.data_usage_monitor

import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build
import android.telephony.TelephonyManager
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.*
import android.app.usage.NetworkStats
import android.content.Intent
import android.os.RemoteException
import android.provider.Settings
import android.telephony.SubscriptionManager
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import java.time.LocalDateTime
import java.time.ZoneId

@RequiresApi(Build.VERSION_CODES.M)
class DataMonitorChannel(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val CHANNEL_ID = "DATA_USAGE_ALERTS"
    }

    private var isMonitoring = false
    private var monitorThread: Thread? = null

    init {
        createNotificationChannel()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getCurrentDataUsage" -> {
                try {
                    result.success(getCurrentDataUsage())
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "getTodayDataUsage" -> {
                try {
                    result.success(getTodayDataUsage())
                } catch (e: Exception) {
                    result.error("ERROR", e.message, null)
                }
            }
            "startMonitoring" -> {
                startMonitoring()
                result.success(true)
            }
            "stopMonitoring" -> {
                stopMonitoring()
                result.success(true)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // الحصول على استهلاك البيانات الحالي بالميجابايت
    private fun getCurrentDataUsage(): Double {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
            val subscriptionId = getSubscriptionId()
            
            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis
            calendar.add(Calendar.MINUTE, -5) // آخر 5 دقائق
            val startTime = calendar.timeInMillis
            
            try {
                val networkStats = networkStatsManager.querySummary(
                    ConnectivityManager.TYPE_MOBILE,
                    getSubscriberId(subscriptionId),
                    startTime,
                    endTime
                )
                
                var totalBytes = 0L
                val bucket = NetworkStats.Bucket()
                while (networkStats.hasNextBucket()) {
                    networkStats.getNextBucket(bucket)
                    totalBytes += bucket.rxBytes + bucket.txBytes
                }
                networkStats.close()
                
                return totalBytes.toDouble() / (1024 * 1024) // تحويل إلى ميجابايت
            } catch (e: RemoteException) {
                e.printStackTrace()
            }
        }
        return 0.0
    }

    // الحصول على استهلاك البيانات لليوم الحالي بالميجابايت
    private fun getTodayDataUsage(): Double {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val networkStatsManager = context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
            val subscriptionId = getSubscriptionId()
            
            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis
            
            // إعادة تعيين الوقت إلى بداية اليوم
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis
            
            try {
                val networkStats = networkStatsManager.querySummary(
                    ConnectivityManager.TYPE_MOBILE,
                    getSubscriberId(subscriptionId),
                    startTime,
                    endTime
                )
                
                var totalBytes = 0L
                val bucket = NetworkStats.Bucket()
                while (networkStats.hasNextBucket()) {
                    networkStats.getNextBucket(bucket)
                    totalBytes += bucket.rxBytes + bucket.txBytes
                }
                networkStats.close()
                
                return totalBytes.toDouble() / (1024 * 1024) // تحويل إلى ميجابايت
            } catch (e: RemoteException) {
                e.printStackTrace()
            }
        }
        return 0.0
    }

    // بدء مراقبة البيانات في الخلفية
    private fun startMonitoring() {
        if (isMonitoring) {
            return
        }
        
        isMonitoring = true
        monitorThread = Thread {
            try {
                while (isMonitoring) {
                    // التحقق من استهلاك البيانات كل 5 دقائق
                    Thread.sleep(5 * 60 * 1000)
                    
                    // يمكننا هنا إضافة منطق إرسال التنبيهات إذا تجاوز الاستهلاك الحد
                    // على سبيل المثال، نقارن مع الحد اليومي المحدد
                }
            } catch (e: InterruptedException) {
                // تم إيقاف المراقبة
            }
        }
        monitorThread?.start()
    }

    // إيقاف مراقبة البيانات
    private fun stopMonitoring() {
        isMonitoring = false
        monitorThread?.interrupt()
        monitorThread = null
    }

    // الحصول على رقم الاشتراك لشريحة SIM
    private fun getSubscriptionId(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val subscriptionManager = context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
            val activeSubscriptions = subscriptionManager.activeSubscriptionInfoList ?: return -1
            
            if (activeSubscriptions.isNotEmpty()) {
                return activeSubscriptions[0].subscriptionId
            }
        }
        return -1
    }

    // الحصول على معرف المشترك لشريحة SIM
    private fun getSubscriberId(subscriptionId: Int): String? {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                return telephonyManager.createForSubscriptionId(subscriptionId).subscriberId
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        return telephonyManager.subscriberId
    }

    // إنشاء قناة الإشعارات
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "تنبيهات استهلاك البيانات"
            val descriptionText = "إشعارات حول استهلاك بيانات الإنترنت"
            val importance = NotificationManager.IMPORTANCE_DEFAULT
            val channel = NotificationChannel(CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }
            
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
} 