import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';
import 'data_usage_service.dart';
import 'package:ABRAR/services/service_locator.dart';
import 'package:ABRAR/services/shared_preferences_service.dart';

// نموذج لاستخدام التطبيق
class AppUsage {
  final String packageName;
  final double usageMB;

  AppUsage({required this.packageName, required this.usageMB});
}

class DeviceUsageSyncService {
  // المثيل الوحيد للخدمة
  static final DeviceUsageSyncService _instance =
      DeviceUsageSyncService._internal();
  factory DeviceUsageSyncService() => _instance;
  DeviceUsageSyncService._internal();

  // مراجع الخدمات
  final _firebaseService = FirebaseService();

  // توقيت المزامنة
  Timer? _syncTimer;
  Timer? _limitCheckTimer;
  Timer? _connectionCheckTimer;
  static const _syncInterval = Duration(minutes: 15);
  static const _limitCheckInterval = Duration(minutes: 5);
  static const _connectionCheckInterval = Duration(minutes: 10);

  // مستمع التغييرات في الحد اليومي
  StreamSubscription<int>? _dailyLimitSubscription;

  // حالة تجاوز الحد
  bool _isOverLimit = false;

  // وقت آخر مزامنة وآخر محاولة مزامنة
  int _lastSyncTime = 0;
  int _lastSyncAttemptTime = 0;

  // حالة الاتصال
  bool _isOnline = false;
  final List<Map<String, dynamic>> _pendingUpdates = [];

  // الحد الأقصى للتحديثات المعلقة
  static const int MAX_PENDING_UPDATES = 50;

  // تهيئة الخدمة
  Future<bool> initialize() async {
    try {
      print('بدء تهيئة خدمة المزامنة...');

      // محاولة استرجاع البيانات المعلقة من التخزين المحلي
      await _loadPendingUpdates();

      // تهيئة خدمة Firebase
      bool firebaseInitialized = await _firebaseService.initialize();

      // التحقق من الاتصال
      _isOnline =
          firebaseInitialized && await _firebaseService.checkConnection();
      print('حالة الاتصال بـ Firebase: ${_isOnline ? 'متصل' : 'غير متصل'}');

      // استرداد الحد اليومي من Firebase وتطبيقه محليًا
      if (_isOnline) {
        await _syncDailyLimit();
      }

      // بدء مراقبة استخدام البيانات محليًا
      bool monitoringStarted =
          await DataUsageService.startMonitoringDataUsage();
      if (!monitoringStarted) {
        print('تحذير: فشل في بدء مراقبة استخدام البيانات');
      }

      // مزامنة الإعدادات المحلية مع Firebase عند بدء التطبيق
      if (_isOnline) {
        await _syncLocalSettingsToFirebase();
      }

      // بدء الاستماع للتغييرات في الحد اليومي
      _startListeningToDailyLimit();

      // بدء المزامنة الدورية
      _startPeriodicSync();

      // بدء التحقق الدوري من تجاوز الحد
      _startLimitChecking();

      // بدء التحقق من الاتصال دوريًا
      _startConnectionChecking();

      print('تم تهيئة خدمة المزامنة بنجاح');
      return true;
    } catch (e) {
      print('خطأ في تهيئة خدمة المزامنة: $e');
      return false;
    }
  }

  // مزامنة الإعدادات المحلية مع Firebase
  Future<void> _syncLocalSettingsToFirebase() async {
    try {
      print('جاري مزامنة الإعدادات المحلية مع Firebase...');

      // الحصول على الإعدادات المحلية
      final localDailyLimit = await DataUsageService.getDailyDataLimit();

      // إضافة أي إعدادات إضافية حسب الحاجة
      Map<String, dynamic> additionalSettings = {
        'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
      };

      // مزامنة الإعدادات مع Firebase
      bool success = await _firebaseService.syncSettings(
        dailyLimit: localDailyLimit,
        additionalSettings: additionalSettings,
      );

      if (success) {
        print('تمت مزامنة الإعدادات المحلية مع Firebase بنجاح');
      } else {
        print('فشلت مزامنة الإعدادات المحلية مع Firebase');
      }
    } catch (e) {
      print('خطأ في مزامنة الإعدادات المحلية مع Firebase: $e');
    }
  }

