import 'package:ABRAR/services/service_locator.dart';
import 'package:ABRAR/services/shared_preferences_service.dart';

class ServiceLocatorTest {
  // دالة لاختبار كفاءة service locator
  static void testSharedPreferences() async {
    // استخدام نفس الكائن من service locator
    final prefs1 = getIt<SharedPrefsService>();
    final prefs2 = getIt<SharedPrefsService>();

    // اختبار أن الكائنين متطابقين (نفس المرجع)
    assert(identical(prefs1, prefs2),
        'يجب أن يكون كلا المرجعين يشيران إلى نفس الكائن');

    // اختبار الوظائف الأساسية
    await prefs1.setString('test_key', 'test_value');
    final value = prefs2.getString('test_key');

    // التحقق من القيمة
    assert(value == 'test_value',
        'يجب أن تكون القيمة المستردة هي نفسها التي تم تخزينها');

    print('اختبار service locator ناجح');
  }

  // دالة لتنظيف البيانات بعد الاختبار
  static void cleanup() async {
    final prefs = getIt<SharedPrefsService>();
    await prefs.remove('test_key');
  }
}
