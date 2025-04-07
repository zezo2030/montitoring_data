import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'package:ABRAR/services/service_locator.dart';
import 'package:ABRAR/services/shared_preferences_service.dart';

class FirebaseService {
  // المثيل الوحيد للخدمة
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // مراجع قاعدة البيانات
  late FirebaseFirestore _firestore;
  late CollectionReference _devicesCollection;
  String? _deviceId;
  String? _deviceName;
  bool _isInitialized = false;

  // مستمع التغييرات للحد اليومي
  StreamSubscription<DocumentSnapshot>? _dailyLimitListener;
  // للاستماع للتغييرات في الإعدادات
  final StreamController<int> _dailyLimitStreamController =
      StreamController<int>.broadcast();

  // الحصول على تدفق (stream) التغييرات للحد اليومي
  Stream<int> get dailyLimitStream => _dailyLimitStreamController.stream;

  // الحد الأقصى لعدد التطبيقات المخزنة
  static const int MAX_APPS_TO_STORE = 20;

  // تهيئة Firebase
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // التأكد من تهيئة Firebase أولاً
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // تهيئة Firestore بعد التأكد من تهيئة Firebase
      _firestore = FirebaseFirestore.instance;

      // تكوين الوضع غير المتصل بإعدادات محسنة
      try {
        _firestore.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes:
              20 * 1024 * 1024, // زيادة إلى 20 ميجابايت للأداء الأفضل
          sslEnabled: true,
        );

