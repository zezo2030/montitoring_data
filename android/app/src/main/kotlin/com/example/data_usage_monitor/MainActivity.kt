package com.example.data_usage_monitor

import android.app.AppOpsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PERMISSIONS_CHANNEL = "com.example.data_usage_monitor/permissions"
    private val DATA_MONITOR_CHANNEL = "com.example.data_usage_monitor/data_monitor"
    private val DATA_LIMIT_CHANNEL = "com.example.data_usage_monitor/data_limit"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // تهيئة قناة الأذونات
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PERMISSIONS_CHANNEL)
                .setMethodCallHandler { call, result ->
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
                }
        
        // تهيئة قناة مراقبة البيانات
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_MONITOR_CHANNEL)
                .setMethodCallHandler(DataMonitorChannel(context))

        // تهيئة قناة حدود البيانات
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_LIMIT_CHANNEL)
                .setMethodCallHandler(DataLimitChannel(context))
    }

    // التحقق من وجود إذن الوصول إلى إحصائيات الاستخدام
    private fun hasUsageStatsPermission(): Boolean {
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
    }

    // فتح إعدادات الوصول إلى الاستخدام
    private fun openUsageAccessSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    // التحقق مما إذا كان التطبيق يتجاهل تحسينات البطارية
    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }
        val powerManager =
                context.getSystemService(Context.POWER_SERVICE) as android.os.PowerManager
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    // طلب تجاهل تحسينات البطارية
    private fun requestIgnoreBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                data = Uri.parse("package:${context.packageName}")
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        }
    }
} 