  // بدء الاستماع للتغييرات في الحد اليومي
  void _startListeningToDailyLimit() {
    // إلغاء أي اشتراك سابق
    _dailyLimitSubscription?.cancel();

    // الاشتراك في تدفق تغييرات الحد اليومي
    _dailyLimitSubscription =
        _firebaseService.dailyLimitStream.listen((newLimit) async {
      print('تم استلام تحديث للحد اليومي في خدمة المزامنة: $newLimit ميجابايت');

      try {
        // تحديث الحد اليومي في الخدمة المحلية
        await DataUsageService.setDailyDataLimit(newLimit.toDouble());

        // نشر رسالة تأكيد
        print('تم تحديث الحد اليومي محليًا بنجاح إلى: $newLimit ميجابايت');

        // التحقق من تجاوز الحد مع القيمة الجديدة
        await _checkDailyLimit();
      } catch (e) {
        print('خطأ أثناء تطبيق تحديث الحد اليومي: $e');
      }
    }, onError: (error) {
      print('خطأ في مستمع تغييرات الحد اليومي: $error');
    });
  }

  // حفظ التحديثات المعلقة
  Future<void> _savePendingUpdates() async {
    try {
      if (_pendingUpdates.isEmpty) return;

      final prefs = getIt<SharedPrefsService>();
      final jsonData = jsonEncode(_pendingUpdates);
      await prefs.setString('pending_updates', jsonData);
      print('تم حفظ ${_pendingUpdates.length} تحديثات معلقة في التخزين المحلي');
    } catch (e) {
      print('خطأ في حفظ التحديثات المعلقة: $e');
    }
  }

  // تحميل التحديثات المعلقة
  Future<void> _loadPendingUpdates() async {
    try {
      final prefs = getIt<SharedPrefsService>();
      final jsonData = prefs.getString('pending_updates');
      if (jsonData != null && jsonData.isNotEmpty) {
        final List<dynamic> data = jsonDecode(jsonData);
        _pendingUpdates.clear();
        _pendingUpdates
            .addAll(data.map((item) => Map<String, dynamic>.from(item)));
        print(
            'تم تحميل ${_pendingUpdates.length} تحديثات معلقة من التخزين المحلي');

        // التحقق من عدم تجاوز عدد التحديثات المعلقة الحد الأقصى
        if (_pendingUpdates.length > MAX_PENDING_UPDATES) {
          print(
              'تم تجاوز الحد الأقصى للتحديثات المعلقة، سيتم الاحتفاظ بأحدث $MAX_PENDING_UPDATES فقط');
          _pendingUpdates.sort((a, b) =>
              (b['timestamp'] as int).compareTo(a['timestamp'] as int));
          _pendingUpdates.removeRange(
              MAX_PENDING_UPDATES, _pendingUpdates.length);
        }
      }
    } catch (e) {
      print('خطأ في تحميل التحديثات المعلقة: $e');
    }
  }

