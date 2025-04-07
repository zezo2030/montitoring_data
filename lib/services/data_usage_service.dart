import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/data_usage_model.dart';

class DataUsageService {
  static const MethodChannel _monitorChannel =
      MethodChannel('com.example.v2/data_monitor');
  static const MethodChannel _limitChannel =
      MethodChannel('com.example.v2/data_limit');
  static const EventChannel _dataStreamChannel =
      EventChannel('com.example.v2/data_stream');

  // تدفق البيانات - سيتم تحديثه بشكل مستمر
  static Stream<DataUsageUpdate>? _dataStream;

  // الحصول على تدفق تحديثات البيانات المستمر
  static Stream<DataUsageUpdate> getDataUsageStream() {
    _dataStream ??= _dataStreamChannel
        .receiveBroadcastStream()
        .map<String>((dynamic event) => event as String)
        .map<DataUsageUpdate>((jsonString) {
      try {
        final jsonData = json.decode(jsonString);
        return DataUsageUpdate(
          currentUsage: (jsonData['currentUsage'] as num).toDouble(),
          todayUsage: (jsonData['todayUsage'] as num).toDouble(),
          timestamp: jsonData['timestamp'] as int,
          dailyLimit: (jsonData['dailyLimit'] as num).toDouble(),
        );
      } catch (e) {
        print('خطأ في تحليل بيانات JSON: $e');
        // إرجاع بيانات تجريبية في حالة حدوث خطأ
        return DataUsageUpdate(
          currentUsage: getMockDataUsage(),
          todayUsage: getMockDataUsage() * 6,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          dailyLimit: 0.0,
        );
      }
    }).asBroadcastStream();

    return _dataStream!;
  }

  // إضافة طريقة للاختبار السريع، تعيد معلومات تجريبية
  static double getMockDataUsage() {
    // بيانات تجريبية للاختبار
    return 150.5; // ميجابايت
  }

  // الحصول على استهلاك البيانات الحالي (بالميجابايت)
  static Future<double> getCurrentDataUsage() async {
    try {
      final result = await _monitorChannel.invokeMethod('getCurrentDataUsage');
      // التأكد من أن النتيجة هي رقم
      if (result is num) {
        return result.toDouble();
      } else {
        print('نوع غير متوقع: ${result.runtimeType}');
        return getMockDataUsage();
      }
    } catch (e) {
      print('خطأ في الحصول على استهلاك البيانات: $e');
      // إرجاع بيانات تجريبية في حالة حدوث خطأ
      return getMockDataUsage();
    }
  }

  // الحصول على استهلاك البيانات لليوم الحالي (بالميجابايت)
  static Future<double> getTodayDataUsage() async {
    try {
      final result = await _monitorChannel.invokeMethod('getTodayDataUsage');
      // التأكد من أن النتيجة هي رقم
      if (result is num) {
        return result.toDouble();
      } else {
        print('نوع غير متوقع: ${result.runtimeType}');
        return getMockDataUsage() * 6;
      }
    } catch (e) {
      print('خطأ في الحصول على استهلاك البيانات اليومي: $e');
      // إرجاع بيانات تجريبية × 6 للاستهلاك اليومي
      return getMockDataUsage() * 6;
    }
  }

  // التحقق ما إذا كانت خدمة المراقبة نشطة
  static Future<bool> isMonitoringActive() async {
    try {
      final result = await _monitorChannel.invokeMethod('isMonitoringActive');
      if (result is bool) {
        return result;
      }
      return false;
    } catch (e) {
      print('خطأ في التحقق من حالة المراقبة: $e');
      return false;
    }
  }

  // بدء مراقبة البيانات في الخلفية
  static Future<bool> startMonitoringDataUsage() async {
    try {
      final result = await _monitorChannel.invokeMethod('startMonitoring');
      if (result is bool) {
        return result;
      }
      return true;
    } catch (e) {
      print('خطأ في بدء مراقبة البيانات: $e');
      // إعادة true للتجربة
      return true;
    }
  }

  // إيقاف مراقبة البيانات في الخلفية
  static Future<bool> stopMonitoringDataUsage() async {
    try {
      final result = await _monitorChannel.invokeMethod('stopMonitoring');
      if (result is bool) {
        return result;
      }
      return true;
    } catch (e) {
      print('خطأ في إيقاف مراقبة البيانات: $e');
      // إعادة true للتجربة
      return true;
    }
  }

  // تعيين حد يومي لاستهلاك البيانات (بالميجابايت)
  static Future<bool> setDailyDataLimit(double limitMB) async {
    try {
      final result = await _limitChannel
          .invokeMethod('setDailyLimit', {'limitMB': limitMB});
      if (result is bool) {
        return result;
      }
      return true;
    } catch (e) {
      print('خطأ في تعيين الحد اليومي: $e');
      return true;
    }
  }

  // الحصول على الحد اليومي الحالي (بالميجابايت)
  static Future<double> getDailyDataLimit() async {
    try {
      final result = await _limitChannel.invokeMethod('getDailyLimit');
      // التأكد من أن النتيجة هي رقم
      if (result is num) {
        return result.toDouble();
      } else {
        print('نوع غير متوقع: ${result.runtimeType}');
        return 0.0;
      }
    } catch (e) {
      print('خطأ في الحصول على الحد اليومي: $e');
      return 0.0;
    }
  }

  // تفعيل/إلغاء تفعيل التنبيهات عند الوصول للحد اليومي
  static Future<bool> setLimitAlertEnabled(bool enabled) async {
    try {
      final result = await _limitChannel
          .invokeMethod('setLimitAlertEnabled', {'enabled': enabled});
      if (result is bool) {
        return result;
      }
      return true;
    } catch (e) {
      print('خطأ في تعيين حالة تنبيه الحد: $e');
      return true;
    }
  }
}
