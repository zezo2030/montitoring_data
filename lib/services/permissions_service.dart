import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionsService {
  // تعريف قناة المنصة باسم الحزمة الصحيح
  static const platform = MethodChannel('com.example.v2/permissions');

  // تحقق من جميع الأذونات المطلوبة
  static Future<bool> checkAllPermissions(BuildContext context) async {
    // تحقق من أذونات أساسية
    bool hasBasePermissions = await _checkAndRequestBasePermissions();
    if (!hasBasePermissions) {
      return false;
    }

    // تحقق من إذن إحصائيات الاستخدام (يحتاج صفحة إعدادات خاصة)
    bool hasUsageStats = await _checkAndRequestUsageStatsPermission(context);
    if (!hasUsageStats) {
      return false;
    }

    // تحقق من تجاهل تحسينات البطارية (للأندرويد 12+)
    bool hasBatteryOptimizationIgnored =
        await _checkAndRequestBatteryOptimization(context);

    return hasBatteryOptimizationIgnored;
  }

  // التحقق من وطلب الأذونات الأساسية
  static Future<bool> _checkAndRequestBasePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.notification,
    ].request();

    // تحقق ما إذا تم منح جميع الأذونات
    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        allGranted = false;
      }
    });

    return allGranted;
  }

  // التحقق من وطلب إذن إحصائيات الاستخدام
  static Future<bool> _checkAndRequestUsageStatsPermission(
      BuildContext context) async {
    bool hasPermission = false;

    try {
      hasPermission = await platform.invokeMethod('checkUsageStatsPermission');
    } on PlatformException catch (e) {
      print("خطأ في التحقق من إذن إحصائيات الاستخدام: ${e.message}");
      return false;
    }

    if (!hasPermission) {
      // إظهار حوار لتوجيه المستخدم إلى الإعدادات
      await _showUsageAccessDialog(context);

      // التحقق مرة أخرى بعد عودة المستخدم
      try {
        hasPermission =
            await platform.invokeMethod('checkUsageStatsPermission');
      } on PlatformException catch (e) {
        print("خطأ في التحقق من إذن إحصائيات الاستخدام: ${e.message}");
        return false;
      }
    }

    return hasPermission;
  }

  // التحقق من وطلب تجاهل تحسينات البطارية
  static Future<bool> _checkAndRequestBatteryOptimization(
      BuildContext context) async {
    if (!Platform.isAndroid) {
      return true; // لا حاجة لهذا الإذن على غير أندرويد
    }

    // تحقق من إصدار أندرويد (نحتاج الإذن فقط للإصدار 12+)
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkVersion = androidInfo.version.sdkInt ?? 0;

    if (sdkVersion < 31) {
      // أندرويد 12 هو SDK 31
      return true; // لا حاجة للإذن على إصدارات أقدم
    }

    bool isIgnoringBatteryOptimizations = false;

    try {
      isIgnoringBatteryOptimizations =
          await platform.invokeMethod('isIgnoringBatteryOptimizations');
    } on PlatformException catch (e) {
      print("خطأ في التحقق من إذن تجاهل تحسينات البطارية: ${e.message}");
      return false;
    }

    if (!isIgnoringBatteryOptimizations) {
      // إظهار حوار لتوجيه المستخدم للسماح بتجاهل تحسينات البطارية
      await _showBatteryOptimizationDialog(context);

      // طلب الإذن
      try {
        await platform.invokeMethod('requestIgnoreBatteryOptimizations');

        // التحقق مرة أخرى بعد عودة المستخدم
        isIgnoringBatteryOptimizations =
            await platform.invokeMethod('isIgnoringBatteryOptimizations');
      } on PlatformException catch (e) {
        print("خطأ في طلب إذن تجاهل تحسينات البطارية: ${e.message}");
        return false;
      }
    }

    return isIgnoringBatteryOptimizations;
  }

  // عرض حوار لتوجيه المستخدم إلى إعدادات إذن الوصول للاستخدام
  static Future<void> _showUsageAccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إذن مطلوب'),
          content: const Text(
              'يحتاج التطبيق إلى إذن "الوصول إلى بيانات الاستخدام" للعمل بشكل صحيح.\n\n'
              'سيتم توجيهك إلى صفحة الإعدادات. الرجاء تفعيل "الوصول إلى بيانات الاستخدام" لتطبيقنا.'),
          actions: <Widget>[
            TextButton(
              child: const Text('الإعدادات'),
              onPressed: () async {
                Navigator.of(context).pop();
                // فتح صفحة إعدادات الوصول للاستخدام
                try {
                  await platform.invokeMethod('openUsageAccessSettings');
                } on PlatformException catch (e) {
                  print("خطأ في فتح الإعدادات: ${e.message}");
                }
              },
            ),
            TextButton(
              child: const Text('لاحقًا'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // عرض حوار لتوجيه المستخدم إلى إعدادات تجاهل تحسينات البطارية
  static Future<void> _showBatteryOptimizationDialog(
      BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('إذن مطلوب'),
          content: const Text(
              'يحتاج التطبيق إلى تعطيل تحسينات البطارية للعمل في الخلفية بشكل صحيح.\n\n'
              'سيتم طلب الإذن في الشاشة التالية.'),
          actions: <Widget>[
            TextButton(
              child: const Text('موافق'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
