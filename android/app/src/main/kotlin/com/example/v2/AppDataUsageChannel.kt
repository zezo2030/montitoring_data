package com.example.v2

import android.content.Context
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class AppDataUsageChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    private val TAG = "AppDataUsageChannel"

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getAppsWifiDataUsage" -> {
                    val timeRange = call.argument<Int>("timeRange") ?: 24
                    val wifiUsage = AppDataUsageCalculator.getAppsWifiDataUsage(context, timeRange)
                    result.success(wifiUsage.toString())
                }
                "getAppsMobileDataUsage" -> {
                    val timeRange = call.argument<Int>("timeRange") ?: 24
                    val mobileUsage =
                            AppDataUsageCalculator.getAppsMobileDataUsage(context, timeRange)
                    result.success(mobileUsage.toString())
                }
                "getAllAppsDataUsage" -> {
                    val timeRange = call.argument<Int>("timeRange") ?: 24
                    val allUsage = AppDataUsageCalculator.getAllAppsDataUsage(context, timeRange)
                    result.success(allUsage.toString())
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في قناة استخدام بيانات التطبيقات: ${e.message}", e)
            result.error("ERROR", e.message, null)
        }
    }
}
