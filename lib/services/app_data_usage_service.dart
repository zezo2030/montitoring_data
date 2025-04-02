import 'dart:convert';
import 'package:flutter/services.dart';

class AppDataUsageService {
  static const MethodChannel _channel =
      MethodChannel('com.example.v2/app_data_usage');

  // الحصول على استخدام الواي فاي للتطبيقات
  static Future<List<Map<String, dynamic>>> getAppsWifiDataUsage(
      {int timeRange = 24}) async {
    try {
      final String result = await _channel
          .invokeMethod('getAppsWifiDataUsage', {'timeRange': timeRange});
      final List<dynamic> appsData = jsonDecode(result);
      return appsData.map((app) => Map<String, dynamic>.from(app)).toList();
    } catch (e) {
      print('خطأ في الحصول على استخدام الواي فاي للتطبيقات: $e');
      return [];
    }
  }

  // الحصول على استخدام بيانات الجوال للتطبيقات
  static Future<List<Map<String, dynamic>>> getAppsMobileDataUsage(
      {int timeRange = 24}) async {
    try {
      final String result = await _channel
          .invokeMethod('getAppsMobileDataUsage', {'timeRange': timeRange});
      final List<dynamic> appsData = jsonDecode(result);
      return appsData.map((app) => Map<String, dynamic>.from(app)).toList();
    } catch (e) {
      print('خطأ في الحصول على استخدام بيانات الجوال للتطبيقات: $e');
      return [];
    }
  }

  // الحصول على استخدام كل البيانات (واي فاي + جوال) للتطبيقات
  static Future<List<Map<String, dynamic>>> getAllAppsDataUsage(
      {int timeRange = 24}) async {
    try {
      final String result = await _channel
          .invokeMethod('getAllAppsDataUsage', {'timeRange': timeRange});
      final List<dynamic> appsData = jsonDecode(result);
      return appsData.map((app) => Map<String, dynamic>.from(app)).toList();
    } catch (e) {
      print('خطأ في الحصول على إجمالي استخدام البيانات للتطبيقات: $e');
      return [];
    }
  }

  // الحصول على البيانات مرتبة حسب الاستخدام الأعلى
  static Future<List<Map<String, dynamic>>> getSortedAppsDataUsage(
      {int timeRange = 24}) async {
    final apps = await getAllAppsDataUsage(timeRange: timeRange);

    // ترتيب التطبيقات حسب إجمالي الاستخدام تنازلياً
    apps.sort((a, b) =>
        (b['totalUsageMB'] as double).compareTo(a['totalUsageMB'] as double));

    return apps;
  }
}
