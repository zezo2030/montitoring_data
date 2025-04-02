import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppIconService {
  static const MethodChannel _channel =
      MethodChannel('com.example.v2/app_icon');
  static final Map<String, Image> _iconCache = {};

  // الحصول على أيقونة التطبيق
  static Future<Image?> getAppIcon(String packageName) async {
    // التحقق من الذاكرة المؤقتة أولاً
    if (_iconCache.containsKey(packageName)) {
      return _iconCache[packageName]!;
    }

    try {
      final String? base64String = await _channel.invokeMethod('getAppIcon', {
        'packageName': packageName,
      });

      if (base64String == null || base64String.isEmpty) {
        return null;
      }

      // تحويل المعلومات المشفرة إلى صورة
      final Uint8List bytes = base64Decode(base64String);
      final image = Image.memory(
        bytes,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
      );

      // تخزين الصورة في الذاكرة المؤقتة
      _iconCache[packageName] = image;
      return image;
    } catch (e) {
      print('خطأ في الحصول على أيقونة التطبيق: $e');
      return null;
    }
  }
}
