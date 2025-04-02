package com.example.v2

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class AppIconChannel(private val context: Context) : MethodChannel.MethodCallHandler {
    private val TAG = "AppIconChannel"

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "getAppIcon" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName == null) {
                        result.error("MISSING_PARAMS", "يجب تحديد اسم الحزمة", null)
                        return
                    }

                    val icon = getAppIcon(packageName)
                    result.success(icon)
                }
                else -> {
                    result.notImplemented()
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في قناة أيقونات التطبيقات: ${e.message}", e)
            result.error("ERROR", e.message, null)
        }
    }

    private fun getAppIcon(packageName: String): String? {
        try {
            val packageManager = context.packageManager
            val drawable = packageManager.getApplicationIcon(packageName)

            return drawableToBase64(drawable)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في الحصول على أيقونة التطبيق: ${e.message}", e)
            return null
        }
    }

    private fun drawableToBase64(drawable: Drawable): String {
        try {
            val bitmap =
                    if (drawable is BitmapDrawable) {
                        drawable.bitmap
                    } else {
                        val width = 128
                        val height = 128
                        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                        val canvas = Canvas(bitmap)
                        drawable.setBounds(0, 0, canvas.width, canvas.height)
                        drawable.draw(canvas)
                        bitmap
                    }

            val byteArrayOutputStream = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream)
            val byteArray = byteArrayOutputStream.toByteArray()

            return Base64.encodeToString(byteArray, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(TAG, "خطأ في تحويل الأيقونة: ${e.message}", e)
            return ""
        }
    }
}
