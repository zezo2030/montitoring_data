package com.example.v2

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.os.RemoteException
import android.provider.Settings
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val TAG = "DataUsageMonitor"
    private val PERMISSIONS_CHANNEL = "com.example.v2/permissions"
    private val DATA_MONITOR_CHANNEL = "com.example.v2/data_monitor"
    private val DATA_LIMIT_CHANNEL = "com.example.v2/data_limit"
    private val DATA_STREAM_CHANNEL = "com.example.v2/data_stream"

    // معالج لإرسال تحديثات دورية
    private val handler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var streamRunning = false
    private val streamUpdateInterval = 5000L // تحديث كل 5 ثواني

    // مهمة التحديث الدوري
    private val updateRunnable =
            object : Runnable {
                override fun run() {
                    try {
                        if (streamRunning && eventSink != null) {
                            sendDataUpdate()
                            // جدولة التنفيذ التالي
                            handler.postDelayed(this, streamUpdateInterval)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "خطأ في مهمة التحديث: ${e.message}")
                    }
                }
            }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // بدء خدمة المراقبة إذا لم تكن تعمل بالفعل
        if (!DataMonitorService.isServiceRunning) {
            startDataMonitorService()
        }
    }

    override fun onResume() {
        super.onResume()

        // التحقق من حالة الخدمة والبدء مرة أخرى إذا كانت متوقفة
        if (!DataMonitorService.isServiceRunning) {
            startDataMonitorService()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopDataStream()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        try {
            // تهيئة قناة الأذونات
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
                    .setMethodCallHandler { call, result ->
                        try {
                            when (call.method) {
                                "checkUsageStatsPermission" -> {
                                    result.success(hasUsageStatsPermission())
                                }
                                "openUsageAccessSettings" -> {
                                    openUsageAccessSettings()
                                    result.success(true)
                                }
                                "isIgnoringBatteryOptimizations" -> {
                                    result.success(isIgnoringBatteryOptimizations())
                                }
                                "requestIgnoreBatteryOptimizations" -> {
                                    requestIgnoreBatteryOptimizations()
                                    result.success(true)
                                }
                                else -> {
                                    result.notImplemented()
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "خطأ في قناة الأذونات: ${e.message}")
                            result.error("ERROR", e.message, null)
                        }
                    }

            // تهيئة قناة مراقبة البيانات
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_MONITOR_CHANNEL)
                    .setMethodCallHandler { call, result ->
                        try {
                            when (call.method) {
                                "getCurrentDataUsage" -> {
                                    val currentUsage =
                                            DataUsageCalculator.getCurrentDataUsage(context)
                                    result.success(currentUsage)
                                }
                                "getTodayDataUsage" -> {
                                    val todayUsage = DataUsageCalculator.getTodayDataUsage(context)
                                    result.success(todayUsage)
                                }
                                "startMonitoring" -> {
                                    startDataMonitorService()
                                    result.success(true)
                                }
                                "stopMonitoring" -> {
                                    stopDataMonitorService()
                                    result.success(true)
                                }
                                "isMonitoringActive" -> {
                                    result.success(DataMonitorService.isServiceRunning)
                                }
                                else -> {
                                    result.notImplemented()
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "خطأ في قناة مراقبة البيانات: ${e.message}")
                            result.error("ERROR", e.message, null)
                        }
                    }

            // تهيئة قناة حدود البيانات
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_LIMIT_CHANNEL)
                    .setMethodCallHandler { call, result ->
                        try {
                            when (call.method) {
                                "setDailyLimit" -> {
                                    val limitMB = call.argument<Double>("limitMB") ?: 0.0
                                    setDailyLimit(limitMB)
                                    result.success(true)
                                }
                                "getDailyLimit" -> {
                                    val limit = getDailyLimit()
                                    result.success(limit)
                                }
                                "setLimitAlertEnabled" -> {
                                    val enabled = call.argument<Boolean>("enabled") ?: false
                                    setLimitAlertEnabled(enabled)
                                    result.success(true)
                                }
                                else -> {
                                    result.notImplemented()
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "خطأ في قناة حدود البيانات: ${e.message}")
                            result.error("ERROR", e.message, null)
                        }
                    }

            // تهيئة قناة تدفق البيانات المستمرة
            EventChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_STREAM_CHANNEL)
                    .setStreamHandler(
                            object : EventChannel.StreamHandler {
                                override fun onListen(
                                        arguments: Any?,
                                        events: EventChannel.EventSink?
                                ) {
                                    Log.d(TAG, "بدء الاستماع لتدفق البيانات")
                                    eventSink = events
                                    startDataStream()
                                }

                                override fun onCancel(arguments: Any?) {
                                    Log.d(TAG, "إيقاف الاستماع لتدفق البيانات")
                                    stopDataStream()
                                    eventSink = null
                                }
                            }
                    )
        } catch (e: Exception) {
            Log.e(TAG, "خطأ أثناء تهيئة القنوات: ${e.message}")
        }
    }

    // بدء تدفق البيانات المستمر
    private fun startDataStream() {
        if (streamRunning) return

        streamRunning = true
        handler.post(updateRunnable)
        Log.d(TAG, "تم بدء تدفق البيانات المستمر")
    }

    // إيقاف تدفق البيانات المستمر
    private fun stopDataStream() {
        streamRunning = false
        handler.removeCallbacks(updateRunnable)
        Log.d(TAG, "تم إيقاف تدفق البيانات المستمر")
    }

    // إرسال تحديث بيانات الاستخدام
    private fun sendDataUpdate() {
        try {
            // تحديث البيانات باستخدام DataUsageCalculator
            DataUsageCalculator.getCurrentDataUsage(context)
            DataUsageCalculator.getTodayDataUsage(context)

            // إنشاء كائن JSON يحتوي على البيانات المحدثة
            val dataJson =
                    JSONObject().apply {
                        put("currentUsage", DataUsageCalculator.lastCurrentDataUsage)
                        put("todayUsage", DataUsageCalculator.lastTodayDataUsage)
                        put("timestamp", DataUsageCalculator.lastTimestamp)
                        put("dailyLimit", getDailyLimit())
                    }

            // إرسال البيانات عبر القناة
            eventSink?.success(dataJson.toString())
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في إرسال تحديث البيانات: ${e.message}")
        }
    }

    private fun startDataMonitorService() {
        try {
            if (!isIgnoringBatteryOptimizations() && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
            ) {
                Log.d(TAG, "طلب تجاهل تحسينات البطارية")
                requestIgnoreBatteryOptimizations()
            }

            val serviceIntent = Intent(this, DataMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            Log.d(TAG, "تم بدء خدمة المراقبة")
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في بدء خدمة المراقبة: ${e.message}")
        }
    }

    private fun stopDataMonitorService() {
        try {
            val serviceIntent = Intent(this, DataMonitorService::class.java)
            stopService(serviceIntent)
            Log.d(TAG, "تم إيقاف خدمة المراقبة")
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في إيقاف خدمة المراقبة: ${e.message}")
        }
    }

    // الحصول على استخدام البيانات الحالي بالميجابايت (آخر 5 دقائق)
    private fun getCurrentDataUsage(): Double {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!hasUsageStatsPermission()) {
                throw SecurityException("لا يوجد إذن للوصول لإحصائيات الاستخدام")
            }

            val networkStatsManager =
                    context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis
            calendar.add(Calendar.MINUTE, -5) // آخر 5 دقائق
            val startTime = calendar.timeInMillis

            try {
                // جمع بيانات الواي فاي فقط
                val wifiStats =
                        networkStatsManager.querySummary(
                                ConnectivityManager.TYPE_WIFI,
                                null, // لا نحتاج لمعرف المشترك للواي فاي
                                startTime,
                                endTime
                        )

                var totalBytes = 0L
                val bucket = NetworkStats.Bucket()
                while (wifiStats.hasNextBucket()) {
                    wifiStats.getNextBucket(bucket)
                    totalBytes += bucket.rxBytes + bucket.txBytes
                }
                wifiStats.close()

                return totalBytes.toDouble() / (1024 * 1024) // تحويل إلى ميجابايت
            } catch (e: RemoteException) {
                Log.e(TAG, "خطأ في الحصول على استخدام البيانات الحالي: ${e.message}")
                throw e
            }
        } else {
            return 0.0 // للإصدارات القديمة
        }
    }

    // الحصول على استخدام البيانات لليوم الحالي بالميجابايت
    private fun getTodayDataUsage(): Double {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (!hasUsageStatsPermission()) {
                throw SecurityException("لا يوجد إذن للوصول لإحصائيات الاستخدام")
            }

            val networkStatsManager =
                    context.getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager

            val calendar = Calendar.getInstance()
            val endTime = calendar.timeInMillis

            // إعادة تعيين الوقت إلى بداية اليوم
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            val startTime = calendar.timeInMillis

            try {
                // جمع بيانات الواي فاي فقط
                val wifiStats =
                        networkStatsManager.querySummary(
                                ConnectivityManager.TYPE_WIFI,
                                null, // لا نحتاج لمعرف المشترك للواي فاي
                                startTime,
                                endTime
                        )

                var totalBytes = 0L
                val bucket = NetworkStats.Bucket()
                while (wifiStats.hasNextBucket()) {
                    wifiStats.getNextBucket(bucket)
                    totalBytes += bucket.rxBytes + bucket.txBytes
                }
                wifiStats.close()

                return totalBytes.toDouble() / (1024 * 1024) // تحويل إلى ميجابايت
            } catch (e: RemoteException) {
                Log.e(TAG, "خطأ في الحصول على استخدام البيانات اليومي: ${e.message}")
                throw e
            }
        } else {
            return 0.0 // للإصدارات القديمة
        }
    }

    // الحصول على رقم الاشتراك لشريحة SIM
    private fun getSubscriptionId(): Int {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val subscriptionManager =
                    context.getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as
                            SubscriptionManager
            val activeSubscriptions = subscriptionManager.activeSubscriptionInfoList ?: return -1

            if (activeSubscriptions.isNotEmpty()) {
                return activeSubscriptions[0].subscriptionId
            }
        }
        return -1
    }

    // الحصول على معرف المشترك لشريحة SIM
    private fun getSubscriberId(subscriptionId: Int): String? {
        val telephonyManager =
                context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                return telephonyManager.createForSubscriptionId(subscriptionId).subscriberId
            } catch (e: Exception) {
                Log.e(TAG, "خطأ في الحصول على معرف المشترك: ${e.message}")
            }
        }

        return telephonyManager.subscriberId
    }

    // تخزين ومعالجة الحد اليومي
    private val sharedPrefs by lazy {
        context.getSharedPreferences("DataLimitPrefs", Context.MODE_PRIVATE)
    }
    private val KEY_DAILY_LIMIT = "daily_limit"
    private val KEY_ALERT_ENABLED = "alert_enabled"
    private val DEFAULT_DAILY_LIMIT = 0.0

    // تعيين الحد اليومي بالميجابايت
    private fun setDailyLimit(limitMB: Double) {
        sharedPrefs.edit().putFloat(KEY_DAILY_LIMIT, limitMB.toFloat()).apply()
    }

    // الحصول على الحد اليومي بالميجابايت
    private fun getDailyLimit(): Double {
        return sharedPrefs.getFloat(KEY_DAILY_LIMIT, DEFAULT_DAILY_LIMIT.toFloat()).toDouble()
    }

    // تعيين تفعيل/تعطيل التنبيهات
    private fun setLimitAlertEnabled(enabled: Boolean) {
        sharedPrefs.edit().putBoolean(KEY_ALERT_ENABLED, enabled).apply()
    }

    // التحقق من وجود إذن الوصول إلى إحصائيات الاستخدام
    private fun hasUsageStatsPermission(): Boolean {
        try {
            val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
            val mode =
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        appOps.unsafeCheckOpNoThrow(
                                AppOpsManager.OPSTR_GET_USAGE_STATS,
                                Process.myUid(),
                                context.packageName
                        )
                    } else {
                        appOps.checkOpNoThrow(
                                AppOpsManager.OPSTR_GET_USAGE_STATS,
                                Process.myUid(),
                                context.packageName
                        )
                    }
            return mode == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في التحقق من إذن إحصائيات الاستخدام: ${e.message}")
            return false
        }
    }

    // فتح إعدادات الوصول إلى الاستخدام
    private fun openUsageAccessSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في فتح إعدادات الوصول للاستخدام: ${e.message}")
        }
    }

    // التحقق مما إذا كان التطبيق يتجاهل تحسينات البطارية
    private fun isIgnoringBatteryOptimizations(): Boolean {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                return true
            }
            val powerManager =
                    context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
            return powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في التحقق من تجاهل تحسينات البطارية: ${e.message}")
            return false
        }
    }

    // طلب تجاهل تحسينات البطارية
    private fun requestIgnoreBatteryOptimizations() {
        try {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
                return
            }
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
            intent.data = Uri.parse("package:${context.packageName}")
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في طلب تجاهل تحسينات البطارية: ${e.message}")
        }
    }
}
