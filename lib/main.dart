import 'package:flutter/material.dart';
import 'package:ABRAR/router/app_router.dart';
import 'package:ABRAR/services/device_usage_sync_service.dart';
import 'package:ABRAR/services/firebase_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ABRAR/services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase مع معالجة الأخطاء
  try {
    // تهيئة Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // إعداد service locator
    await setupServiceLocator();

    // تفعيل وضع عدم الاتصال لـ Firestore
    getIt<FirebaseService>().enableOfflineMode();

    // التحقق من الاتصال بـ Firestore
    bool isConnected = await getIt<FirebaseService>().checkConnection();
    if (isConnected) {
      print('تم الاتصال بـ Firebase بنجاح');
    } else {
      print('تم تشغيل التطبيق في وضع عدم الاتصال');
    }

    // تهيئة خدمة مزامنة استخدام الجهاز
    final syncService = DeviceUsageSyncService();
    await syncService.initialize();

    // مزامنة الاستهلاك اليومي مع فايربيز
    bool syncResult = await syncService.syncDailyUsageToFirebase();
    if (syncResult) {
      print('تم رفع بيانات الاستهلاك اليومي إلى فايربيز بنجاح');
    } else {
      print('تعذر رفع بيانات الاستهلاك اليومي، سيتم المحاولة لاحقاً');
    }

    print('تم تهيئة التطبيق بنجاح');
  } catch (e) {
    print('خطأ أثناء تهيئة التطبيق: $e');
    // الاستمرار في تشغيل التطبيق حتى مع وجود خطأ
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final router = createRouter();
      return MaterialApp.router(
        routerConfig: router,
        title: 'Data Usage Monitor',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2D7AF6),
            brightness: Brightness.light,
            primary: const Color(0xFF2D7AF6),
            secondary: const Color(0xFF5CE1E6),
            tertiary: const Color(0xFFAD7BFF),
          ),
          useMaterial3: true,
          fontFamily: 'Cairo',
          scaffoldBackgroundColor: const Color(0xFFF5F8FF),
          cardTheme: CardTheme(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: Colors.white.withOpacity(0.8),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.white.withOpacity(0.8),
            elevation: 0,
            centerTitle: true,
            iconTheme: const IconThemeData(color: Color(0xFF2D7AF6)),
            titleTextStyle: const TextStyle(
              color: Color(0xFF2D7AF6),
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Cairo',
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D7AF6),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF2D7AF6),
            foregroundColor: Colors.white,
          ),
        ),
        debugShowCheckedModeBanner: false,
      );
    });
  }
}