        // تقليل عدد العمليات المتزامنة لتحسين الأداء
        await _firestore.terminate();
        await _firestore.clearPersistence();
        _firestore = FirebaseFirestore.instance;
      } catch (settingsError) {
        print('تحذير: فشل ضبط إعدادات Firestore: $settingsError');
        // الاستمرار رغم الخطأ
      }

      _devicesCollection = _firestore.collection('devices');

      await _initializeDeviceInfo();
      _isInitialized = true;

      // بدء الاستماع للتغييرات في الحد اليومي
      startListeningToDailyLimit();

      print('تم تهيئة Firebase Firestore بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تهيئة Firebase: $e');
      // محاولة إعادة الاتصال بعد تأخير
      await Future.delayed(Duration(seconds: 3));
      if (!_isInitialized) {
        print('محاولة إعادة الاتصال بـ Firebase...');
        return initialize();
      }
      return false;
    }
  }

  // بدء الاستماع للتغييرات في الحد اليومي
  void startListeningToDailyLimit() {
    if (_deviceName == null || !_isInitialized) return;

    // إلغاء أي مستمع سابق
    _dailyLimitListener?.cancel();

    try {
      print('بدء الاستماع للتغييرات في الحد اليومي...');
      print(_deviceId);
      print("device name ${_deviceName}");
      // تسجيل مستمع للتغييرات على مستند الجهاز
      _dailyLimitListener =
          _devicesCollection.doc(_deviceName).snapshots().listen(
        (DocumentSnapshot snapshot) {
          if (snapshot.exists) {
            final data = snapshot.data() as Map<String, dynamic>?;
            if (data != null && data.containsKey('settings')) {
              final settings = data['settings'] as Map<String, dynamic>?;
              if (settings != null && settings.containsKey('dailyLimit')) {
                var limit = settings['dailyLimit'];
                int dailyLimit = 1000; // قيمة افتراضية

                // معالجة مرنة لأنواع مختلفة من البيانات
                if (limit is int) dailyLimit = limit;
                if (limit is double) dailyLimit = limit.toInt();
                if (limit is String) dailyLimit = int.tryParse(limit) ?? 1000;

                print('تم استلام تحديث للحد اليومي: $dailyLimit ميجابايت');
                // إرسال القيمة الجديدة إلى التدفق
                _dailyLimitStreamController.add(dailyLimit);
              }
            }
          }
        },
        onError: (error) {
          print('خطأ في مستمع التغييرات للحد اليومي: $error');
          // محاولة إعادة الاتصال بعد مدة
          Future.delayed(Duration(seconds: 30), () {
            if (_dailyLimitListener == null) {
              print('محاولة إعادة الاتصال بمستمع الحد اليومي...');
              startListeningToDailyLimit();
            }
          });
        },
        onDone: () {
          print('تم إغلاق مستمع الحد اليومي');
          // إعادة الاتصال في حالة الانقطاع غير المتوقع
          Future.delayed(Duration(seconds: 5), () {
            if (_dailyLimitListener == null) {
              print('محاولة إعادة الاتصال التلقائي بمستمع الحد اليومي...');
              startListeningToDailyLimit();
            }
          });
        },
      );
    } catch (e) {
      print('خطأ في بدء الاستماع للتغييرات في الحد اليومي: $e');
      // محاولة إعادة الاتصال بعد مدة
      Future.delayed(Duration(seconds: 60), () {
        print('محاولة إعادة الاتصال بعد فشل...');
        startListeningToDailyLimit();
      });
    }
  }

  // التوقف عن الاستماع للتغييرات
  void stopListeningToDailyLimit() {
    _dailyLimitListener?.cancel();
    _dailyLimitListener = null;
  }

  // الحصول على معلومات الجهاز
  Future<void> _initializeDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final prefs = getIt<SharedPrefsService>();

      // إذا كان معرف الجهاز مخزنًا مسبقًا، استخدمه
      _deviceId = prefs.getString('device_id');
      _deviceName = prefs.getString('device_name');

      if (_deviceId == null) {
        // إنشاء معرف جديد للجهاز حسب النظام
        if (defaultTargetPlatform == TargetPlatform.android) {
          final androidInfo = await deviceInfo.androidInfo;
          _deviceId = androidInfo.id;
          _deviceId = _sanitizeFirebasePath(_deviceId!);
          _deviceName = androidInfo.model;
        } else if (defaultTargetPlatform == TargetPlatform.iOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _deviceId = iosInfo.identifierForVendor;
          if (_deviceId != null) {
            _deviceId = _sanitizeFirebasePath(_deviceId!);
          }
          _deviceName = '${iosInfo.name} ${iosInfo.model}';
        } else if (defaultTargetPlatform == TargetPlatform.windows) {
          final windowsInfo = await deviceInfo.windowsInfo;
          _deviceId = windowsInfo.deviceId;
          _deviceId = _sanitizeFirebasePath(_deviceId!);
          _deviceName = windowsInfo.computerName;
        }

        // تخزين معرف الجهاز للاستخدام المستقبلي
        if (_deviceId != null) {
          await prefs.setString('device_id', _deviceId!);
          if (_deviceName != null) {
            await prefs.setString('device_name', _deviceName!);
          }

          // إنشاء بيانات الجهاز في Firebase للمرة الأولى
          bool registered = await registerDevice();
          if (!registered) {
            print('تعذر تسجيل الجهاز في Firestore');
          }
        }
      }
    } catch (e) {
      print('خطأ في تهيئة معلومات الجهاز: $e');
    }
  }

  // تنظيف المسار ليكون متوافقًا مع قيود Firebase
  String _sanitizeFirebasePath(String path) {
    return path
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('\$', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_')
        .replaceAll('/', '_')
        .replaceAll('\\', '_');
  }

  // تنفيذ عملية Firestore بأمان مع إعادة المحاولة
  Future<T?> _safeFirestoreOperation<T>(Future<T> Function() operation,
      {int retries = 3}) async {
    if (!_isInitialized) {
      print('Firebase غير مهيأ، إعادة التهيئة...');
      bool initSuccess = await initialize();
      if (!initSuccess) {
        print('فشل في تهيئة Firebase، لا يمكن إكمال العملية');
        return null;
      }
    }

    int attempt = 0;
    while (attempt < retries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        // تحديد نوع الخطأ
        bool isConnectionError = e.toString().contains('network') ||
            e.toString().contains('connection') ||
            e.toString().contains('timeout') ||
            e.toString().contains('unavailable');

        if (isConnectionError) {
          print('خطأ في الاتصال بـ Firestore (محاولة $attempt/$retries): $e');
        } else {
          print('خطأ في عملية Firestore (محاولة $attempt/$retries): $e');
        }

        if (attempt >= retries) {
          print('فشلت جميع المحاولات');
          return null;
        }

        // تأخير تصاعدي قبل إعادة المحاولة - أطول في حالة خطأ الاتصال
        int delaySeconds = isConnectionError ? attempt * 3 : attempt;
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }
    return null;
  }

  // تسجيل الجهاز في Firebase
  Future<bool> registerDevice() async {
    if (_deviceId == null) return false;

    try {
      // التحقق من وجود المستند أولاً
      final docSnapshot = await _devicesCollection
          .doc(_deviceName)
          .get()
          .timeout(Duration(seconds: 10));

      // بيانات التسجيل
      final deviceData = {
        'deviceName': _deviceName ?? 'جهاز غير معروف',
        'platform': defaultTargetPlatform.toString(),
        'lastActive': FieldValue.serverTimestamp(),
      };

      // إذا كان المستند غير موجود، أضف بيانات أولية إضافية
      if (!docSnapshot.exists) {
        deviceData['firstRegistered'] = FieldValue.serverTimestamp();
        deviceData['settings'] = {
          'dailyLimit': 2048, // الحد الافتراضي (ميجابايت)
          'notifications': true,
        };

        await _devicesCollection.doc(_deviceName).set(deviceData);
      } else {
        // تحديث البيانات الموجودة فقط
        await _devicesCollection.doc(_deviceName).update(deviceData);
      }

      print('تم تسجيل الجهاز بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تسجيل الجهاز: $e');
      return false;
    }
  }

  // الحصول على الحد اليومي المسموح به
  Future<int> getDailyLimit() async {
    final result = await _safeFirestoreOperation(() async {
      if (_deviceName == null) return 2048; // قيمة افتراضية

      final docSnapshot = await _devicesCollection
          .doc(_deviceName)
          .get()
          .timeout(Duration(seconds: 5));

      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>;
        final settings = data['settings'] as Map<String, dynamic>?;
        if (settings != null && settings.containsKey('dailyLimit')) {
          var limit = settings['dailyLimit'];
          // معالجة مرنة لأنواع مختلفة من البيانات
          if (limit is int) return limit;
          if (limit is double) return limit.toInt();
          if (limit is String) return int.tryParse(limit) ?? 2048;
        }
      }
      return 2048; // قيمة افتراضية إذا لم يتم العثور على إعداد
    });

    return result ?? 2048; // إرجاع قيمة افتراضية إذا فشلت العملية
  }

  // تحديث الحد اليومي
  Future<bool> updateDailyLimit(int limit) async {
    return await _safeFirestoreOperation(() async {
          if (_deviceName == null) return false;

          try {
            // التحقق من وجود المستند والإعدادات أولاً
            final docSnapshot = await _devicesCollection
                .doc(_deviceName)
                .get()
                .timeout(Duration(seconds: 5));

            if (!docSnapshot.exists) {
              // إذا كان المستند غير موجود، قم بإنشائه مع إعدادات كاملة
              await _devicesCollection.doc(_deviceName).set({
                'settings': {
                  'dailyLimit': limit,
                  'notifications': true,
                },
                'lastUpdate': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            } else {
              // تحقق من وجود إعدادات
              final data = docSnapshot.data() as Map<String, dynamic>;

              if (data.containsKey('settings')) {
                // تحديث الحد اليومي فقط
                await _devicesCollection.doc(_deviceName).update({
                  'settings.dailyLimit': limit,
                }).timeout(Duration(seconds: 5));
              } else {
                // إنشاء كائن إعدادات كامل
                await _devicesCollection.doc(_deviceName).set({
                  'settings': {
                    'dailyLimit': limit,
                    'notifications': true,
                  }
                }, SetOptions(merge: true)).timeout(Duration(seconds: 5));
              }
            }

            print('تم تحديث الحد اليومي إلى $limit ميجابايت');
            return true;
          } catch (e) {
            print('خطأ في تحديث الحد اليومي: $e');
            return false;
          }
        }) ??
        false;
  }

  // تحديث وقت النشاط الأخير للجهاز
  Future<bool> updateLastActive() async {
    return await _safeFirestoreOperation(() async {
          if (_deviceName == null) return false;

          await _devicesCollection.doc(_deviceName).update({
            'lastActive': FieldValue.serverTimestamp(),
          }).timeout(Duration(seconds: 5));

          return true;
        }) ??
        false;
  }

  // التحقق من الاتصال بـ Firestore
  Future<bool> checkConnection() async {
    try {
      if (!_isInitialized) {
        bool initSuccess = await initialize();
        if (!initSuccess) return false;
      }

      // محاولة استدعاء بسيط للتحقق من الاتصال
      await _firestore.collection('_connection_test').doc('test').set({
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(Duration(seconds: 5));

      print('الاتصال بـ Firestore متاح');
      return true;
    } catch (e) {
      print('فشل الاتصال بـ Firestore: $e');
      return false;
    }
  }

  // استخدام Firebase في وضع عدم الاتصال
  void enableOfflineMode() {
    try {
      // تمكين الدعم في وضع عدم الاتصال مع حجم مخزن معقول
      _firestore.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: 10 * 1024 * 1024, // 10 ميجابايت
      );
      print('تم تفعيل وضع عدم الاتصال لـ Firestore');
    } catch (e) {
      print('خطأ في تمكين وضع عدم الاتصال: $e');
    }
  }

  // الحصول على معرف الجهاز الحالي
  String? getDeviceId() {
    return _deviceId;
  }

  // الحصول على اسم الجهاز الحالي
  String? getDeviceName() {
    return _deviceName;
  }

  // إيقاف الخدمة وتحرير الموارد
  void dispose() {
    // إيقاف الاستماع للتغييرات
    stopListeningToDailyLimit();

    // إغلاق تدفق التغييرات
    _dailyLimitStreamController.close();
  }

  // مزامنة الإعدادات المحلية مع Firebase
  Future<bool> syncSettings({
    required double dailyLimit,
    bool notifications = true,
    Map<String, dynamic>? additionalSettings,
  }) async {
    return await _safeFirestoreOperation(() async {
          if (_deviceName == null) return false;

          try {
            // التحقق من وجود المستند والإعدادات أولاً
            final docSnapshot = await _devicesCollection
                .doc(_deviceName)
                .get()
                .timeout(Duration(seconds: 5));

            // بناء كائن الإعدادات
            final Map<String, dynamic> settings = {
              'dailyLimit': dailyLimit.toInt(),
              'notifications': notifications,
            };

            // إضافة أي إعدادات إضافية إذا تم توفيرها
            if (additionalSettings != null) {
              settings.addAll(additionalSettings);
            }

            if (!docSnapshot.exists) {
              // إذا كان المستند غير موجود، قم بإنشائه مع الإعدادات
              await _devicesCollection.doc(_deviceName).set({
                'deviceName': _deviceName ?? 'جهاز غير معروف',
                'platform': defaultTargetPlatform.toString(),
                'firstRegistered': FieldValue.serverTimestamp(),
                'lastActive': FieldValue.serverTimestamp(),
                'settings': settings,
              }, SetOptions(merge: true));
            } else {
              // تحديث الإعدادات في المستند الموجود
              await _devicesCollection.doc(_deviceName).set({
                'settings': settings,
                'lastActive': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
            }

            print('تم مزامنة الإعدادات بنجاح مع Firebase');
            return true;
          } catch (e) {
            print('خطأ في مزامنة الإعدادات مع Firebase: $e');
            return false;
          }
        }) ??
        false;
  }

  // تحديث بيانات الجهاز (استخدام مخصص)
  Future<bool> updateDeviceData(
      String deviceId, Map<String, dynamic> data) async {
    return await _safeFirestoreOperation(() async {
          try {
            // التحقق من صحة المعاملات
            if (deviceId.isEmpty) {
              print('خطأ: معرف الجهاز فارغ');
              return false;
            }

            if (data.isEmpty) {
              print('خطأ: البيانات المراد تحديثها فارغة');
              return false;
            }

            // إضافة طابع الوقت
            data['lastUpdate'] = FieldValue.serverTimestamp();

            // تحديث البيانات مع دمج القيم الموجودة
            await _devicesCollection
                .doc(deviceId)
                .set(data, SetOptions(merge: true))
                .timeout(Duration(seconds: 10));

            print('تم تحديث بيانات الجهاز بنجاح');
            return true;
          } catch (e) {
            print('خطأ في تحديث بيانات الجهاز: $e');
            return false;
          }
        }) ??
        false;
  }
}
