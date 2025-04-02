import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// خدمة إدارة الأذونات في التطبيق
class PermissionsService {
  // ===== الثوابت =====
  static const platform = MethodChannel('com.example.v2/permissions');

  // ===== الواجهة العامة =====

  /// التحقق من جميع الأذونات المطلوبة بدون طلبها تلقائياً
  static Future<bool> checkAllPermissions(BuildContext context) async {
    // تحقق من أذونات أساسية
    bool hasBasePermissions = await _checkBasePermissions();
    if (!hasBasePermissions) return false;

    // تحقق من إذن إحصائيات الاستخدام
    bool hasUsageStats = await _checkUsageStatsPermission(context);
    if (!hasUsageStats) return false;

    // تحقق من تجاهل تحسينات البطارية
    return await _checkBatteryOptimization(context);
  }

  /// طلب جميع الأذونات اللازمة وانتظار استجابة المستخدم
  static Future<bool> requestAllPermissions(BuildContext context) async {
    // طلب الأذونات الأساسية
    bool hasBasePermissions = await _requestBasePermissions();
    if (!hasBasePermissions) return false;

    // طلب إذن إحصائيات الاستخدام
    bool hasUsageStats = await _checkAndRequestUsageStatsPermission(context);
    if (!hasUsageStats) return false;

    // طلب تجاهل تحسينات البطارية
    return await _checkAndRequestBatteryOptimization(context);
  }

  // ===== طرق التحقق من الأذونات (بدون طلب) =====

  /// التحقق فقط من الأذونات الأساسية بدون طلبها
  static Future<bool> _checkBasePermissions() async {
    Map<Permission, PermissionStatus> statuses = {
      Permission.phone: await Permission.phone.status,
      Permission.notification: await Permission.notification.status,
    };

    return statuses.values.every((status) => status.isGranted);
  }

  /// التحقق فقط من إذن إحصائيات الاستخدام
  static Future<bool> _checkUsageStatsPermission(BuildContext context) async {
    try {
      return await platform.invokeMethod('checkUsageStatsPermission');
    } on PlatformException catch (e) {
      print("خطأ في التحقق من إذن إحصائيات الاستخدام: ${e.message}");
      return false;
    }
  }

  /// التحقق فقط من تجاهل تحسينات البطارية
  static Future<bool> _checkBatteryOptimization(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkVersion = androidInfo.version.sdkInt ?? 0;

    if (sdkVersion < 31) return true;

    try {
      return await platform.invokeMethod('isIgnoringBatteryOptimizations');
    } on PlatformException catch (e) {
      print("خطأ في التحقق من إذن تجاهل تحسينات البطارية: ${e.message}");
      return false;
    }
  }

  // ===== طرق طلب الأذونات =====

  /// طلب الأذونات الأساسية
  static Future<bool> _requestBasePermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.phone,
      Permission.notification,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  /// التحقق من وطلب إذن إحصائيات الاستخدام
  static Future<bool> _checkAndRequestUsageStatsPermission(
      BuildContext context) async {
    try {
      bool hasPermission =
          await platform.invokeMethod('checkUsageStatsPermission');

      if (!hasPermission) {
        await _showUsageAccessDialog(context);
        hasPermission =
            await platform.invokeMethod('checkUsageStatsPermission');
      }

      return hasPermission;
    } on PlatformException catch (e) {
      print("خطأ في التحقق من إذن إحصائيات الاستخدام: ${e.message}");
      return false;
    }
  }

  /// التحقق من وطلب تجاهل تحسينات البطارية
  static Future<bool> _checkAndRequestBatteryOptimization(
      BuildContext context) async {
    if (!Platform.isAndroid) return true;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkVersion = androidInfo.version.sdkInt ?? 0;

    if (sdkVersion < 31) return true;

    try {
      bool isIgnoringBatteryOptimizations =
          await platform.invokeMethod('isIgnoringBatteryOptimizations');

      if (!isIgnoringBatteryOptimizations) {
        await _showBatteryOptimizationDialog(context);
        await platform.invokeMethod('requestIgnoreBatteryOptimizations');
        isIgnoringBatteryOptimizations =
            await platform.invokeMethod('isIgnoringBatteryOptimizations');
      }

      return isIgnoringBatteryOptimizations;
    } on PlatformException catch (e) {
      print("خطأ في التحقق من إذن تجاهل تحسينات البطارية: ${e.message}");
      return false;
    }
  }

  // ===== حوارات واجهة المستخدم =====

  /// عرض حوار لتوجيه المستخدم إلى إعدادات إذن الوصول للاستخدام
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

  /// عرض حوار لتوجيه المستخدم إلى إعدادات تجاهل تحسينات البطارية
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
