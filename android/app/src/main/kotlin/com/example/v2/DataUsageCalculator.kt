package com.example.v2

import android.app.AppOpsManager
import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.ConnectivityManager
import android.os.Build
import android.os.Process
import android.os.RemoteException
import android.util.Log
import java.util.Calendar

object DataUsageCalculator {
    private val TAG = "DataUsageCalculator"

    // متغيرات لتخزين آخر قراءات
    var lastCurrentDataUsage: Double = 0.0
    var lastTodayDataUsage: Double = 0.0
    var lastTimestamp: Long = System.currentTimeMillis()

    // الحصول على استخدام البيانات الحالي بالميجابايت (آخر 3 ساعات)
    fun getCurrentDataUsage(context: Context): Double {
        try {
            if (!hasUsageStatsPermission(context)) {
                Log.e(TAG, "لا يوجد إذن للوصول لإحصائيات الاستخدام")
                return 0.0
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val networkStatsManager =
                        context.getSystemService(Context.NETWORK_STATS_SERVICE) as
                                NetworkStatsManager

                val calendar = Calendar.getInstance()
                val endTime = calendar.timeInMillis
                calendar.add(Calendar.HOUR, -3) // آخر 3 ساعات
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

                    val result = totalBytes.toDouble() / (1024 * 1024) // تحويل إلى ميجابايت
                    lastCurrentDataUsage = result
                    lastTimestamp = System.currentTimeMillis()
                    return result
                } catch (e: RemoteException) {
                    Log.e(TAG, "خطأ في الحصول على استخدام البيانات الحالي: ${e.message}")
                }
            }
            return 0.0
        } catch (e: Exception) {
            Log.e(TAG, "خطأ عام في getCurrentDataUsage: ${e.message}")
            return 0.0
        }
    }

    // الحصول على استخدام البيانات لليوم الحالي بالميجابايت
    fun getTodayDataUsage(context: Context): Double {
        try {
            if (!hasUsageStatsPermission(context)) {
                Log.e(TAG, "لا يوجد إذن للوصول لإحصائيات الاستخدام")
                return 0.0
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val networkStatsManager =
                        context.getSystemService(Context.NETWORK_STATS_SERVICE) as
                                NetworkStatsManager

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

                    val result = totalBytes.toDouble() / (1024 * 1024) // تحويل إلى ميجابايت
                    lastTodayDataUsage = result
                    lastTimestamp = System.currentTimeMillis()
                    return result
                } catch (e: RemoteException) {
                    Log.e(TAG, "خطأ في الحصول على استخدام البيانات اليومي: ${e.message}")
                }
            }
            return 0.0
        } catch (e: Exception) {
            Log.e(TAG, "خطأ عام في getTodayDataUsage: ${e.message}")
            return 0.0
        }
    }

    // التحقق من وجود إذن الوصول إلى إحصائيات الاستخدام
    fun hasUsageStatsPermission(context: Context): Boolean {
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
}