  // بدء المزامنة الدورية مع Firebase
  void _startPeriodicSync() {
    // إلغاء المؤقت القديم إذا كان موجودًا
    _syncTimer?.cancel();

    // إعداد مزامنة دورية
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      // تجنب تكرار المزامنة في فترات قصيرة
      int now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastSyncAttemptTime > 60000) {
        // على الأقل دقيقة واحدة بين المحاولات
        _lastSyncAttemptTime = now;
        // يمكن إضافة منطق المزامنة هنا عند الحاجة
      }
    });
  }

  // بدء فحص الحد الدوري
  void _startLimitChecking() {
    // إلغاء المؤقت القديم إذا كان موجودًا
    _limitCheckTimer?.cancel();

    // فحص مباشر (مع تأخير قصير)
    Future.delayed(Duration(seconds: 10), () {
      _checkDailyLimit();
    });

    // إعداد فحص دوري
    _limitCheckTimer = Timer.periodic(_limitCheckInterval, (_) {
      _checkDailyLimit();
    });
  }

  // بدء التحقق من الاتصال دوريًا
  void _startConnectionChecking() {
    // إلغاء المؤقت القديم إذا كان موجودًا
    _connectionCheckTimer?.cancel();

    // إعداد فحص دوري للاتصال
    _connectionCheckTimer = Timer.periodic(_connectionCheckInterval, (_) async {
      final wasOnline = _isOnline;
      _isOnline = await _firebaseService.checkConnection();

      // إذا عاد الاتصال بعد انقطاع، حاول مزامنة البيانات المعلقة
      if (!wasOnline && _isOnline && _pendingUpdates.isNotEmpty) {
        print(
            'تم استعادة الاتصال. محاولة مزامنة البيانات المعلقة (${_pendingUpdates.length})');
        await _syncPendingData();
        // حفظ حالة التحديثات المعلقة بعد المزامنة
        await _savePendingUpdates();
      }
    });
  }

  // مزامنة البيانات المعلقة
  Future<void> _syncPendingData() async {
    if (_pendingUpdates.isEmpty || !_isOnline) return;

    int successCount = 0;
    // نسخة من القائمة للتكرار عليها
    final pendingCopy = List<Map<String, dynamic>>.from(_pendingUpdates);

    for (var update in pendingCopy) {
      try {
        // تنفيذ المزامنة هنا
        // إضافة منطق المزامنة الفعلي عند الحاجة

        // نموذج لنجاح المزامنة:
        _pendingUpdates.remove(update);
        successCount++;
      } catch (e) {
        print('خطأ في مزامنة بيانات معلقة: $e');
        // التوقف عن المحاولة إذا فشلت المزامنة
        break;
      }
    }

    print(
        'تمت مزامنة $successCount من البيانات المعلقة. متبقي: ${_pendingUpdates.length}');

    if (successCount > 0) {
      // تحديث وقت آخر نشاط ومزامنة
      await _firebaseService.updateLastActive();
      _lastSyncTime = DateTime.now().millisecondsSinceEpoch;

      // حفظ التحديثات المعلقة المتبقية
      await _savePendingUpdates();
    }
  }

  // التحقق من تجاوز الحد اليومي
  Future<void> _checkDailyLimit() async {
    try {
      // الحصول على الاستخدام الحالي
      final todayUsage = await DataUsageService.getTodayDataUsage();

      // الحصول على الحد اليومي من Firebase إذا كان متصلاً
      int dailyLimit = 1536; // قيمة افتراضية
      if (_isOnline) {
        dailyLimit = await _firebaseService.getDailyLimit();
      } else {
        // استخدام القيمة المخزنة محليًا
        final localLimit = await DataUsageService.getDailyDataLimit();
        dailyLimit = localLimit.toInt();
      }

      // التحقق من تجاوز الحد
      final isCurrentlyOverLimit = todayUsage > dailyLimit;

      // إذا تغيرت حالة تجاوز الحد، أرسل إشعارًا
      if (isCurrentlyOverLimit != _isOverLimit) {
        _isOverLimit = isCurrentlyOverLimit;

        if (_isOverLimit) {
          // يمكن استدعاء خدمة الإشعارات هنا
          print(
              'تنبيه: تم تجاوز الحد اليومي للبيانات! (${todayUsage.round()} من $dailyLimit ميجابايت)');
        }
      }
    } catch (e) {
      print('خطأ في التحقق من الحد اليومي: $e');
    }
  }

  // مزامنة الحد اليومي من Firebase إلى الجهاز المحلي
  Future<void> _syncDailyLimit() async {
    try {
      // الحصول على الحد اليومي من Firebase
      final firebaseLimit = await _firebaseService.getDailyLimit();

      // تطبيق الحد على الخدمة المحلية
      await DataUsageService.setDailyDataLimit(firebaseLimit.toDouble());

      print('تم تحديث الحد اليومي من Firebase: $firebaseLimit ميجابايت');
    } catch (e) {
      print('خطأ في مزامنة الحد اليومي: $e');
    }
  }

  // تحديث الحد اليومي (سيتم تحديثه في كل من Firebase والجهاز المحلي)
  Future<bool> updateDailyLimit(int limitMB) async {
    try {
      bool updated = true;

      // تحديث الحد في الخدمة المحلية أولاً
      await DataUsageService.setDailyDataLimit(limitMB.toDouble());

      // تحديث الحد في Firestore إذا كان متصلًا
      if (_isOnline) {
        // طريقة 2: مزامنة جميع الإعدادات مع Firebase (أكثر شمولاً)
        updated = await _firebaseService.syncSettings(
          dailyLimit: limitMB.toDouble(),
          additionalSettings: {
            'lastUpdated': DateTime.now().millisecondsSinceEpoch,
            'updatedBy': _firebaseService.getDeviceName() ?? 'غير معروف',
          },
        );
      }

      print('تم تحديث الحد اليومي: $limitMB ميجابايت');
      return updated;
    } catch (e) {
      print('خطأ في تحديث الحد اليومي: $e');
      return false;
    }
  }

  // الحصول على وقت آخر مزامنة ناجحة
  int getLastSyncTime() {
    return _lastSyncTime;
  }

  // الحصول على حالة الاتصال
  bool isOnline() {
    return _isOnline;
  }

  // الحصول على عدد التحديثات المعلقة
  int getPendingUpdatesCount() {
    return _pendingUpdates.length;
  }

  // محاولة مزامنة البيانات المعلقة يدويًا
  Future<bool> trySyncPendingData() async {
    if (!_isOnline) {
      // محاولة التحقق من الاتصال أولًا
      _isOnline = await _firebaseService.checkConnection();
    }

    if (_isOnline) {
      await _syncPendingData();
      return _pendingUpdates.isEmpty;
    }

    return false;
  }

  // التحقق من الاتصال يدويًا
  Future<bool> checkConnection() async {
    _isOnline = await _firebaseService.checkConnection();
    return _isOnline;
  }

  // إيقاف الخدمة
  void dispose() {
    _syncTimer?.cancel();
    _limitCheckTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _dailyLimitSubscription?.cancel();

    // حفظ أي تحديثات معلقة قبل إيقاف الخدمة
    if (_pendingUpdates.isNotEmpty) {
      _savePendingUpdates();
    }
  }

  // مزامنة الإعدادات مع Firebase يدويًا
  Future<bool> syncSettingsToFirebase() async {
    if (!_isOnline) {
      // محاولة التحقق من الاتصال أولًا
      _isOnline = await _firebaseService.checkConnection();
    }

    if (_isOnline) {
      try {
        await _syncLocalSettingsToFirebase();
        return true;
      } catch (e) {
        print('خطأ في مزامنة الإعدادات يدويًا: $e');
        return false;
      }
    } else {
      print('تعذر مزامنة الإعدادات: غير متصل بالإنترنت');
      return false;
    }
  }

  // تحديث البيانات مباشرة للواجهة الرئيسية
  Future<void> updateHomeScreenData() async {
    // 1. تحديث البيانات المحلية أولاً
    try {
      await DataUsageService.getCurrentDataUsage();
      await DataUsageService.getTodayDataUsage();

      print('تم تحديث بيانات الصفحة الرئيسية بنجاح');
    } catch (e) {
      print('خطأ أثناء تحديث بيانات الصفحة الرئيسية: $e');
    }
  }

  // رفع الاستهلاك اليومي إلى فايربيز
  Future<bool> syncDailyUsageToFirebase() async {
    if (!_isOnline) {
      // محاولة التحقق من الاتصال أولاً
      _isOnline = await _firebaseService.checkConnection();
    }

    if (!_isOnline) {
      print('تعذر مزامنة الاستهلاك اليومي: غير متصل بالإنترنت');
      return false;
    }

    try {
      // الحصول على الاستهلاك اليومي من الخدمة المحلية
      final todayUsage = await DataUsageService.getTodayDataUsage();
      final currentUsage = await DataUsageService.getCurrentDataUsage();

      // تحضير البيانات للرفع
      final usageData = {
        'todayUsage': todayUsage,
        'currentRate': currentUsage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'deviceName': _firebaseService.getDeviceName() ?? 'غير معروف',
      };

      // رفع البيانات إلى فايربيز
      final deviceId = _firebaseService.getDeviceName();
      if (deviceId == null) {
        print('تعذر مزامنة الاستهلاك اليومي: معرف الجهاز غير متوفر');
        return false;
      }

      // الوصول إلى Firestore
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // إضافة البيانات إلى مجموعة فرعية بتاريخ اليوم
      final todayDate = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD
      await firestore
          .collection('devices')
          .doc(deviceId)
          .collection('daily_usage')
          .doc(todayDate)
          .set(usageData, SetOptions(merge: true));

      // تحديث إجمالي الاستهلاك في وثيقة الجهاز الرئيسية
      await firestore.collection('devices').doc(deviceId).update({
        'lastUsageUpdate': FieldValue.serverTimestamp(),
        'stats': {
          'todayUsage': todayUsage,
          'lastSyncTime': DateTime.now().millisecondsSinceEpoch,
        }
      });

      _lastSyncTime = DateTime.now().millisecondsSinceEpoch;
      print('تم مزامنة الاستهلاك اليومي بنجاح: $todayUsage ميجابايت');
      return true;
    } catch (e) {
      print('خطأ في مزامنة الاستهلاك اليومي: $e');
      return false;
    }
  }
}
