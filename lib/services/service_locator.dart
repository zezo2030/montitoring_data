import 'package:get_it/get_it.dart';
import 'package:ABRAR/services/shared_preferences_service.dart';
import 'package:ABRAR/services/firebase_service.dart';
import 'package:ABRAR/services/device_usage_sync_service.dart';
import 'package:ABRAR/services/app_icon_service.dart';
import 'package:ABRAR/services/permissions_service.dart';
import 'package:ABRAR/services/notification_service.dart';

// إنشاء كائن وحيد من GetIt
final getIt = GetIt.instance;

// تهيئة الخدمات
Future<void> setupServiceLocator() async {
  // تسجيل خدمات كنماذج Singleton
  getIt.registerSingleton<SharedPrefsService>(SharedPrefsService());
  getIt.registerSingleton<FirebaseService>(FirebaseService());
  getIt.registerSingleton<DeviceUsageSyncService>(DeviceUsageSyncService());
  getIt.registerSingleton<NotificationService>(NotificationService());

  // تسجيل الخدمات الأخرى
  getIt.registerSingleton<AppIconService>(AppIconService());
  getIt.registerSingleton<PermissionsService>(PermissionsService());

  // تهيئة الخدمات التي تحتاج إلى تهيئة
  await getIt<SharedPrefsService>().initialize();
  await getIt<FirebaseService>().initialize();
  await getIt<DeviceUsageSyncService>().initialize();
  await getIt<NotificationService>().initialize();
}
