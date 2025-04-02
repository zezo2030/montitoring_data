package com.example.v2

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    private val TAG = "BootReceiver"

    override fun onReceive(context: Context, intent: Intent) {
        try {
            if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
                            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
                            intent.action == "android.intent.action.QUICKBOOT_POWERON"
            ) {

                Log.d(TAG, "تم استقبال إشارة إعادة التشغيل، بدء خدمة المراقبة")

                // تأخير بدء الخدمة قليلاً بعد إعادة التشغيل
                Thread.sleep(1000)

                // بدء الخدمة
                val serviceIntent = Intent(context, DataMonitorService::class.java)
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(serviceIntent)
                } else {
                    context.startService(serviceIntent)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في بدء الخدمة بعد إعادة التشغيل: ${e.message}")
        }
    }
}
