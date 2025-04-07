import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // تتبع آخر وقت لإرسال إشعار لتجنب التكرار
  int _lastLimitNotificationTime = 0;
  int _lastApproachingNotificationTime = 0;

  // الفاصل الزمني الأدنى بين الإشعارات (20 دقيقة)
  static const int _minimumNotificationIntervalMs = 20 * 60 * 1000;

  // تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    if (_isInitialized) return;

    // إعدادات للأندرويد
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // إعدادات للـ iOS
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // تهيئة الإعدادات لجميع المنصات
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // تهيئة المكون
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        // يمكن معالجة النقر على الإشعار هنا
        print('تم النقر على الإشعار: ${response.payload}');
      },
    );

    // إنشاء قناة الإشعارات للأندرويد
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    _isInitialized = true;
    print('تم تهيئة خدمة الإشعارات بنجاح');
  }

  // إنشاء قناة إشعارات للأندرويد
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'data_usage_alerts',
      'استهلاك البيانات',
      description: 'تنبيهات تتعلق باستهلاك بيانات الإنترنت',
      importance: Importance.high,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // إرسال إشعار عند الوصول للحد اليومي
  Future<void> showDailyLimitReachedNotification({
    required double usage,
    required double limit,
    String? title,
    String? body,
  }) async {
    // منع إرسال إشعارات متكررة خلال فترة زمنية قصيرة
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLimitNotificationTime < _minimumNotificationIntervalMs) {
      print('تم منع إشعار متكرر عن الوصول للحد');
      return;
    }

    _lastLimitNotificationTime = now;

    if (!_isInitialized) {
      await initialize();
    }

    title = title ?? 'حصتك اليوميه خلصت';
    body = body ?? 'عزوز بيقولك خلصت النت وهيفصل دلوقتي';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'data_usage_alerts',
      'استهلاك البيانات',
      channelDescription: 'تنبيهات تتعلق باستهلاك بيانات الإنترنت',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.red,
      ledColor: Colors.red,
      ledOnMs: 1000,
      ledOffMs: 500,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      0, // معرف الإشعار
      title,
      body,
      notificationDetails,
      payload:
          'dailyLimit_${usage.toStringAsFixed(1)}_${limit.toStringAsFixed(1)}',
    );

    print('تم إرسال إشعار: $title - $body');
  }

  // إرسال إشعار عند الاقتراب من الحد اليومي
  Future<void> showApproachingLimitNotification({
    required double usage,
    required double limit,
    required double threshold, // نسبة مئوية (مثل 80 تعني 80%)
    String? title,
    String? body,
  }) async {
    // منع إرسال إشعارات متكررة خلال فترة زمنية قصيرة
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastApproachingNotificationTime <
        _minimumNotificationIntervalMs) {
      print('تم منع إشعار متكرر عن الاقتراب من الحد');
      return;
    }

    _lastApproachingNotificationTime = now;

    if (!_isInitialized) {
      await initialize();
    }

    final percentage = usage / limit * 100;
    title = title ?? 'اقتراب من حد الاستهلاك';
    body = body ??
        'وصلت إلى ${percentage.toStringAsFixed(1)}% من الحد اليومي (${limit.toStringAsFixed(1)} ميجابايت)';

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'data_usage_alerts',
      'استهلاك البيانات',
      channelDescription: 'تنبيهات تتعلق باستهلاك بيانات الإنترنت',
      importance: Importance.high,
      priority: Priority.high,
      color: Colors.orange,
      icon: '@mipmap/ic_launcher',
    );

    final DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      1, // معرف الإشعار
      title,
      body,
      notificationDetails,
      payload:
          'approaching_${usage.toStringAsFixed(1)}_${limit.toStringAsFixed(1)}',
    );

    print('تم إرسال إشعار الاقتراب: $title - $body');
  }

  // تنظيف وإلغاء الإشعارات
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
