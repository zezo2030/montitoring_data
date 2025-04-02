package com.example.v2

import android.app.usage.NetworkStats
import android.app.usage.NetworkStatsManager
import android.content.Context
import android.net.ConnectivityManager
import android.os.Build
import android.os.Process
import android.util.Log
import java.util.Calendar
import org.json.JSONArray
import org.json.JSONObject

object AppDataUsageCalculator {
    private val TAG = "AppDataUsageCalculator"

    // الحصول على استخدام البيانات لكل تطبيق (الواي فاي)
    fun getAppsWifiDataUsage(context: Context, timeRangeInHours: Int = 24): JSONArray {
        val appsUsage = JSONArray()

        try {
            if (!DataUsageCalculator.hasUsageStatsPermission(context)) {
                Log.e(TAG, "لا يوجد إذن للوصول لإحصائيات الاستخدام")
                return appsUsage
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val networkStatsManager =
                        context.getSystemService(Context.NETWORK_STATS_SERVICE) as
                                NetworkStatsManager
                val packageManager = context.packageManager

                val calendar = Calendar.getInstance()
                val endTime = calendar.timeInMillis

                // تعيين وقت البداية حسب المدة المطلوبة
                calendar.add(Calendar.HOUR, -timeRangeInHours)
                val startTime = calendar.timeInMillis

                // جمع استخدام الواي فاي
                val stats =
                        networkStatsManager.querySummary(
                                ConnectivityManager.TYPE_WIFI,
                                "",
                                startTime,
                                endTime
                        )

                // خريطة لتجميع البيانات حسب التطبيق
                val appUsageMap = mutableMapOf<Int, Long>()
                val bucket = NetworkStats.Bucket()

                // جمع البيانات من الإحصائيات
                while (stats.hasNextBucket()) {
                    stats.getNextBucket(bucket)
                    val uid = bucket.uid
                    val bytesTotal = bucket.rxBytes + bucket.txBytes

                    // إضافة البيانات إلى الخريطة
                    appUsageMap[uid] = (appUsageMap[uid] ?: 0L) + bytesTotal
                }
                stats.close()

                // إنشاء قائمة بالتطبيقات وبياناتها
                for ((uid, bytes) in appUsageMap) {
                    // تجاهل التطبيقات النظامية والمحذوفة
                    if (uid <= Process.FIRST_APPLICATION_UID) continue

                    try {
                        val packages = packageManager.getPackagesForUid(uid)
                        if (packages != null && packages.isNotEmpty()) {
                            val packageName = packages[0]
                            val appInfo = packageManager.getApplicationInfo(packageName, 0)
                            val appName = packageManager.getApplicationLabel(appInfo).toString()

                            // تحويل البيانات إلى ميجابايت
                            val usageMB = bytes.toDouble() / (1024 * 1024)

                            val appData = JSONObject()
                            appData.put("packageName", packageName)
                            appData.put("appName", appName)
                            appData.put("usageMB", usageMB)

                            // إضافة معلومات الأيقونة
                            try {
                                val iconDrawable = packageManager.getApplicationIcon(packageName)
                                appData.put("hasIcon", true)
                            } catch (e: Exception) {
                                appData.put("hasIcon", false)
                            }

                            appsUsage.put(appData)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "خطأ في الحصول على معلومات التطبيق: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ عام في الحصول على استخدام البيانات للتطبيقات: ${e.message}")
        }

        return appsUsage
    }

    // الحصول على استخدام البيانات لكل تطبيق (بيانات الجوال)
    fun getAppsMobileDataUsage(context: Context, timeRangeInHours: Int = 24): JSONArray {
        val appsUsage = JSONArray()

        try {
            if (!DataUsageCalculator.hasUsageStatsPermission(context)) {
                Log.e(TAG, "لا يوجد إذن للوصول لإحصائيات الاستخدام")
                return appsUsage
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val networkStatsManager =
                        context.getSystemService(Context.NETWORK_STATS_SERVICE) as
                                NetworkStatsManager
                val packageManager = context.packageManager

                val calendar = Calendar.getInstance()
                val endTime = calendar.timeInMillis

                // تعيين وقت البداية حسب المدة المطلوبة
                calendar.add(Calendar.HOUR, -timeRangeInHours)
                val startTime = calendar.timeInMillis

                // جمع استخدام بيانات الجوال
                val stats =
                        networkStatsManager.querySummary(
                                ConnectivityManager.TYPE_MOBILE,
                                null, // لا نحتاج معرف المشترك لحساب استخدام التطبيقات
                                startTime,
                                endTime
                        )

                // خريطة لتجميع البيانات حسب التطبيق
                val appUsageMap = mutableMapOf<Int, Long>()
                val bucket = NetworkStats.Bucket()

                // جمع البيانات من الإحصائيات
                while (stats.hasNextBucket()) {
                    stats.getNextBucket(bucket)
                    val uid = bucket.uid
                    val bytesTotal = bucket.rxBytes + bucket.txBytes

                    // إضافة البيانات إلى الخريطة
                    appUsageMap[uid] = (appUsageMap[uid] ?: 0L) + bytesTotal
                }
                stats.close()

                // إنشاء قائمة بالتطبيقات وبياناتها
                for ((uid, bytes) in appUsageMap) {
                    // تجاهل التطبيقات النظامية والمحذوفة
                    if (uid <= Process.FIRST_APPLICATION_UID) continue

                    try {
                        val packages = packageManager.getPackagesForUid(uid)
                        if (packages != null && packages.isNotEmpty()) {
                            val packageName = packages[0]
                            val appInfo = packageManager.getApplicationInfo(packageName, 0)
                            val appName = packageManager.getApplicationLabel(appInfo).toString()

                            // تحويل البيانات إلى ميجابايت
                            val usageMB = bytes.toDouble() / (1024 * 1024)

                            val appData = JSONObject()
                            appData.put("packageName", packageName)
                            appData.put("appName", appName)
                            appData.put("usageMB", usageMB)

                            // إضافة معلومات الأيقونة
                            try {
                                val iconDrawable = packageManager.getApplicationIcon(packageName)
                                appData.put("hasIcon", true)
                            } catch (e: Exception) {
                                appData.put("hasIcon", false)
                            }

                            appsUsage.put(appData)
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "خطأ في الحصول على معلومات التطبيق: ${e.message}")
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ عام في الحصول على استخدام بيانات الجوال للتطبيقات: ${e.message}")
        }

        return appsUsage
    }

    // الحصول على مجموع استخدام البيانات لكل تطبيق (واي فاي + بيانات الجوال)
    fun getAllAppsDataUsage(context: Context, timeRangeInHours: Int = 24): JSONArray {
        val appsUsage = JSONArray()

        try {
            // خريطة لتخزين إجمالي استخدام كل تطبيق
            val totalUsageMap = mutableMapOf<String, AppUsageInfo>()

            // الحصول على استخدام الواي فاي
            val wifiUsage = getAppsWifiDataUsage(context, timeRangeInHours)
            for (i in 0 until wifiUsage.length()) {
                val appData = wifiUsage.getJSONObject(i)
                val packageName = appData.getString("packageName")
                val appName = appData.getString("appName")
                val usageMB = appData.getDouble("usageMB")

                totalUsageMap[packageName] = AppUsageInfo(packageName, appName, wifiMB = usageMB)
            }

            // الحصول على استخدام بيانات الجوال
            val mobileUsage = getAppsMobileDataUsage(context, timeRangeInHours)
            for (i in 0 until mobileUsage.length()) {
                val appData = mobileUsage.getJSONObject(i)
                val packageName = appData.getString("packageName")
                val appName = appData.getString("appName")
                val usageMB = appData.getDouble("usageMB")

                if (totalUsageMap.containsKey(packageName)) {
                    // إضافة استخدام البيانات الخلوية إلى التطبيق الموجود
                    totalUsageMap[packageName]?.mobileMB = usageMB
                } else {
                    // إنشاء سجل جديد للتطبيق
                    totalUsageMap[packageName] =
                            AppUsageInfo(packageName, appName, mobileMB = usageMB)
                }
            }

            // تحويل الخريطة إلى JSONArray
            for (appInfo in totalUsageMap.values) {
                val appData = JSONObject()
                appData.put("packageName", appInfo.packageName)
                appData.put("appName", appInfo.appName)
                appData.put("wifiUsageMB", appInfo.wifiMB)
                appData.put("mobileUsageMB", appInfo.mobileMB)
                appData.put("totalUsageMB", appInfo.wifiMB + appInfo.mobileMB)

                appsUsage.put(appData)
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ عام في الحصول على إجمالي استخدام البيانات للتطبيقات: ${e.message}")
        }

        return appsUsage
    }

    // فئة مساعدة لتخزين معلومات استخدام التطبيق
    private data class AppUsageInfo(
            val packageName: String,
            val appName: String,
            var wifiMB: Double = 0.0,
            var mobileMB: Double = 0.0
    )
}
